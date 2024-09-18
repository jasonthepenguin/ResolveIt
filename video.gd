extends Control


@export var play_intro = true

var fade = false
var fade_music = false
@export var fade_amount = 0.25 # per second

@export var fade_music_amount = 0.05

@onready var video_player = get_node("VideoStreamPlayer")

@onready var fade_timer = get_node("Timer")
@onready var fade_audio_timer = get_node("Timer2")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	fade_timer.start()
	fade_audio_timer.start()
	
	if play_intro == false:
		
		queue_free()
		
	
	
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	if fade and !(modulate.a <= 0):
		
		modulate.a += -fade_amount * delta
		
	
	
	if fade_music and !(video_player.volume_db <= -80):
		video_player.volume_db += -fade_music_amount
		pass
	
	pass


func _on_timer_timeout():
	queue_free()
	pass # Replace with function body.


func _on_timer_2_timeout():
	
	fade = true
	fade_music = true
	
	pass # Replace with function body.
