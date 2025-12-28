extends Node3D  # Ou Area3D/RigidBody3D dependendo do tipo

@export var item_type = "health"  # health, ammo, coin, etc.
@export var item_value = 10
@export var pickup_radius = 1.0
@export var rotate_speed = 1.0
@export var float_amplitude = 0.2
@export var float_speed = 2.0

var initial_y = 0.0
var time = 0.0
var can_pickup = true

@onready var player = null

func _ready():
	initial_y = position.y
	
	# Tenta encontrar player
	_find_player()
	
	# Adiciona à área de coleta
	add_to_group("dropped_items")
	
	# Auto-destruir após tempo
	await get_tree().create_timer(30.0).timeout  # 30 segundos
	if is_instance_valid(self):
		queue_free()

func _process(delta):
	time += delta
	
	# Animação de rotação
	rotate_y(rotate_speed * delta)
	
	# Animação de flutuação
	position.y = initial_y + sin(time * float_speed) * float_amplitude
	
	# Verifica coleta
	if player and can_pickup:
		check_pickup()

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func check_pickup():
	var distance = position.distance_to(player.global_transform.origin)
	if distance <= pickup_radius:
		pickup()

func pickup():
	if not can_pickup:
		return
	
	can_pickup = false
	
	# Efeito de coleta
	print("Item coletado: ", item_type, " (", item_value, ")")
	
	# Dá o item ao player
	if player.has_method("add_item"):
		player.add_item(item_type, item_value)
	
	# Efeito visual/sonoro (opcional)
	# $AnimationPlayer.play("pickup")
	# yield($AnimationPlayer, "animation_finished")
	
	# Remove o item
	queue_free()

# Função para atração magnética (item vai até o player)
func attract_to_player():
	if not player:
		return
	
	var direction = (player.global_transform.origin - position).normalized()
	position += direction * 5.0 * get_process_delta_time()

# Sinal quando entra na área do player
func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		pickup()
