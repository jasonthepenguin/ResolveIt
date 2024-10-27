# BaseAgent.gd
class_name BaseAgent extends Node

var kb: AgentKnowledgeBase
var update_accumulator = 0.0

func _init():
	kb = AgentKnowledgeBase.new()

func _process(delta):
	update_accumulator += delta
	if update_accumulator >= 1.0:
		update_accumulator = 0.0
		#update_state()

func update_state():
	push_error("Function 'update_state' in BaseAgent was not implemented by child class")
	pass
