class_name AgentThrowActuator extends Node

@export var throw_force = 10.0
@export var throw_range = 10.0
@export var debug_info: bool = false

@onready var character: CharacterBody3D = get_parent()

func throw_object(target: Node3D):
	if not target:
		return
		
	if target is RigidBodyCustom or target is RigidBody3D:
		var throw_direction = get_throw_direction()
		var impulse = throw_direction * throw_force
		
		# If object is close enough to throw
		var distance = character.global_position.distance_to(target.global_position)
		if distance <= throw_range:
			if debug_info: print("Throwing object with force: ", impulse)
			
			if target is RigidBodyCustom:
				target.apply_impulse_off_centre(impulse, Vector3.ZERO)
			else:
				target.apply_impulse(impulse, Vector3.ZERO)
				
			# Remove CAN_THROW affordance after throwing
			var affordance = target.get_node_or_null("Affordance")
			if affordance:
				affordance.remove_affordance(Affordance.Type.CAN_THROW)
			return true
	return false

func get_throw_direction() -> Vector3:
	var random_angle = randf_range(-PI/4, PI/4)
	var base_direction = Vector3(cos(random_angle), 1.0, sin(random_angle))
	return base_direction.normalized()
