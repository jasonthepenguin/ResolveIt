# TeacherAgent.gd
class_name TeacherAgent extends BaseAgent

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()
var busy = false

var anger_level = 0  # 0: normal, 1: angry, 2: really angry, 3: totally angry

func _init():
	super()
	_initialize()

func _ready():
	pass
	
func _initialize():
	# Main teaching requirement - need position and working projector
	kb.add_rule("can_teach", [
		"in_position",
		"projector_is_on"
	])
	map_action("in_position", move_to_position)
	map_action("projector_is_on", turn_projector_on)
	
	# Disruption conditions
	kb.add_rule("is_disrupted", [
		"is_teaching",
		"equipment_failure"
	])
	
	kb.add_rule("equipment_failure", [
		"computer_is_broken"
	])
	map_action("computer_is_broken", fix_computer)
	
	kb.add_rule("equipment_failure", [
		"projector_is_off"
	])
	map_action("projector_is_off", turn_projector_on)

func update_state():
	if busy:
		return
		
	# Check if we are teaching
	if kb.has_fact("is_teaching"):
		return
		
	# Check if we can teach
	var query = kb.query_goal("can_teach")
	if query.achieved:
		if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), "is teaching")
		kb.add_fact("is_teaching")
		kb.add_fact("is_happy")
		anger_level = max(0, anger_level - 1)  # Gradually become less angry when teaching
	else:
		if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), "cant teach, missing", query.missing_conditions)
		kb.remove_fact("is_teaching")
		kb.remove_fact("is_happy")
		make_decision(query.missing_conditions)
	
	# Check for disruption
	var disruption_query = kb.query_goal("is_disrupted")
	if disruption_query.achieved:
		anger_level = min(anger_level + 1, 3)
		kb.remove_fact("is_teaching")
		kb.remove_fact("is_happy")
		update_emotional_state()

func update_emotional_state():
	# Reset all emotional states first
	kb.remove_fact("is_angry")
	kb.remove_fact("is_really_angry")
	kb.remove_fact("is_totally_angry")
	
	# Set appropriate emotional state based on anger level
	match anger_level:
		1: 
			kb.add_fact("is_angry")
		2: 
			kb.add_fact("is_really_angry")
			start_yelling()
		3: 
			kb.add_fact("is_totally_angry")
			storm_out()
			
func make_decision(conditions: Array):
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), "making decision")
	busy = true
	for condition in conditions:
		await run_action(condition)
	busy = false
	
func move_to_position():
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.seek_affordance_format(Affordance.Type.CAN_PRESENT))
	var nodes = Affordance.get_affordance_list(get_tree(), Affordance.Type.CAN_PRESENT)
	if nodes.is_empty():
		return # cannot reach position
	
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.found_affordance_format())
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), "moving to position")
	var position = nodes[0].parent_object.global_position
	if await agent_actuator.move_to(Vector2(position.x, position.z)):
		kb.add_fact("in_position")
		if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), "in position")
	
func turn_projector_on():
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.seek_affordance_format(Affordance.Type.PROJECTOR_ON))
	var nodes = Affordance.get_affordance_list(get_tree(), Affordance.Type.PROJECTOR_ON)
	if nodes.is_empty():
		return # cannot reach position
	
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), LogManager.found_affordance_format())
	if show_thoughts: LogManager.add_message(LogManager.id_format("Teacher"), "turning projector on")
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
