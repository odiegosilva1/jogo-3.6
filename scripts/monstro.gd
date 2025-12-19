extends KinematicBody

# Variáveis do monstro
var enemyHP = 3
var damage = 1

var attackDistance = 1.0
var attackRate = 1.0
var enemySpeed = 2.5

var velocity = Vector3.ZERO

# Variável para drop
var drop_item_scene = null
var has_drop = true  # Se este monstro dropa item

onready var timer = $Timer if has_node("Timer") else null
onready var player = get_node("/root/World/Player") if has_node("/root/World/Player") else null

const UP = Vector3.UP

func _ready():
	if timer:
		timer.wait_time = attackRate
		timer.start()

# Função para configurar o drop
func set_drop_item(item_scene):
	drop_item_scene = item_scene

func _setup_drop(item_scene):
	drop_item_scene = item_scene

func _physics_process(_delta):
	if not player:
		return
	
	var distance = translation.distance_to(player.translation)
	
	if distance > attackDistance:
		var direction = (player.translation - translation).normalized()
		velocity = Vector3(direction.x, 0, direction.z) * enemySpeed
		velocity = move_and_slide(velocity, UP)

func takeDamage(dmg):
	enemyHP -= dmg
	
	if enemyHP <= 0:
		# Dropa item antes de morrer
		if has_drop:
			drop_item()
		die()

func die():
	# Animação de morte (opcional)
	# Aqui você pode tocar uma animação antes de remover
	
	# Remove o monstro
	queue_free()

func drop_item():
	if drop_item_scene and has_drop:
		# Instancia o item
		var item = drop_item_scene.instance()
		item.translation = translation + Vector3(0, 0.5, 0)  # Ligeiramente acima
		
		# Adiciona à cena
		get_parent().add_child(item)
		
		print("Item dropado!")
		
		# Marca que já dropou
		has_drop = false
		
		return item
	
	return null

func _on_Timer_timeout():
	if player and translation.distance_to(player.translation) < attackDistance:
		player.takeDemage(damage)
