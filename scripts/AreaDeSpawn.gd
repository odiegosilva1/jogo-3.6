extends Area

# Export variáveis para ajustar no Inspector
export(PackedScene) var monster_scene
export(PackedScene) var item_drop_scene  # Item que o monstro dropa
export(int) var max_monsters = 8
export(float) var min_spawn_distance = 5.0  # Distância mínima do player
export(float) var max_spawn_distance = 25.0  # Distância máxima do player
export(float) var spawn_check_interval = 3.0  # Verifica a cada X segundos

# Variáveis
var current_monsters = 0
var spawn_timer = 0.0
var monster_container = null
var player = null

func _ready():
	# Encontra o player
	player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		player = player[0]
	else:
		print("AVISO: Player não encontrado!")
		set_process(false)
		return
	
	# Cria container para monstros
	monster_container = Spatial.new()
	monster_container.name = "MonsterContainer"
	get_parent().add_child(monster_container)
	
	# Adiciona ao grupo de spawn areas
	add_to_group("spawn_areas")
	
	print("Área de spawn de monstros pronta!")
	
	# Spawna monstros iniciais
	call_deferred("spawn_initial_monsters")

func _process(delta):
	spawn_timer += delta
	
	if spawn_timer >= spawn_check_interval:
		spawn_timer = 0.0
		try_spawn_monster()

func spawn_initial_monsters():
	# Spawna alguns monstros iniciais
	var initial_count = min(3, max_monsters)
	for _i in range(initial_count):  # Adicionado underscore
		spawn_monster()
		yield(get_tree().create_timer(0.5), "timeout")  # Delay entre spawns

func try_spawn_monster():
	# Só spawna se tiver menos monstros que o máximo
	if current_monsters < max_monsters:
		# Chance de spawn (70%)
		if randf() < 0.7:
			spawn_monster()

func spawn_monster():
	if not monster_scene or not player:
		return null
	
	# Tenta encontrar uma posição válida várias vezes
	var position = null
	var attempts = 0
	var max_attempts = 10
	
	while position == null and attempts < max_attempts:
		position = find_valid_spawn_position()
		attempts += 1
	
	if position:
		# Instancia o monstro
		var monster = monster_scene.instance()
		monster.translation = position
		monster_container.add_child(monster)
		
		# Configura o monstro para dropar item
		_setup_monster_drop(monster)
		
		current_monsters += 1
		
		# Conecta sinais
		monster.connect("tree_exiting", self, "_on_monster_died", [monster])
		
		print("Monstro spawnado em: ", position)
		return monster
	
	return null

func find_valid_spawn_position():
	# Gera posição aleatória dentro da área
	var bounds = get_spawn_bounds()
	
	var random_pos = Vector3(
		rand_range(bounds.min_x, bounds.max_x),
		0,
		rand_range(bounds.min_z, bounds.max_z)
	)
	
	# Verifica se a posição é válida
	if is_valid_spawn_position(random_pos):
		return random_pos
	
	return null

func get_spawn_bounds():
	# Calcula os limites da área de spawn
	var shape = get_child(0)
	var bounds = {
		"min_x": -10,
		"max_x": 10,
		"min_z": -10,
		"max_z": 10
	}
	
	if shape is CollisionShape and shape.shape is BoxShape:
		var extents = shape.shape.extents
		var global_pos = global_transform.origin
		
		bounds = {
			"min_x": global_pos.x - extents.x,
			"max_x": global_pos.x + extents.x,
			"min_z": global_pos.z - extents.z,
			"max_z": global_pos.z + extents.z
		}
	
	return bounds

func is_valid_spawn_position(position: Vector3) -> bool:
	# Verifica distância do player
	var distance_to_player = position.distance_to(player.global_transform.origin)
	if distance_to_player < min_spawn_distance or distance_to_player > max_spawn_distance:
		return false
	
	# Verifica colisão com outros monstros
	for monster in monster_container.get_children():
		if position.distance_to(monster.global_transform.origin) < 3.0:
			return false
	
	# Verifica se está em terreno sólido (raycast)
	var space_state = get_world().direct_space_state
	var from = position + Vector3(0, 10, 0)  # 10 unidades acima
	var to = position + Vector3(0, -20, 0)   # 20 unidades abaixo
	
	var result = space_state.intersect_ray(from, to, [], 1)
	if not result.empty():
		return true
	
	return false

func _setup_monster_drop(monster):
	# Adiciona script para dropar item
	if monster.has_method("set_drop_item"):
		monster.set_drop_item(item_drop_scene)
	elif monster.has_script():
		# Se o monstro já tem um script, adiciona via código
		monster.call_deferred("_setup_drop", item_drop_scene)

func _on_monster_died(monster):
	current_monsters -= 1
	
	# Dropa item se tiver
	if monster.has_method("drop_item"):
		monster.drop_item()
	
	print("Monstro morreu. Monstros ativos: ", current_monsters)
	
	# Respawn após delay
	yield(get_tree().create_timer(rand_range(5.0, 10.0)), "timeout")
	try_spawn_monster()

# Função para spawn manual
func spawn_monster_at_position(position: Vector3):
	if current_monsters >= max_monsters:
		return null
	
	var monster = monster_scene.instance()
	monster.translation = position
	monster_container.add_child(monster)
	
	_setup_monster_drop(monster)
	
	current_monsters += 1
	monster.connect("tree_exiting", self, "_on_monster_died", [monster])
	
	return monster
