class_name TeacherBehaviour extends AgentBaseBehaviour

# Teacher-specific emotional influence positions
const TEACHING_SATISFACTION = Vector2(0, -0.9)  # Strong happiness
const DISRUPTION_ANGER = Vector2(0.8, 0.2)      # Primary anger with some arousal
const EQUIPMENT_SADNESS = Vector2(-0.7, 0.3)    # Primary sadness with some tension

func _init():
	super()
	self.agent_name = "Teacher"
	_initialize_knowledge()
	_initialize_emotional_influences()
	update_interval = 1.0

func _initialize_knowledge():
	# Main teaching requirement - need position and working projector
	kb.add_rule("can_teach", [
		"in_position",
		"projector_is_on"
	])
	
	# Disruption conditions
	kb.add_rule("is_disrupted", [
		"is_teaching",
		"equipment_failure"
	])
	kb.add_rule("equipment_failure", [
		"projector_is_off"
	])
	
	# Map actions
	map_action("in_position", move_to_teaching_position)
	map_action("projector_is_on", turn_projector_on)
	map_action("projector_is_off", turn_projector_on)
	map_action("computer_is_broken", fix_computer)
	
	# Map emotional actions
	map_emotional_action("is_storming_out", storm_out)
	map_emotional_action("is_discouraged", consider_canceling_class)
	map_emotional_action("is_enthusiastic", teach_enthusiastically)
	map_emotional_action("is_frustrated", show_frustration)

func _initialize_emotional_influences():
	# Map facts to emotional influences
	map_emotional_influence("is_teaching", "teaching", TEACHING_SATISFACTION)
	map_emotional_influence("computer_is_broken", "computer", EQUIPMENT_SADNESS)
	map_emotional_influence("projector_is_off", "projector", DISRUPTION_ANGER)
	
	# Map emotions to facts
	map_emotion_state(FuzzyEmotionTriangle.Emotion.HAPPY, 
		EmotionController.STRONG_EMOTION_THRESHOLD, "is_enthusiastic")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.ANGRY, 
		EmotionController.STRONG_EMOTION_THRESHOLD, "is_storming_out")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.ANGRY, 
		EmotionController.MODERATE_EMOTION_THRESHOLD, "is_frustrated")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.SAD, 
		EmotionController.STRONG_EMOTION_THRESHOLD, "is_discouraged")

func _handle_state():
	if not kb.has_fact("is_teaching"):
		if kb.query_goal("is_disrupted").achieved:
			if show_debug:
				LogManager.add_message(LogManager.id_format(agent_name), "handling disruption")
			kb.remove_fact("is_teaching")
		else:
			var teaching_query = kb.query_goal("can_teach")
			if teaching_query.achieved:
				kb.add_fact("is_teaching")
				LogManager.add_message(LogManager.id_format(agent_name), "is teaching")
			else:
				if show_debug:
					LogManager.add_message(LogManager.id_format(agent_name), 
						"Can't teach, missing:", teaching_query.missing_conditions)
				make_decision(teaching_query.missing_conditions)

# Teacher-specific actions
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

func fix_computer():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "fixing computer")
	await scene_tree.create_timer(2.0).timeout
	kb.remove_fact("computer_is_broken")

func storm_out():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "storms out of the room")

func teach_enthusiastically():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "teaches with enthusiasm")

func show_frustration():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "shows frustration")

func consider_canceling_class():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "considers canceling class")
