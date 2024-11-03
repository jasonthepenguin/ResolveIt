extends Label


@onready var other_node = get_node("../../CharacterBody3D")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = "Number of Custom Rigid Bodies: %d" % other_node.shared_body_count
	
	
