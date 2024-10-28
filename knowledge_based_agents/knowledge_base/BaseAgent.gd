# BaseAgent.gd
class_name BaseAgent extends Node

@export var update_period = 1.0

var kb: AgentKnowledgeBase
var update_accumulator = 0.0
var world_state: WorldState = null

func _init():
	kb = AgentKnowledgeBase.new()
	
func _ready():
	get_world_state()

func _process(delta):
	update_accumulator += delta
	if update_accumulator >= update_period:
		update_accumulator = 0.0
		update_state()

func update_state():
	push_error("Function 'update_state' in BaseAgent was not implemented by child class")
	pass

func get_world_state():
	world_state = get_tree().get_root().get_node("WorldState")
	if world_state == null:
		print("World state not found at root")
