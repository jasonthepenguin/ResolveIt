class_name AgentBaseBehaviour

var update_interval = 1.0
var show_debug = false

var world_state: WorldState
var scene_tree: SceneTree
var actuator: AgentActuator
var emoji_manager: EmojiManager
var perception: AgentPerception

var kb: AgentKnowledgeBase
var __action_map: Dictionary = {}
var __accumulator = 0.0
var busy = false
var agent_name = "unknown" # to be specified by base

func _init():
	kb = AgentKnowledgeBase.new()
	
func _ready():
	if not perception:
		push_error("AgentBaseBehaviour requires valid AgentPerception reference!")
		
	perception.collision_detected.connect(_on_collision_detected)

func _process(delta):
	__accumulator += delta
	if __accumulator >= update_interval:
		__accumulator = 0.0
		update_state()

func map_action(condition: String, action: Callable):
	__action_map[condition] = action
	
func run_action(condition: String):
	if condition in __action_map:
		await __action_map[condition].call()

func update_state():
	if busy:
		return
	
	# Handle specific states and decisions
	_handle_state()

func _on_collision_detected(object: Node3D, point: Vector3, normal: Vector3):
	"""Handle collision events from AgentPerception"""
	pass

func make_decision(conditions: Array):
	if show_debug: 
		LogManager.add_message(LogManager.id_format(agent_name), "making decision")
	busy = true
	for condition in conditions:
		await run_action(condition)
	busy = false

# Common affordance helper methods that use perception
func scan_for_affordance(affordance_type: Affordance.Type) -> Dictionary:
	"""Scans for nearest affordance using perception system."""
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), 
			LogManager.seek_affordance_format(affordance_type))
			
	var result = perception.scan_for_nearest_affordance(affordance_type)
	
	if result.found and show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), 
			LogManager.found_affordance_format())
			
	return result

func move_to_affordance(affordance_type: Affordance.Type) -> bool:
	"""Attempts to move to nearest affordance of given type."""
	var scan_result = scan_for_affordance(affordance_type)
	if not scan_result.found:
		return false
		
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "moving to position")
		
	var position = scan_result.affordance.parent_object.global_position
	return await actuator.move_to(Vector2(position.x, position.z))

# Virtual methods to be overridden by child classes
func _initialize_knowledge():
	push_error("Function '_initialize_knowledge' in AgentBaseBehaviour was not implemented by child class")

func _handle_state():
	push_error("Function '_handle_state' in AgentBaseBehaviour was not implemented by child class")
