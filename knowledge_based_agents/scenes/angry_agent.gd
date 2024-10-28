extends Node

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()
var period = 1.0
var accumulator: float
var target_object = null
var throw_waypoint = null
var is_seeking_object = false
var is_moving_to_waypoint = false
var is_holding = false
var throw_force = 10.0

func _ready():
	add_to_group("AngryAgent")
	find_throw_waypoint()

func _process(delta):
	accumulator += delta
	
	if accumulator >= period:
		accumulator = 0
		
		if not is_seeking_object and not is_holding and not is_moving_to_waypoint:
			find_throwable_object()
		elif is_seeking_object and nav_agent.is_navigation_finished():
			pickup_object()
		elif is_moving_to_waypoint and nav_agent.is_navigation_finished():
			throw_object()

func find_throw_waypoint():
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_THROW):
			var parent = affordance.parent_object
			if parent.name.begins_with("Waypoint"):
				throw_waypoint = parent
				print("Found throw waypoint")
				break

func find_throwable_object():
	if not throw_waypoint:
		print("No throw waypoint found!")
		return
		
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_THROW):
			var parent = affordance.parent_object
			if parent is RigidBodyCustom:
				target_object = parent
				is_seeking_object = true
				var location = target_object.global_transform.origin
				agent_actuator.move_to(Vector2(location.x, location.z))
				print("Found throwable object, moving to pickup")
				break

func pickup_object():
	if target_object and is_seeking_object:
		is_seeking_object = false
		is_holding = true
		print("Picked up object")
		
		# Move to throw waypoint
		is_moving_to_waypoint = true
		var waypoint_pos = throw_waypoint.global_transform.origin
		agent_actuator.move_to(Vector2(waypoint_pos.x, waypoint_pos.z))
		print("Moving to throw position")

func throw_object():
	if target_object and is_holding:
		is_holding = false
		is_moving_to_waypoint = false
		
		# Calculate throw direction from waypoint position
		var throw_direction = (target_object.global_transform.origin - throw_waypoint.global_transform.origin).normalized()
		throw_direction.y = 0.5  # Add some upward arc
		
		# Apply impulse to throw the object
		target_object.apply_impulse(throw_direction * throw_force)
		
		print("Threw object with force: ", throw_force)
		target_object = null
