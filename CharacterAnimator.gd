extends Node3D

@onready var player = _find_player(self)
@export var idle_key: String
@export var walking_key: String

func play_idle():
	player.play(idle_key, 0.2)
	
func play_walking():
	player.play(walking_key, 0.2)

func _ready():
	var agent: AIAgent = get_parent()
	agent.movement_started.connect(play_walking)
	agent.movement_stopped.connect(play_idle)
	
	_loop_animation(idle_key)
	_loop_animation(walking_key)

func _loop_animation(key: String):
	player.get_animation(key).loop_mode = Animation.LOOP_LINEAR

func _find_player(node: Node) -> AnimationPlayer:
	# Check if current node is an AnimationPlayer
	if node is AnimationPlayer:
		return node
		
	# Recursively search children
	for child in node.get_children():
		var result = _find_player(child)
		if result:
			return result
			
	return null
