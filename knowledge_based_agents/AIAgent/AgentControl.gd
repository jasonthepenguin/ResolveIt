extends CharacterBody3D

@export var random_movement: bool = false
@export var apply_impulse: bool = true

func _ready():
	if not random_movement:
		$AgentRandomMovement.set_process(false)
		$AgentRandomMovement.set_physics_process(false)
	if not apply_impulse:
		$CharacterImpulseApplicator.set_process(false)
		$CharacterImpulseApplicator.set_physics_process(false)
		
func get_body() -> CharacterBody3D:
	return self
		
func get_nav_agent() -> NavigationAgent3D:
	return $NavigationAgent3D
	
func get_actuator() -> AgentNavActuator:
	return $AgentNavActuator
	
func get_random_movement() -> AgentRandomMovement:
	return $AgentRandomMovement
	
func get_impulse_applicator() -> CharacterImpulseApplicator:
	return $CharacterImpulseApplicator
