extends Node

func _ready():
	# Get the parent RigidBodyCustom
	var rigid_body = get_parent()
	if not rigid_body is RigidBodyCustom:
		push_warning("RigidBodySetup should be attached to a RigidBodyCustom node")
		return
		
	# Get or create the Affordance node
	var affordance = rigid_body.get_node_or_null("Affordance")
	
	if not affordance:
		affordance = Affordance.new()
		rigid_body.add_child(affordance)
		affordance.name = "Affordance"
		
	# Add the CAN_THROW affordance
	affordance.add_affordance(Affordance.Type.CAN_THROW)
