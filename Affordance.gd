# Affordance.gd
extends Node

var affordances: Dictionary = {}


func add_affordance(action: String, callback: Callable) -> void:
	affordances[action] = callback


func has_affordance(action: String) -> bool:

	return affordances.has(action)


func trigger_affordance(action: String) -> void:
	
	if has_affordance(action):
		affordances[action].call()
