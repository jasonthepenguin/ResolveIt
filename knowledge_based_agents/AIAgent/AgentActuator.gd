# AgentActuator.gd
class_name AgentActuator extends NavigationAgent3D

var speed: float = 2.0
var rotation_speed: float = 10.0  # Speed at which the agent rotates
var debug_info: bool = false
var random_movement: bool = false
var update_interval: float = 1.5
var max_stuck_time: float = 0.5
var distance_threshold: float = 0.001

@onready var agent: AIAgent = get_parent()
var accumulator = 0.0
var random_move_accumulator = 0.0
var last_location: Vector3
var stuck_time = 0.0
var current_location: Vector3
var next_location: Vector3
var new_velocity: Vector3
var current_random_target: Vector2

func _physics_process(delta):
	current_location = agent.global_position
	
	# Handle random movement
	if random_movement:
		random_move_accumulator += delta
		if random_move_accumulator >= update_interval:
			random_move_accumulator = 0.0
			_set_random_target()
	
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
		var current_rotation = agent.rotation.y
		
		# Find shortest rotation path
		var rotation_diff = fmod(target_rotation - current_rotation + PI, TAU) - PI
		
		# Smoothly interpolate rotation
		agent.rotation.y += rotation_diff * rotation_speed * delta
		
	# Apply movement
	agent.velocity = agent.velocity.move_toward(new_velocity, .25)
	agent.move_and_slide()
	
	# Check if we're stuck
	if not is_navigation_finished():
		if current_location.distance_to(last_location) < distance_threshold:
			stuck_time += delta
			if stuck_time > max_stuck_time:
				if random_movement:
					_set_random_target()  # Try a new random target if we're stuck
				stuck_time = 0
		else:
			stuck_time = 0
	
	last_location = current_location

func _set_random_target():
	# Get a random point within reasonable bounds
	# Assuming a 20x20 area centered on the agent
	var random_x = randf_range(-10, 10)
	var random_z = randf_range(-10, 10)
	
	# Get current position
	var agent_pos = agent.global_position
	
	# Set target relative to current position
	current_random_target = Vector2(
		agent_pos.x + random_x,
		agent_pos.z + random_z
	)
	
	if debug_info:
		LogManager.add_message("Agent: New random target ", current_random_target)
	
	# Set the navigation target
	move_to(current_random_target)

# calling functions need to call await with this
func move_to(new_position: Vector2) -> bool:
	if debug_info: LogManager.add_message("Agent: Moving to ", new_position)
	agent.movement_started.emit()
	
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
	agent.movement_stopped.emit()
	
	return true

# Optional: Set agent rotation directly (useful for initial orientation)
func set_rotation(angle: float):
	agent.rotation.y = angle
