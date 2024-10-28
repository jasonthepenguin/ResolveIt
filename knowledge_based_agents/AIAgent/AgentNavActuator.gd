class_name AgentNavActuator extends Node

@export var speed = 2.0
@export var debug_info: = false
@onready var character: CharacterBody3D = get_parent()
@onready var nav: NavigationAgent3D = character.get_nav_agent()
var accumulator = 0.0
var current_location: Vector3
var next_location: Vector3
var new_velocity: Vector3

func _physics_process(_delta):
	current_location = character.global_position
	
	if debug_info and not nav.is_navigation_finished():
		accumulator += _delta
		if (accumulator >= 1.0):
			print("Agent: Location ", current_location)
			accumulator = 0
			
	next_location = nav.get_next_path_position()
	new_velocity = (next_location - current_location).normalized() * speed
	character.velocity = character.velocity.move_toward(new_velocity, .25)
	character.move_and_slide()

# calling functions need to call await with this
func move_to(new_position: Vector2) -> bool:
	if debug_info: print("Agent: Moving to ", new_position)
	
	# Set the target and wait one frame for the navigation to update
	nav.set_target_position(Vector3(new_position.x, 0, new_position.y))
	
	# Wait until we get a definitive answer about reachability
	while not nav.is_target_reachable() and not nav.is_navigation_finished():
		await get_tree().process_frame
	
	# Check if target is reachable
	if not nav.is_target_reachable():
		if debug_info: print("Agent: Target unreachable")
		return false
	
	# Wait for movement to complete
	await nav.navigation_finished
	if debug_info: print("Agent: Target reached")
	return true
