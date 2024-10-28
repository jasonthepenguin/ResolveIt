# BaseAgent.gd
class_name BaseAgent extends Node

@export var enabled = true
@export var update_interval = 1.0
@export var show_debug: bool = false
@onready var world_state: WorldState = WorldState.find(get_tree())

var kb: AgentKnowledgeBase
var __action_map: Dictionary = {}
var __accumulator = 0.0

func _init():
	kb = AgentKnowledgeBase.new()
	
func _ready():
	pass

func _process(delta):
	if enabled:
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
	push_error("Function 'update_state' in BaseAgent was not implemented by child class")
	pass
