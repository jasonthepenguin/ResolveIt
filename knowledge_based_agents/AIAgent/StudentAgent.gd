class_name StudentAgent extends AgentBaseBehaviour

# Student-specific emotional influence positions
const LEARNING_JOY = Vector2(0, -0.8)        # Strong happiness from learning
const CONFUSION_SADNESS = Vector2(-0.6, 0.2)  # Mild sadness from confusion
const DISRUPTION_STRESS = Vector2(0.5, 0.3)   # Mild stress from disruptions
const DEEP_SADNESS = Vector2(-0.8, 0.4)       # Deep sadness when unable to learn

func _init():
	super()
	agent_name = "Student"
	_initialize_knowledge()
	_initialize_emotional_influences()

func _initialize_knowledge():
	# Study requirements
	kb.add_rule("can_study", [
		"is_in_study_location",
		"computer_is_on",
		"teacher_is_teaching"
	])
	
	# Study location can be classroom
	kb.add_rule("is_in_study_location", [
		"is_in_classroom"
	])
	
	# Teacher teaching requirement
	kb.add_rule("teacher_is_teaching", [
		"teacher_has_presentation",
		"teacher_is_present"
	])
	
	kb.add_rule("teacher_has_presentation", [
		"computer_is_on",
		"projector_is_on"
	])
	
	# Map emotional actions
	map_emotional_action("is_crying", start_crying)
	map_emotional_action("is_frustrated", show_frustration)
	map_emotional_action("is_happy", express_happiness)

func _initialize_emotional_influences():
	# Map facts to emotional influences
	map_emotional_influence("is_studying", "learning", LEARNING_JOY)
	map_emotional_influence("is_confused", "confusion", CONFUSION_SADNESS)
	map_emotional_influence("class_disrupted", "disruption", DISRUPTION_STRESS)
	map_emotional_influence("unable_to_study", "sadness", DEEP_SADNESS)

	# Map emotions to facts
	map_emotion_state(FuzzyEmotionTriangle.Emotion.HAPPY, 
		EmotionController.STRONG_EMOTION_THRESHOLD, "is_happy")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.SAD, 
		EmotionController.STRONG_EMOTION_THRESHOLD, "is_crying")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.ANGRY, 
		EmotionController.MODERATE_EMOTION_THRESHOLD, "is_frustrated")

func _handle_state():
	# Check if we can study
	var study_query = kb.query_goal("can_study")
	if study_query.achieved:
		kb.add_fact("is_studying")
		kb.remove_fact("unable_to_study")
		kb.remove_fact("is_confused")
		kb.remove_fact("class_disrupted")
	else:
		kb.remove_fact("is_studying")
		kb.add_fact("unable_to_study")
		
		# Add appropriate contextual emotions based on what's preventing study
		if not kb.has_fact("teacher_is_present"):
			kb.add_fact("class_disrupted")
		elif not kb.has_fact("projector_is_on") or not kb.has_fact("computer_is_on"):
			kb.add_fact("is_confused")
			
		if show_debug:
			LogManager.add_message(LogManager.id_format(agent_name), 
				"Cannot study yet. Need: ", study_query.missing_conditions)
		
		# Special case: Leave room if crying and unable to study
		if kb.has_fact("is_crying") and kb.has_fact("unable_to_study"):
			await leave_room()

# Student-specific actions
func start_crying():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "starts crying")

func show_frustration():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "shows frustration")

func express_happiness():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "expresses happiness")

func leave_room():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "leaving room due to emotional distress")
	
	busy = true
	
	# Try to find an exit affordance and move to it
	var exit_nodes = Affordance.get_affordance_list(scene_tree, Affordance.Type.CAN_USE)
	if not exit_nodes.is_empty():
		var exit_node = exit_nodes[0]
		var exit_position = exit_node.parent_object.global_position
		var success = await actuator.move_to(Vector2(exit_position.x, exit_position.z))
		
		if success:
			if show_debug:
				LogManager.add_message(LogManager.id_format(agent_name), "has left the room")
			# Since we're now a behavior, we need to signal the parent AIAgent to clean up
			scene_tree.get_current_scene().queue_free()
		else:
			if show_debug:
				LogManager.add_message(LogManager.id_format(agent_name), "couldn't reach exit, staying in room")
			busy = false
	else:
		if show_debug:
			LogManager.add_message(LogManager.id_format(agent_name), "couldn't find exit, staying in room")
		busy = false
