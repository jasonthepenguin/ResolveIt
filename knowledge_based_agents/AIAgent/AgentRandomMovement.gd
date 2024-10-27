class_name AgentRandomMovement extends Node

@export var max_stuck_time = 0.5
@export var distance_threshold = 0.001
@export var debug_info: bool = false
@onready var character: CharacterBody3D = get_parent()
@onready var nav_agent: NavigationAgent3D = character.get_nav_agent()
@onready var actuator = character.get_actuator()
var last_location: Vector3
var stuck_time = 0.0

func _ready():
	randomize()

func _physics_process(delta):
	if (nav_agent.is_navigation_finished()):
		actuator.move_to(get_random_position())
	
	var current_location = character.global_transform.origin
	
	if current_location.distance_to(last_location) < distance_threshold:
		stuck_time += delta
		if (stuck_time > max_stuck_time):
			if debug_info: print("Got stuck")
			actuator.move_to(get_random_position())
			stuck_time = 0
			
	last_location = current_location

func get_random_position() -> Vector2:
	return Vector2(randf_range(-10, 10), randf_range(-10, 10))
