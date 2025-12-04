extends KinematicBody

var speed = 10
var accel = 20
var gravity = 9.8
var jump = 5
var mousesense = 0.1
var dire = Vector3()
var vel = Vector3()
var fall = Vector3()

onready var head = $Head

# Function Input
func _input(event):
	if Input.is_action_just_pressed("shot"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if Input.is_action_just_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mousesense))
		head.rotate_x(deg2rad(-event.relative.y * mousesense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-15), deg2rad(15))

# Movimentação
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
	
	# Movimento (usar is_action_pressed em vez de is_action_just_pressed)
	if Input.is_action_pressed("w"):
		dire -= transform.basis.z
	elif Input.is_action_pressed("s"):
		dire += transform.basis.z
		
	if Input.is_action_pressed("a"):
		dire -= transform.basis.x
	elif Input.is_action_pressed("d"):
		dire += transform.basis.x
	
	dire = dire.normalized()
	
	# Interpolar velocidade horizontal
	vel = vel.linear_interpolate(dire * speed, accel * delta)
	
	# Combinar velocidade horizontal e vertical
	var final_vel = vel + fall
	
	# Aplicar movimento uma única vez
	final_vel = move_and_slide(final_vel, Vector3.UP)
	
	# Atualizar fall com a velocidade vertical resultante
	if is_on_floor() and fall.y < 0:
		fall.y = 0
