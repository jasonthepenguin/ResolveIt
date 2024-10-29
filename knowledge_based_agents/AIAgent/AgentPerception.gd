class_name AgentPerception

signal collision_detected(object: Node3D, point: Vector3, normal: Vector3)

var show_debug: bool = false

# Required references
var character: CharacterBody3D
var world_state: WorldState

func _init(character_body: CharacterBody3D, initial_world_state: WorldState) -> void:
	character = character_body
	world_state = initial_world_state
	
	if not character or not world_state:
		push_error("AgentPerception requires valid CharacterBody3D and WorldState references!")

func scan_for_nearest_affordance(affordance_type: Affordance.Type) -> Dictionary:
	"""
	Scans for the nearest affordance of specified type within perception radius.
	Returns a dictionary with:
	- found: bool - whether an affordance was found
	- affordance: Affordance - the found affordance (null if not found)
	- distance: float - distance to affordance (INF if not found)
	"""
	var result = {
		"found": false,
		"affordance": null,
		"distance": INF
	}
	
	var affordances = Affordance.get_affordance_list(world_state.get_tree(), affordance_type)
	
	# Find nearest affordance
	for affordance in affordances:
		var distance = character.global_position.distance_to(
			affordance.parent_object.global_position
		)
		
		result.found = true
		result.affordance = affordance
		result.distance = distance
		
		if show_debug:
			LogManager.add_message(
				"Found affordance: ", 
				Affordance.to_str(affordance_type),
				" at distance: ",
				distance
			)
	
	return result

func process_collisions() -> void:
	"""
	Internal method to process current frame collisions and emit signals.
	"""
	# Skip collision processing if character is only touching the ground
	if character.is_on_floor_only():
		return
		
	for i in character.get_slide_collision_count():
		var collision = character.get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is Node3D:
			collision_detected.emit(
				collider,
				collision.get_position(),
				collision.get_normal()
			)
			
			if show_debug:
				LogManager.add_message("Collision detected with: ", collider.name)
