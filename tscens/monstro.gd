extends CharacterBody3D


# Declare member variables here. Examples:
set_velocity(velocity)
set_up_direction(Vector3.UP)
set_floor_stop_on_slope_enabled(true)
move_and_slide()
velocity = velocity
var target 

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")	


# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	set_velocity(speed)
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	move_and_slide()	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
