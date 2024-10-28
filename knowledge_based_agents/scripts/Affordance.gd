class_name Affordance extends Node

enum Type {
	CAN_PICKUP		= 1 << 0,  # 1
	CAN_THROW		= 1 << 1,  # 2
	CAN_PRESENT		= 1 << 2,  # 4
	CAN_STUDY		= 1 << 3,
	CAN_PUSH		= 1 << 4,
	CAN_OPEN		= 1 << 5,
	CAN_CLOSE		= 1 << 6,
	CAN_USE			= 1 << 7,
	PROJECTOR_ON	= 1 << 8
}

@export_flags("Pickup", "Throw", "Present", "Study", "Push", "Open", "Close", "Use", "Projector on") 
var affordances: int = 0

var parent_object = null

func _ready():
	add_to_group("Affordance")
	parent_object = get_parent()

func has_affordance(type: Type) -> bool:
	return affordances & type != 0

func add_affordance(type: Type):
	affordances |= type
	
func remove_affordance(type: Type):
	affordances &= ~type
	
static func get_affordance_list(tree: SceneTree, affordance_type: Affordance.Type) -> Array[Node]:
	var affordance_nodes = tree.get_nodes_in_group("Affordance")
	var nodes: Array[Node] = []
	for node in affordance_nodes:
		if node.has_affordance(affordance_type):
			nodes.append(node)
	return nodes
	
static func to_str(type: Affordance.Type) -> String:
	match type:
		Type.CAN_PICKUP: return "Pickup"
		Type.CAN_THROW: return "Throw"
		Type.CAN_PRESENT: return "Present"
		Type.CAN_STUDY: return "Study"
		Type.CAN_PUSH: return "Push"
		Type.CAN_OPEN: return "Open"
		Type.CAN_CLOSE: return "Close"
		Type.CAN_USE: return "Use"
		Type.PROJECTOR_ON: return "Projector On"
		_: return "Unknown"
