class_name KBA_Environment extends Node

var state: Dictionary = {}

func get_state() -> Dictionary:
	return state
	
func set_state(state: Dictionary):
	self.state = state
