extends BaseAgent

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()
@onready var carry_actuator: ObjectCarryActuator = get_parent().get_node("ObjectCarryActuator")
@export var throw_force = 10.0

func _ready():
	_initialize()
	
func _initialize():
	# Initial state facts
	kb.add_fact("not_holding_object")
	kb.add_fact("not_at_target")
	kb.add_fact("can_move")
	kb.add_fact("can_reach_target")
	
	kb.add_rule("pickup_object", [
		"not_holding_object",
		"near_pickup_object",
		"can_pickup"
	])
	
	kb.add_rule("go_to_target", [
		"holding_object",
		"not_at_target",
		"can_reach_target"
	])
	
	kb.add_rule("throw_object", [
		"holding_object",
		"at_target"
	])

func update_state():
	_update_proximity_states()
	
	if kb.has_fact("moving_to_object"):
		_handle_moving_to_object()
	elif kb.has_fact("moving_to_target"):
		_handle_moving_to_target()
	else:
		_decide_action()

func _decide_action():
	if kb.query_goal("pickup_object").achieved:
		_start_moving_to_object()
	elif kb.query_goal("go_to_target").achieved:
		_start_moving_to_target()
	elif kb.query_goal("throw_object").achieved:
		_throw_object()

func _update_proximity_states():
	var found_pickup = false
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_PICKUP):
			var object = affordance.parent_object
			# Check if it's a RigidBodyCustom
			if not object is RigidBodyCustom:
				continue
				
			var distance = get_parent().global_position.distance_to(object.global_position)
			if distance < 20.0:
				kb.add_fact("near_pickup_object")
				kb.add_fact("can_pickup")
				found_pickup = true
				break
	
	if not found_pickup:
		kb.remove_fact("near_pickup_object")
		kb.remove_fact("can_pickup")
	
	if kb.has_fact("moving_to_target"):
		if not nav_agent.is_target_reachable():
			kb.remove_fact("moving_to_target")
			kb.remove_fact("can_reach_target")
		elif nav_agent.is_navigation_finished():
			kb.remove_fact("moving_to_target")
			kb.remove_fact("not_at_target")
			kb.add_fact("at_target")
			print("Arrived at target")

func _start_moving_to_object():
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_PICKUP) and affordance.parent_object is RigidBodyCustom:
			var location = affordance.parent_object.global_transform.origin
			agent_actuator.move_to(Vector2(location.x, location.z))
			kb.add_fact("moving_to_object")
			break

func _start_moving_to_target():
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_THROW):
			var location = affordance.parent_object.global_transform.origin
			agent_actuator.move_to(Vector2(location.x, location.z))
			kb.add_fact("moving_to_target")
			break

func _handle_moving_to_object():
	if nav_agent.is_navigation_finished():
		kb.remove_fact("moving_to_object")
		_pickup_object()

func _handle_moving_to_target():
	pass  # Handled in _update_proximity_states()

func _pickup_object():
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_PICKUP):
			var pickup_object = affordance.parent_object
			if pickup_object is RigidBodyCustom:
				carry_actuator.pickup_object(pickup_object)
				kb.remove_fact("not_holding_object")
				kb.add_fact("holding_object")
				break

func _throw_object():
	if carry_actuator.is_carrying():
		carry_actuator.throw_object(throw_force)
		kb.remove_fact("holding_object")
		kb.add_fact("not_holding_object")
		kb.remove_fact("at_target")
		kb.add_fact("not_at_target")
