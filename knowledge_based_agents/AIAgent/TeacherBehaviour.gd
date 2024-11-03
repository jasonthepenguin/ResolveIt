class_name TeacherBehaviour extends AgentBaseBehaviour

var tiredness = 0.0
var happiness = 0.0

var states = {
	"tired": 0.0,
	"happy": 0.0
}

func _init():
	super()
	self.agent_name = "Teacher"
	_initialize_knowledge()
	update_interval = 1.0

func _initialize_knowledge():
	# Main teaching requirement - need position and working projector
	kb.add_rule("can_teach", [
		"in_position",
		"projector_is_on"
	])
	
	# Map actions
	map_action("in_position", move_to_teaching_position)
	map_action("projector_is_on", turn_projector_on)

func _handle_state():
	check_state()
	
	if (kb.has_fact("is_teaching")):
		change_state("happy", 0.2)
		change_state("tired", 0.1)
		
	if (kb.has_fact("is_wandering")):
		change_state("happy", -0.1)
		change_state("tired", -0.2)
		
	if kb.has_fact("want_teach"):
		if show_debug:
				LogManager.add_message(LogManager.id_format(agent_name), 
				"feeling unhappy, wants to teach")
		set_wander(false)
		var teaching_query = kb.query_goal("can_teach")
		if teaching_query.achieved:
			kb.add_fact("is_teaching")
			kb.remove_fact("want_teach")
			kb.remove_fact("is_wandering")
			LogManager.add_message(LogManager.id_format(agent_name), "is teaching")
		else:
			if show_debug:
				LogManager.add_message(LogManager.id_format(agent_name),
					"Can't teach, missing:", teaching_query.missing_conditions)
			make_decision(teaching_query.missing_conditions)
	elif kb.has_fact("want_wander"):
		if show_debug:
				LogManager.add_message(LogManager.id_format(agent_name), 
				"feeling tired, going to wander")
		kb.add_fact("is_wandering")
		kb.remove_fact("want_wander")
		kb.remove_fact("in_position")
		kb.remove_fact("is_teaching")
		set_wander(true)
	
	show_emotion()

# Teacher-specific actions
func change_state(id: String, increment: float):
	states[id] = clampf(states[id] + increment, 0.0, 1.0)
	
func check_state():
	if (states["happy"] == 0.0):
		kb.add_fact("want_teach")
		kb.remove_fact("want_wander")
	elif (states["tired"] == 1.0):
		kb.add_fact("want_wander")
		kb.remove_fact("want_teach")
	
func show_emotion():
	if (states["happy"] > 0.7):
		emoji_manager.display_emotion(EmojiManager.State.HAPPY)
	else:
		emoji_manager.display_emotion(EmojiManager.State.NEUTRAL)

func move_to_teaching_position():
	if await move_to_affordance(Affordance.Type.CAN_PRESENT):
		kb.add_fact("in_position")
		if show_debug: 
			LogManager.add_message(LogManager.id_format(agent_name), "in position")

func turn_projector_on():
	var scan_result = perception.scan_for_nearest_affordance(Affordance.Type.PROJECTOR_ON)
	if not scan_result.found:
		return
		
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "turning projector on")
		
	var projector = scan_result.affordance.parent_object as Projector
	projector.set_projector(true)
	kb.add_fact("projector_is_on")

func set_wander(state: bool):
	actuator.random_movement = state
