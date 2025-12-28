extends CharacterBody3D

var speed = 10
var accel = 20
var gravity = 9.8
var jump = 5
var mousesense = .4

var currentHP = 10
var demage = 1

var dire = Vector3()
var vel = Vector3()
var fall = Vector3()

@onready var head = $Head
# Opção 1: Use o caminho correto para o AnimationPlayer
# Opção 2: Deixe null e use verificação
var anim = null

# Variável para controlar estado anterior
var was_moving = false

func _ready():
	# Tenta encontrar o AnimationPlayer em vários locais possíveis
	if has_node("Pivot/FootPivot/Anim"):
		anim = $Pivot/FootPivot/Anim
	elif has_node("AnimationPlayer"):
		anim = $AnimationPlayer
	elif has_node("Anim"):
		anim = $Anim
	
	# Debug: verifica se encontrou os nós
	print("Head encontrado: ", head != null)
	print("Anim encontrado: ", anim != null)
	
	# Lista animações disponíveis
	if anim:
		print("Animações disponíveis: ", anim.get_animation_list())
	else:
		print("AVISO: AnimationPlayer não encontrado!")

# Function Input
func _input(event):
	if Input.is_action_just_pressed("shot"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if Input.is_action_just_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion and head:
		rotate_y(deg_to_rad(-event.relative.x * mousesense))
		head.rotate_x(deg_to_rad(-event.relative.y * mousesense))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-15), deg_to_rad(15))

	print(currentHP)	
		
func _physics_process(delta):
	dire = Vector3()
	
	# Aplicar gravidade
	if not is_on_floor():
		fall.y -= gravity * delta
	else:
		fall.y = 0
	
	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		fall.y = jump
	
	# Movimento
	var is_moving = false
	if Input.is_action_pressed("w"):
		dire -= transform.basis.z
		is_moving = true
	elif Input.is_action_pressed("s"):
		dire += transform.basis.z
		is_moving = true
		
	if Input.is_action_pressed("a"):
		dire -= transform.basis.x
		is_moving = true
	elif Input.is_action_pressed("d"):
		dire += transform.basis.x
		is_moving = true
	
	dire = dire.normalized()
	
	# Interpolar velocidade horizontal
	vel = vel.lerp(dire * speed, accel * delta)
	
	# Combinar velocidade horizontal e vertical
	var final_vel = vel + fall
	
	# Aplicar movimento
	set_velocity(final_vel)
	set_up_direction(Vector3.UP)
	move_and_slide()
	final_vel = velocity
	
	# Atualizar fall
	if is_on_floor() and fall.y < 0:
		fall.y = 0
	
	# Chamar animação baseada no movimento
	animate(is_moving)

func animate(is_moving):
	if anim == null:
		return
	
	# Só muda a animação se o estado mudou
	if is_moving != was_moving:
		was_moving = is_moving
		
		if is_moving:
			# Verifica se a animação existe
			if anim.has_animation("walk"):
				anim.play("walk")
			else:
				print("ERRO: Animação 'walk' não encontrada!")
		else:
			# Verifica se a animação existe
			if anim.has_animation("Idle"):
				anim.play("Idle")
			else:
				print("ERRO: Animação 'Idle' não encontrada!")
				
# Funcao de dar dano
func takeDamage(damage):
	currentHP -= damage
	
	if currentHP <= 0:
		die()
		
func die():
	get_tree().reload_current_scene()		
	
	
				 
