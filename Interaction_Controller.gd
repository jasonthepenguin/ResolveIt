class_name InteractionController
extends Node

@export var detection_radius: float = 3.0
var is_interacting: bool = false


func initialize(radius: float):
	detection_radius = radius


func find_nearest_interactable(current_position: Vector3) -> Node3D:
	var nearest_distance = INF
	var nearest_object = null
	
	
	for object in get_tree().get_nodes_in_group("interactable"):
		var distance = current_position.distance_to(object.global_position)
		
		if distance < detection_radius and distance < nearest_distance:
			nearest_distance = distance
			nearest_object = object
	
	return nearest_object


func handle_angry_interaction(target: Node3D):
	if target.has_node("Affordance"):
		var affordance = target.get_node("Affordance")
	
		if affordance.has_affordance("activate"):
			affordance.trigger_affordance("activate")


func handle_happy_interaction(target: Node3D):
	if target.has_node("Affordance"):
		var affordance = target.get_node("Affordance")
	
		if affordance.has_affordance("activate"):
			affordance.trigger_affordance("activate")
