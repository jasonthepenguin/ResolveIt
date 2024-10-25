# EmojiController.gd
extends Sprite3D

## Emoji Textures
var neutral_Emoji = load("res://Neutral.png")
var happy_Emoji = load("res://Happy.png")
var angry_Emoji = load("res://Angry.png")
var sad_Emoji = load("res://Sad.png")


var emotionDuration = 0.0  		 ## Monitors time passed since last change
var force_emotion: bool = false  ## Prevents cycling of emotions

@export var cycle_Emotion = 4.0  ## Changes emotions every 4 seconds

func _ready():
	randomize()
	var emotions = [neutral_Emoji, happy_Emoji, angry_Emoji, sad_Emoji]
	self.texture = emotions[randi() % emotions.size()]


func cycleEmotions():
	if force_emotion:
		return

	if self.texture == neutral_Emoji:
		self.texture = happy_Emoji
		
	elif self.texture == happy_Emoji:
		self.texture = angry_Emoji
	
	elif self.texture == angry_Emoji:
		self.texture = sad_Emoji
	
	else:
		self.texture = neutral_Emoji  ## Cycle back to neutral


func setEmotion(emotion):
	self.texture = emotion
	
	force_emotion = true
	
	await get_tree().create_timer(4.0).timeout
	force_emotion = false


func _process(delta):
	if not force_emotion:
		emotionDuration += delta
		
		
	if emotionDuration >= cycle_Emotion:

		cycleEmotions()
		emotionDuration = 0.0  ## Reset the timer
