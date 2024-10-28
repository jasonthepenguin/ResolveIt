# TeacherAgent.gd
class_name TeacherAgent extends BaseAgent

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()
@onready var emotion_controller = get_parent().get_node("EmotionController")

# Teacher-specific emotional influence positions
const TEACHING_SATISFACTION = Vector2(0, -0.9)  # Strong happiness
const DISRUPTION_ANGER = Vector2(0.8, 0.2)      # Primary anger with some arousal
const EQUIPMENT_SADNESS = Vector2(-0.7, 0.3)    # Primary sadness with some tension

var busy = false

func _init():
	super()
	_initialize_knowledge()
	update_interval = 1.0

func _ready():
	emotion_controller.emotion_changed.connect(_on_emotion_changed)
	
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
		"computer_is_broken"
	])
	kb.add_rule("equipment_failure", [
		"projector_is_off"
	])
	
	# Map actions
	map_action("in_position", move_to_position)
	map_action("projector_is_on", turn_projector_on)
	map_action("projector_is_off", turn_projector_on)
	map_action("computer_is_broken", fix_computer)

func update_state():
	if busy:
		return
		
	# Update emotional influences based on current state
	_update_emotional_influences()
		
	# Handle teaching state
	if not kb.has_fact("is_teaching"):
		if kb.query_goal("is_disrupted").achieved:
			if show_debug:
				LogManager.add_message(LogManager.id_format("Teacher"), "handling disruption")
			kb.remove_fact("is_teaching")
		else:
			var teaching_query = kb.query_goal("can_teach")
			if teaching_query.achieved:
				kb.add_fact("is_teaching")
				LogManager.add_message(LogManager.id_format("Teacher"), "is teaching")
			else:
				if show_debug:
					LogManager.add_message(LogManager.id_format("Teacher"), "Can't teach, missing:", teaching_query.missing_conditions)
				make_decision(teaching_query.missing_conditions)
	
	# React to current emotional states
	_handle_emotional_states()
	
func _update_emotional_influences():
	emotion_controller.clear_influences()
	
	# Add teaching satisfaction if teaching
	if kb.has_fact("is_teaching"):
		emotion_controller.add_influence("teaching", TEACHING_SATISFACTION)
	
	# Add equipment problem influences
	if kb.has_fact("computer_is_broken"):
		emotion_controller.add_influence("computer", EQUIPMENT_SADNESS)
	
	if kb.has_fact("projector_is_off"):
		emotion_controller.add_influence("projector", DISRUPTION_ANGER)

func _on_emotion_changed(emotion: int, intensity: float):
	# Clear previous emotional states
	kb.remove_fact("is_storming_out")
	kb.remove_fact("is_discouraged")
	kb.remove_fact("is_enthusiastic")
	kb.remove_fact("is_frustrated")
	
	# Update knowledge base with teacher-specific interpretations
	match emotion:
		FuzzyEmotionTriangle.Emotion.HAPPY:
			if intensity > EmotionController.STRONG_EMOTION_THRESHOLD:
				kb.add_fact("is_enthusiastic")
		
		FuzzyEmotionTriangle.Emotion.ANGRY:
			if intensity > EmotionController.STRONG_EMOTION_THRESHOLD:
				kb.add_fact("is_storming_out")
			elif intensity > EmotionController.MODERATE_EMOTION_THRESHOLD:
				kb.add_fact("is_frustrated")
				
		FuzzyEmotionTriangle.Emotion.SAD:
			if intensity > EmotionController.STRONG_EMOTION_THRESHOLD:
				kb.add_fact("is_discouraged")

func _handle_emotional_states():
	if kb.has_fact("is_storming_out"):
		storm_out()
	elif kb.has_fact("is_discouraged"):
		consider_canceling_class()
	elif kb.has_fact("is_enthusiastic"):
		teach_enthusiastically()
	elif kb.has_fact("is_frustrated"):
		show_frustration()
			
func make_decision(conditions: Array):
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), "making decision")
	busy = true
	for condition in conditions:
		await run_action(condition)
	busy = false
	
func move_to_position():
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.seek_affordance_format(Affordance.Type.CAN_PRESENT))
	var nodes = Affordance.get_affordance_list(get_tree(), Affordance.Type.CAN_PRESENT)
	if nodes.is_empty():
		return # cannot reach position
	
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.found_affordance_format())
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), "moving to position")
	var position = nodes[0].parent_object.global_position
	if await agent_actuator.move_to(Vector2(position.x, position.z)):
		kb.add_fact("in_position")
		if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), "in position")
	
func turn_projector_on():
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.seek_affordance_format(Affordance.Type.PROJECTOR_ON))
	var nodes = Affordance.get_affordance_list(get_tree(), Affordance.Type.PROJECTOR_ON)
	if nodes.is_empty():
		return # cannot reach position
	
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.found_affordance_format())
	if show_debug: LogManager.add_message(LogManager.id_format("Teacher"), "turning projector on")
	var projector = nodes[0].parent_object as Projector
	projector.set_projector(true)
	kb.add_fact("projector_is_on") # todo: done through perception
	
func fix_computer():
	pass

func storm_out():
	pass

func start_yelling():
	pass

func teach():
	pass

func consider_canceling_class():
	pass
	
func teach_enthusiastically():
	pass
	
func show_frustration():
	pass
