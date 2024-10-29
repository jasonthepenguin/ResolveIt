class_name WorldState extends Node

var __state: Dictionary = {}

func _init():
	__state = {
		"projector_on" : false,
	}

func set_state(key: String, new_state):
	__state[key] = new_state
	
func get_state(key: String):
	return __state.get(key, 0)
	
static func find(tree: SceneTree) -> WorldState:
	var world_state = tree.get_current_scene().get_node("WorldState")
	if world_state == null:
		print("World state not found at root")
	return world_state
