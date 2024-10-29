class_name Affordance extends Node

enum Type {
	CAN_PICKUP		= 1 << 0,  # 1
	CAN_THROW		= 1 << 1,  # 2
	CAN_PRESENT		= 1 << 2,  # 4
	CAN_STUDY		= 1 << 3,
	CAN_PUSH		= 1 << 4,
	CAN_OPEN		= 1 << 5,
	CAN_CLOSE		= 1 << 6,
	CAN_USE			= 1 << 7
}

@export_flags("Pickup", "Throw", "Present", "Study", "Push", "Open", "Close", "Use") 
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
