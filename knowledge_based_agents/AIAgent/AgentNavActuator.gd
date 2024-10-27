extends Node

@export var travel_speed = 5.0
@export var debug_info: bool = false
@onready var character: CharacterBody3D = get_parent()
@onready var nav_agent: NavigationAgent3D = character.get_node("NavigationAgent3D")

func _physics_process(_delta):
	var current_location = character.global_transform.origin
	if debug_info: print("Agent: Location ", current_location)
	
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * travel_speed
	
	character.velocity = character.velocity.move_toward(new_velocity, .25)
	character.move_and_slide()
	
func move_to(new_position: Vector2):
	if debug_info: print("Agent: Moving to ", new_position)
	nav_agent.set_target_position(Vector3(new_position.x, 0, new_position.y))
