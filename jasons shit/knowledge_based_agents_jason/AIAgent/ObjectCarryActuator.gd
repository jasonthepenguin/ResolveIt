class_name ObjectCarryActuator extends Node

@export var carry_height: float = 1.0
@export var carry_distance: float = 0.5
@export var carry_smoothing: float = 15.0  # Higher = smoother but slower
@export var throw_upward_boost: float = 0.3  # Adds slight upward arc to throws

@onready var character: CharacterBody3D = get_parent()
var carried_object: RigidBodyCustom = null
var initial_object_transform: Transform3D

func _physics_process(delta: float) -> void:
	if carried_object:
		_update_carried_object_position(delta)

func _update_carried_object_position(delta: float) -> void:
	# Get the forward direction of the agent (negative Z is forward in Godot)
	var forward := -character.transform.basis.z
	
	# Calculate the desired carry position
	var target_position := character.global_position + \
						 (forward * carry_distance) + \
						 (Vector3.UP * carry_height)
	
	# Get current object position
	var current_position := carried_object.global_position
	
	# Smoothly interpolate to target position
	var new_position := current_position.lerp(target_position, delta * carry_smoothing)
	
	# Update the object's transform while maintaining its original rotation
	var new_transform := carried_object.global_transform
	new_transform.origin = new_position
	#carried_object.global_transform = new_transform
	carried_object.set_trans(new_transform)

func pickup_object(object: RigidBodyCustom) -> void:
	if carried_object != null:
		return  # Already carrying something
		
	carried_object = object
	
	# Store initial transform for potential restoration
	initial_object_transform = object.global_transform
	
	# Disable physics while carrying
	#carried_object.set_physics_process(false)
	carried_object.set_integrate_forces_enabled(false)
	carried_object.set_gravity_enabled(false)
	
	# Store original collision settings
	carried_object.set_meta("original_layer", carried_object.get_collision_layer())
	carried_object.set_meta("original_mask", carried_object.get_collision_mask())
	
	# Disable collisions while carried
	carried_object.set_collision_layer(0)
	carried_object.set_collision_mask(0)

func throw_object(force: float = 10.0) -> void:
	if !is_carrying():
		return
		
	# Re-enable physics
	#carried_object.set_physics_process(true)
	carried_object.set_integrate_forces_enabled(true)
	carried_object.set_gravity_enabled(true)
	
	# Restore collision settings
	carried_object.set_collision_layer(carried_object.get_meta("original_layer"))
	carried_object.set_collision_mask(carried_object.get_meta("original_mask"))
	
	# Calculate throw direction with slight upward arc
	var throw_direction: Vector3 = -character.transform.basis.z + (Vector3.UP * throw_upward_boost)
	throw_direction = throw_direction.normalized()
	
	# Apply the throw impulse
	carried_object.apply_impulse(throw_direction * force)
	
	carried_object = null

func drop_object() -> void:
	if !is_carrying():
		return
		
	# Re-enable physics
	#carried_object.set_physics_process(true)
	carried_object.set_integrate_forces_enabled(true)
	carried_object.set_gravity_enabled(true)
	
	# Restore collision settings
	carried_object.set_collision_layer(carried_object.get_meta("original_layer"))
	carried_object.set_collision_mask(carried_object.get_meta("original_mask"))
	
	carried_object = null

func is_carrying() -> bool:
	return carried_object != null
