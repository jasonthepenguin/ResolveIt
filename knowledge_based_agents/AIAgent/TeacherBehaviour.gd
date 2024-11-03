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
		change_state("tired", 0.2)
		
	if (kb.has_fact("is_wandering")):
		change_state("happy", -0.2)
		change_state("tired", -0.2)
		
	if kb.has_fact("want_teach"):
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
	if (states["tired"] == 1.0):
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

## Teacher-specific emotional influence positions
#const TEACHING_SATISFACTION = Vector2(0, -0.3)  # Moderate happiness from teaching
#const NATURAL_NEUTRAL = Vector2(0, 0.3)      # Natural drift towards neutral when not teaching
#
#var teaching_timer: float = 0.0
#const HAPPY_WANDER_THRESHOLD: float = 5.0  # Time to wait while happy before wandering
#
#func _init():
	#super()
	#self.agent_name = "Teacher"
	#_initialize_knowledge()
	#_initialize_emotional_influences()
	#_initialize_starting_state()
#
#func _initialize_starting_state():
	## Start in a neutral emotional state
	#kb.add_fact("is_neutral")
	#kb.add_fact("not_teaching")  # Initially not teaching
	#
	## Ensure we're not in any other states initially
	#kb.remove_fact("is_teaching")
	#kb.remove_fact("is_happy")
	#kb.remove_fact("should_wander")
	#kb.remove_fact("is_wandering")
	#teaching_timer = 0.0
	#
	## Ensure random movement is off initially
	#if actuator:
		#actuator.random_movement = false
#
#func _initialize_knowledge():
	## Main teaching requirement - need position and working projector
	#kb.add_rule("can_teach", [
		#"in_position",
		#"projector_is_on"
	#])
	#
	## Map actions
	#map_action("in_position", move_to_teaching_position)
	#map_action("projector_is_on", turn_projector_on)
	#
	## Map emotional actions
	#map_emotional_action("is_happy", on_happy)
	#map_emotional_action("is_neutral", on_neutral)
	#map_emotional_action("should_wander", start_wandering)
#
#func _initialize_emotional_influences():
	## Teaching makes the teacher gradually happier
	#map_emotional_influence("is_teaching", "teaching", TEACHING_SATISFACTION)
	## Natural drift towards neutral when not teaching
	#map_emotional_influence("not_teaching", "neutral_drift", NATURAL_NEUTRAL)
	#
	## Map emotions to facts with different thresholds to prevent overlap
	#map_emotion_state(FuzzyEmotionTriangle.Emotion.HAPPY, 0.6, "is_happy")
	#map_emotion_state(FuzzyEmotionTriangle.Emotion.NEUTRAL, 0.6, "is_neutral")
#
#func _handle_state():
	## Don't process teaching logic if we're wandering
	#if kb.has_fact("is_wandering"):
		#return
#
	## Clear any conflicting emotional states
	#if kb.has_fact("is_happy"):
		#kb.remove_fact("is_neutral")
	#elif kb.has_fact("is_neutral"):
		#kb.remove_fact("is_happy")
		#
	## Handle happy state
	#if kb.has_fact("is_happy"):
		#if kb.has_fact("is_teaching"):
			#teaching_timer += update_interval
			#if teaching_timer >= HAPPY_WANDER_THRESHOLD:
				#kb.add_fact("should_wander")
				#teaching_timer = 0.0
	#
	## Handle neutral state
	#elif kb.has_fact("is_neutral"):
		#if not kb.has_fact("is_teaching"):
			#var teaching_query = kb.query_goal("can_teach")
			#if teaching_query.achieved:
				#start_teaching()
			#else:
				#if show_debug:
					#LogManager.add_message(LogManager.id_format(agent_name), 
						#"Want to teach, missing:", teaching_query.missing_conditions)
				#make_decision(teaching_query.missing_conditions)
#
#func start_teaching():
	#if show_debug:
		#LogManager.add_message(LogManager.id_format(agent_name), "starting to teach")
	#kb.add_fact("is_teaching")
	#kb.remove_fact("not_teaching")
	#kb.remove_fact("is_wandering")
	#teaching_timer = 0.0
#
#func start_wandering():
	#if show_debug:
		#LogManager.add_message(LogManager.id_format(agent_name), "feeling happy enough to wander")
	#
	## Stop teaching and start wandering
	#kb.remove_fact("is_teaching")
	#kb.add_fact("not_teaching")
	#kb.remove_fact("should_wander")
	#kb.add_fact("is_wandering")
	#actuator.random_movement = true
#
#func on_happy():
	#if kb.has_fact("is_neutral"):
		#kb.remove_fact("is_neutral")
	#if show_debug:
		#LogManager.add_message(LogManager.id_format(agent_name), "feeling happy")
#
#func on_neutral():
	#if kb.has_fact("is_happy"):
		#kb.remove_fact("is_happy")
		#
	#if kb.has_fact("is_wandering"):
		## Only stop wandering when we return to neutral
		#if show_debug:
			#LogManager.add_message(LogManager.id_format(agent_name), "done wandering, returning to teaching")
		#actuator.random_movement = false
		#kb.remove_fact("is_wandering")
		#
	#if show_debug:
		#LogManager.add_message(LogManager.id_format(agent_name), "feeling neutral")
#
## Helper actions remain unchanged
#func move_to_teaching_position():
	#if await move_to_affordance(Affordance.Type.CAN_PRESENT):
		#kb.add_fact("in_position")
		#if show_debug: 
			#LogManager.add_message(LogManager.id_format(agent_name), "in position")
#
#func turn_projector_on():
	#var scan_result = perception.scan_for_nearest_affordance(Affordance.Type.PROJECTOR_ON)
	#if not scan_result.found:
		#return
		#
	#if show_debug:
		#LogManager.add_message(LogManager.id_format(agent_name), "turning projector on")
		#
	#var projector = scan_result.affordance.parent_object as Projector
	#projector.set_projector(true)
	#kb.add_fact("projector_is_on")


