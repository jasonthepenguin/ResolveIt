# CharacterImpulseApplicator.gd
class_name ImpulseApplicator

var push_force: float = 2.0
var character: CharacterBody3D
var perception: AgentPerception

func _init(character_body: CharacterBody3D, agent_perception: AgentPerception):
	character = character_body
	perception = agent_perception
	perception.collision_detected.connect(_on_collision_detected)
	
	if not character or not perception:
		push_error("ImpulseApplicator requires valid CharacterBody3D and AgentPerception references!")

func _on_collision_detected(object: Node3D, collision_point: Vector3, normal: Vector3):
	if object is RigidBodyCustom and not character.is_on_floor_only():
		var rb = object as RigidBodyCustom
		var impulse = -normal * push_force
		
		# Convert world collision point to position relative to RigidBody's center
		var point_relative = collision_point - rb.global_position
		
		rb.apply_impulse_off_centre(impulse, point_relative)
