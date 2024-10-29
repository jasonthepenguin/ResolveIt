extends Node

@onready var agent_actuator: AgentNavActuator = get_parent().get_actuator()
@onready var throw_actuator: AgentThrowActuator = get_parent().get_node("AgentThrowActuator")
@onready var nav_agent: NavigationAgent3D = get_parent().get_nav_agent()

var period = 0.5
var accumulator: float
var seeking_throwable = false
var at_throwable = false
var location_unreachable = false
var stop = false
var current_target: Node3D = null

func _ready():
	if not throw_actuator:
		push_error("AgentThrowActuator not found! Make sure to add it to the Agent node.")

func _process(delta):
	if stop: return
	
	accumulator += delta
	
	if (accumulator >= period):
		if seeking_throwable:
			if not nav_agent.is_target_reachable():
				print("Cannot reach throwable object. Looking for another...")
				seeking_throwable = false
				current_target = null
			if nav_agent.is_navigation_finished():
				seeking_throwable = false
				at_throwable = true
				print("Found throwable object!")
				if current_target:
					# Try to throw the object
					if throw_actuator.throw_object(current_target):
						# If throw was successful, immediately look for next object
						at_throwable = false
						current_target = null
						seek_throwable()
		else:
			seek_throwable()
		
		accumulator = 0

func seek_throwable():
	seeking_throwable = true
	go_to_throwable()
	print("Seeking something to throw!")

func go_to_throwable():
	var affordances = get_tree().get_nodes_in_group("Affordance")
	for affordance in affordances:
		if affordance.has_affordance(Affordance.Type.CAN_THROW):
			var throwable = affordance.parent_object
			if throwable is RigidBodyCustom or throwable is RigidBody3D:
				current_target = throwable
				var location = throwable.global_transform.origin
				agent_actuator.move_to(Vector2(location.x, location.z))
				break
