class_name BaseAgent extends Node

@export var enabled = true
@export var update_interval = 1.0
@export var show_debug: bool = false

@onready var world_state: WorldState = WorldState.find(get_tree())
@onready var agent_actuator: AgentActuator = get_parent().get_node("NavigationAgent3D")
@onready var emotion_controller = get_parent().get_node("EmotionController")

var kb: AgentKnowledgeBase
var __action_map: Dictionary = {}
var __emotional_action_map: Dictionary = {}
var __accumulator = 0.0
var busy = false

# Dictionary mapping facts to emotional influences
# Format: { "fact_name": {"id": "influence_id", "position": Vector2} }
var _emotional_fact_map: Dictionary = {}

# Dictionary mapping emotions to fact states
# Format: { Emotion.TYPE: { intensity_threshold: float, fact: String }[] }
var _emotion_state_map: Dictionary = {}

func _init():
	kb = AgentKnowledgeBase.new()
	
func _ready():
	if emotion_controller:
		emotion_controller.emotion_changed.connect(_on_emotion_changed)

func _process(delta):
	if enabled:
		__accumulator += delta
		if __accumulator >= update_interval:
			__accumulator = 0.0
			update_state()

func map_action(condition: String, action: Callable):
	__action_map[condition] = action
	
func map_emotional_action(fact: String, action: Callable):
	__emotional_action_map[fact] = action
	
func run_action(condition: String):
	if condition in __action_map:
		await __action_map[condition].call()

func map_emotional_influence(fact: String, influence_id: String, position: Vector2):
	"""Maps a fact to an emotional influence that will be applied when the fact is true."""
	_emotional_fact_map[fact] = {
		"id": influence_id,
		"position": position
	}

func map_emotion_state(emotion: FuzzyEmotionTriangle.Emotion, threshold: float, fact: String):
	"""Maps an emotion and intensity threshold to a fact that should be set when triggered."""
	if not _emotion_state_map.has(emotion):
		_emotion_state_map[emotion] = []
	_emotion_state_map[emotion].append({
		"threshold": threshold,
		"fact": fact
	})

func update_state():
	if busy:
		return
		
	# Update emotional influences based on current state
	_update_emotional_influences()
	
	# Handle specific states and decisions
	_handle_state()
	
	# React to current emotional states
	_handle_emotional_states()

func _update_emotional_influences():
	"""Updates emotional influences based on current facts."""
	if not emotion_controller:
		return
		
	emotion_controller.clear_influences()
	
	# Apply influences for all active facts
	for fact in _emotional_fact_map:
		if kb.has_fact(fact):
			var influence = _emotional_fact_map[fact]
			emotion_controller.add_influence(influence.id, influence.position)

func _on_emotion_changed(emotion: int, intensity: float):
	"""Handles emotion changes by setting appropriate facts based on the emotion state map."""
	# Clear all emotion-related facts first
	if _emotion_state_map.has(emotion):
		for state in _emotion_state_map[emotion]:
			kb.remove_fact(state.fact)
	
	# Set facts for emotions that exceed their threshold
	if _emotion_state_map.has(emotion):
		for state in _emotion_state_map[emotion]:
			if intensity > state.threshold:
				kb.add_fact(state.fact)

func _handle_emotional_states():
	"""Execute actions for active emotional states."""
	for fact in __emotional_action_map:
		if kb.has_fact(fact):
			__emotional_action_map[fact].call()

# Virtual methods to be overridden by child classes
func _initialize_knowledge():
	push_error("Function '_initialize_knowledge' in BaseAgent was not implemented by child class")

func _initialize_emotional_influences():
	push_error("Function '_initialize_emotional_influences' in BaseAgent was not implemented by child class")

func _handle_state():
	push_error("Function '_handle_state' in BaseAgent was not implemented by child class")

func make_decision(conditions: Array):
	if show_debug: 
		LogManager.add_message(LogManager.id_format(name), "making decision")
	busy = true
	for condition in conditions:
		await run_action(condition)
	busy = false

# Common movement and interaction methods
func move_to_affordance(affordance_type: Affordance.Type) -> bool:
	if show_debug:
		LogManager.add_message(LogManager.id_format(name), 
			LogManager.seek_affordance_format(affordance_type))
	
	var nodes = Affordance.get_affordance_list(get_tree(), affordance_type)
	if nodes.is_empty():
		return false
	
	if show_debug:
		LogManager.add_message(LogManager.id_format(name), 
			LogManager.found_affordance_format())
		LogManager.add_message(LogManager.id_format(name), "moving to position")
	
	var position = nodes[0].parent_object.global_position
	return await agent_actuator.move_to(Vector2(position.x, position.z))
