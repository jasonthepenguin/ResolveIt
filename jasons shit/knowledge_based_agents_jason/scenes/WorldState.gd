class_name WorldState extends Node

var state: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	state = {
		"projector_on" : false,
	}

func set_state(name: String, new_state):
	state[name] = new_state
