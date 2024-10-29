extends AgentBaseBehaviour

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()

var stop = false
var move_to_a = false
var move_to_b = false

func _ready():
	_initialize()
	
func _initialize():
	kb.add_fact("not_at_a")
	kb.add_fact("not_at_b")
	kb.add_fact("can_reach_a")
	kb.add_fact("can_reach_b")
	
	kb.add_rule("go_to_a", [
		"not_at_a",
		"not_at_b",
		"can_reach_a"
	])
	
	kb.add_rule("go_to_a", [
		"not_at_a",
		"at_b",
		"can_reach_a"
	])
	
	kb.add_rule("go_to_b", [
		"at_a",
		"not_at_b",
		"can_reach_b"
	])

func update_state():
	if stop:
		return
		
	move_to_a = kb.has_fact("moving_to_a")
	move_to_b = kb.has_fact("moving_to_b")
	
	if move_to_a or move_to_b:
		if not nav_agent.is_target_reachable():
			if move_to_a:
				kb.remove_fact("moving_to_a")
				kb.remove_fact("can_reach_a")
			if move_to_b:
				kb.remove_fact("moving_to_b")
				kb.remove_fact("can_reach_b")
		if (nav_agent.is_navigation_finished()):
			if move_to_a:
				kb.remove_fact("moving_to_a")
				kb.remove_fact("not_at_a")
				kb.remove_fact("at_b")
				kb.add_fact("at_a")
				kb.add_fact("not_at_b")
				print("Arrived at a")
			elif move_to_b:
				kb.remove_fact("moving_to_b")
				kb.remove_fact("not_at_b")
				kb.remove_fact("at_a")
				kb.add_fact("at_b")
				kb.add_fact("not_at_a")
				print("Arrived at b")
	else:
		_decide_action()
	
func _decide_action():
	if (kb.query_goal("go_to_a").achieved):
		kb.add_fact("moving_to_a")
		_go_to_location(Affordance.Type.CAN_PRESENT)
		print("Moving to a")
	elif (kb.query_goal("go_to_b").achieved):
		kb.add_fact("moving_to_b")
		_go_to_location(Affordance.Type.CAN_STUDY)
		print("Moving to b")
	elif (not kb.has_fact("can_reach_a")):
		print("cannot reach a")
		stop = true
	elif (not kb.has_fact("can_reach_a")):
		print("cannot reach b")
		stop = true

func _go_to_location(affordance_location: Affordance.Type):
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(affordance_location):
			var location = affordance.parent_object.global_transform.origin
			agent_actuator.move_to(Vector2(location.x, location.z))
			break
