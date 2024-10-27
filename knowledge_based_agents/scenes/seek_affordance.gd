extends Node

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()
var period = 1.0
var accumulator: float
var on_route_to_present_location = false
var on_route_to_study_location = false
var at_present_location = false
var at_study_location = false
var location_unreachable = false
var stop = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if stop: return
	
	accumulator += delta
	
	if (accumulator >= period):
		if on_route_to_present_location or on_route_to_study_location:
			if not nav_agent.is_target_reachable():
				print("Could not reach target. Stopping.")
				stop = true
			if (nav_agent.is_navigation_finished()):
				if (on_route_to_present_location):
					on_route_to_present_location = false
					at_present_location = true
					print("Arrived at present location")
				elif (on_route_to_study_location):
					on_route_to_study_location = false
					at_study_location = true
					print("Arrived at study location")
		else:
			switch_location()
		
		accumulator = 0
	
func switch_location():
	if (at_present_location and not at_study_location):
		at_present_location = false
		on_route_to_study_location = true
		go_to_location(Affordance.Type.CAN_STUDY)
		print("Moving to study location")
	elif (at_study_location and not at_present_location):
		at_study_location = false
		on_route_to_present_location = true
		go_to_location(Affordance.Type.CAN_PRESENT)
		print("Moving to present location")
	else:
		on_route_to_present_location = true
		go_to_location(Affordance.Type.CAN_PRESENT)
		print("Moving to present location")
		# go to present_location

func go_to_location(affordance_location: Affordance.Type):
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(affordance_location):
			var location = affordance.parent_object.global_transform.origin
			agent_actuator.move_to(Vector2(location.x, location.z))
			break
	
