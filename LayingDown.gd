extends Node3D


@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	play_lie_down_animation()

func play_lie_down_animation():
	animation_player.play("Walking_B")
