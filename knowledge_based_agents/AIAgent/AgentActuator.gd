# AgentActuator.gd
class_name AgentActuator extends NavigationAgent3D

var speed: float = 2.0
var rotation_speed: float = 10.0  # Speed at which the agent rotates
var debug_info: bool = false
var random_movement: bool = false
var update_interval: float = 1.5
var max_stuck_time: float = 0.5
var distance_threshold: float = 0.001

@onready var character: CharacterBody3D = get_parent()
var accumulator = 0.0
var last_location: Vector3
var stuck_time = 0.0
var current_location: Vector3
var next_location: Vector3
var new_velocity: Vector3

func _physics_process(delta):
	current_location = character.global_position
	
	if debug_info and not is_navigation_finished():
		accumulator += delta
		if (accumulator >= 1.0):
			LogManager.add_message("Agent: Location ", current_location)
			accumulator = 0
			
	next_location = get_next_path_position()
	new_velocity = (next_location - current_location).normalized() * speed
	
	# Handle rotation
	if new_velocity.length_squared() > 0.01:  # Only rotate if we're moving
		var target_rotation = atan2(new_velocity.x, new_velocity.z)
		var current_rotation = character.rotation.y
		
		# Find shortest rotation path
		var rotation_diff = fmod(target_rotation - current_rotation + PI, TAU) - PI
		
		# Smoothly interpolate rotation
		character.rotation.y += rotation_diff * rotation_speed * delta
		
	# Apply movement
	character.velocity = character.velocity.move_toward(new_velocity, .25)
	character.move_and_slide()

# calling functions need to call await with this
func move_to(new_position: Vector2) -> bool:
	if debug_info: LogManager.add_message("Agent: Moving to ", new_position)
	
	# Set the target and wait one frame for the navigation to update
	set_target_position(Vector3(new_position.x, 0, new_position.y))
	
	# Wait until we get a definitive answer about reachability
	while not is_target_reachable() and not is_navigation_finished():
		await get_tree().process_frame
	
	# Check if target is reachable
	if not is_target_reachable():
		if debug_info: LogManager.add_message("Agent: Target unreachable")
		return false
	
	# Wait for movement to complete
	await navigation_finished
	if debug_info: LogManager.add_message("Agent: Target reached")
	return true

# Optional: Set agent rotation directly (useful for initial orientation)
func set_rotation(angle: float):
	character.rotation.y = angle
