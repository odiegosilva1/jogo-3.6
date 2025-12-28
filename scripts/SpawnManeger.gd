
extends Node3D  # ← USAR SPATIAL PARA 3D

# ==================== CONFIGURAÇÕES (EDITÁVEIS NO INSPECTOR) ====================
@export var monster_scene: PackedScene      # Cena do monstro a spawnar
@export var item_drop_scene: PackedScene    # Item que monstro dropa ao morrer (opcional)

# Limites de spawn
@export var max_monsters: int = 8           # Máximo de monstros simultâneos
@export var spawn_radius_min: float = 5.0   # Distância mínima do spawner
@export var spawn_radius_max: float = 25.0  # Distância máxima do spawner
@export var spawn_interval: float = 3.0     # Intervalo entre tentativas de spawn
@export var min_distance_from_player: float = 10.0  # Distância mínima do player
@export var respawn_delay_min: float = 5.0  # Delay mínimo para respawn
@export var respawn_delay_max: float = 10.0 # Delay máximo para respawn

# Controle de spawn
@export var auto_spawn: bool = true         # Começa a spawnar automaticamente
@export var initial_spawn_count: int = 3    # Quantos monstros spawnar no início
@export var spawn_chance: float = 0.7       # Chance de spawn (0.0 a 1.0)

# ==================== VARIÁVEIS INTERNAS ====================
var current_monsters = 0                   # Contador de monstros ativos
var spawn_timer = 0.0                      # Timer para controle de intervalo
var monster_container = null               # Container para organizar monstros
var player = null                          # Referência ao player
var is_active = true                       # Se o spawner está ativo
var spawn_positions_history = []           # Histórico de posições de spawn

# ==================== INICIALIZAÇÃO ====================
func _ready():
	# Inicializa randomização
	randomize()
	
	# Encontra o player
	_find_player()
	
	# Cria container para monstros
	_create_monster_container()
	
	# Configura spawn inicial se habilitado
	if auto_spawn and initial_spawn_count > 0:
		call_deferred("_spawn_initial_monsters")
	
	print("Spawn Manager inicializado!")
	print("Monstro: ", monster_scene)
	print("Máximo: ", max_monsters)
	print("Player encontrado: ", player != null)

# ==================== LOOP PRINCIPAL ====================
func _process(delta):
	if not is_active or not auto_spawn:
		return
	
	# Atualiza timer de spawn
	spawn_timer += delta
	
	# Verifica se é hora de tentar spawnar
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_try_spawn_monster()

# ==================== FUNÇÕES PRINCIPAIS ====================

# Tenta spawnar um monstro (com verificação de limites e chance)
func _try_spawn_monster():
	# Verifica condições básicas
	if not _can_spawn():
		return
	
	# Chance de spawn
	if randf() > spawn_chance:
		return
	
	# Tenta spawnar
	var monster = _spawn_monster()
	if monster:
		print("Monstro spawnado! Total: ", current_monsters, "/", max_monsters)

# Spawna um monstro em posição aleatória
func _spawn_monster():
	var position = _find_valid_spawn_position()
	
	if position:
		return _create_monster_at_position(position)
	
	return null

# Cria um monstro em posição específica
func _create_monster_at_position(position: Vector3):
	# Instancia o monstro
	var monster = monster_scene.instantiate()
	monster.position = position
	
	# Configura drop se houver item definido
	_setup_monster_drop(monster)
	
	# Adiciona ao container
	monster_container.add_child(monster)
	
	# Atualiza contador
	current_monsters += 1
	
	# Registra posição no histórico (para evitar spawns muito próximos)
	_register_spawn_position(position)
	
	# Conecta sinal de morte
	monster.connect("tree_exiting", Callable(self, "_on_monster_died").bind(monster))
	
	return monster

# ==================== FUNÇÕES DE UTILIDADE ====================

# Encontra o player na cena
func _find_player():
	# Tenta por grupo primeiro
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		return
	
	# Tenta por nome comum
	var possible_names = ["Player", "player", "Character", "character"]
	for name in possible_names:
		if get_tree().get_root().has_node(name):
			player = get_tree().get_root().get_node(name)
			print("Player encontrado por nome: ", name)
			return
	
	print("AVISO: Player não encontrado!")

# Cria container para organizar monstros
func _create_monster_container():
	monster_container = Node3D.new()
	monster_container.name = "MonsterContainer_" + name
	get_parent().add_child(monster_container)

# Encontra uma posição válida para spawn
func _find_valid_spawn_position(max_attempts: int = 10):
	for _attempt in range(max_attempts):
		var position = _generate_random_position()
		
		if _is_valid_spawn_position(position):
			return position
	
	print("Não foi possível encontrar posição válida após ", max_attempts, " tentativas")
	return null

# Gera uma posição aleatória
func _generate_random_position():
	# Gera ângulo e distância aleatórios
	var angle = randf_range(0, PI * 2)
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	
	# Calcula posição relativa ao spawner
	var relative_pos = Vector3(
		sin(angle) * distance,
		0,
		cos(angle) * distance
	)
	
	# Retorna posição global
	return position + relative_pos

# Verifica se uma posição é válida para spawn
func _is_valid_spawn_position(position: Vector3) -> bool:
	# 1. Verifica distância do player
	if player and player is Node3D:
		var distance_to_player = position.distance_to(player.position)
		if distance_to_player < min_distance_from_player:
			return false
	
	# 2. Verifica distância de outros monstros
	for monster in monster_container.get_children():
		if position.distance_to(monster.position) < 3.0:
			return false
	
	# 3. Verifica histórico de spawns (evita spawns muito próximos)
	for past_position in spawn_positions_history:
		if position.distance_to(past_position) < 5.0:
			return false
	
	# 4. Verifica se tem chão (raycast)
	if not _has_ground_at_position(position):
		return false
	
	# 5. Verifica se não está dentro de obstáculos
	if _is_inside_obstacle(position):
		return false
	
	return true

# Verifica se há chão na posição
func _has_ground_at_position(position: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var from = position + Vector3(0, 10, 0)    # 10 unidades acima
	var to = position + Vector3(0, -20, 0)     # 20 unidades abaixo
	
	var result = space_state.intersect_ray(from, to, [], 1)
	return not result.is_empty()

# Verifica se está dentro de obstáculo
func _is_inside_obstacle(position: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	
	# Verifica em 4 direções
	var directions = [
		Vector3(1, 0, 0),   # Direita
		Vector3(-1, 0, 0),  # Esquerda
		Vector3(0, 0, 1),   # Frente
		Vector3(0, 0, -1)   # Trás
	]
	
	for dir in directions:
		var from = position
		var to = position + dir * 2.0  # 2 unidades de distância
		var result = space_state.intersect_ray(from, to, [], 1)
		
		if result:
			return true  # Tem obstáculo muito perto
	
	return false

# Registra posição de spawn no histórico
func _register_spawn_position(position: Vector3):
	spawn_positions_history.append(position)
	
	# Mantém histórico limitado (últimas 10 posições)
	if spawn_positions_history.size() > 10:
		spawn_positions_history.remove(0)

# Configura drop do monstro
func _setup_monster_drop(monster):
	if item_drop_scene and monster.has_method("set_drop_item"):
		monster.set_drop_item(item_drop_scene)
	elif item_drop_scene and monster.has_method("setup_drop"):
		monster.setup_drop(item_drop_scene)

# Spawna monstros iniciais
func _spawn_initial_monsters():
	var count = min(initial_spawn_count, max_monsters)
	
	for _i in range(count):
		if _can_spawn():
			_spawn_monster()
			await get_tree().create_timer(0.5).timeout  # Delay entre spawns

# Verifica se pode spawnar
func _can_spawn() -> bool:
	if not is_active:
		return false
	
	if not monster_scene:
		print("AVISO: Cena do monstro não definida!")
		return false
	
	if current_monsters >= max_monsters:
		return false
	
	if not player:
		return false
	
	return true

# ==================== EVENTOS ====================

# Quando monstro morre
func _on_monster_died(monster):
	current_monsters -= 1
	
	# Dropa item se configurado
	if monster.has_method("drop_item"):
		monster.drop_item()
	
	print("Monstro morreu. Restantes: ", current_monsters, "/", max_monsters)
	
	# Respawn após delay aleatório
	if auto_spawn and is_active:
		var delay = randf_range(respawn_delay_min, respawn_delay_max)
		await get_tree().create_timer(delay).timeout
		_try_spawn_monster()

# ==================== FUNÇÕES PÚBLICAS (PARA OUTROS SCRIPTS) ====================

# Ativa/desativa spawner
func set_active(active: bool):
	is_active = active
	print("Spawn Manager ", ("ativado" if active else "desativado"))

# Spawna monstro em posição específica (para scripts externos)
func spawn_at_position(position: Vector3):
	if _can_spawn() and _is_valid_spawn_position(position):
		return _create_monster_at_position(position)
	return null

# Spawna múltiplos monstros de uma vez
func spawn_multiple(count: int, delay_between: float = 0.5):
	for _i in range(count):
		if _can_spawn():
			_spawn_monster()
			await get_tree().create_timer(delay_between).timeout

# Limpa todos os monstros
func clear_all_monsters():
	for monster in monster_container.get_children():
		monster.queue_free()
	
	current_monsters = 0
	spawn_positions_history.clear()

# Retorna informações do spawner
func get_info() -> Dictionary:
	return {
		"active": is_active,
		"current_monsters": current_monsters,
		"max_monsters": max_monsters,
		"has_monster_scene": monster_scene != null,
		"has_player_reference": player != null
	}

# Configura cena do monstro dinamicamente
func set_monster_scene(scene: PackedScene):
	monster_scene = scene
	print("Cena do monstro atualizada")

# Configura cena do item drop dinamicamente
func set_item_drop_scene(scene: PackedScene):
	item_drop_scene = scene
	print("Cena do item drop atualizada")
