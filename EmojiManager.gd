# EmojiController.gd
extends Sprite3D

## Emoji Textures
var neutral_Emoji = load("res://Neutral.png")
var happy_Emoji = load("res://Happy.png")
var angry_Emoji = load("res://Angry.png")
var sad_Emoji = load("res://Sad.png")

@export var cycle_Emotion = 4.0  ## Changes emotions every 4 seconds
var emotionDuration = 0.0  ## Monitors time passed since last change

func _ready():
	self.texture = neutral_Emoji  ## Start with neutral emoji

func cycleEmotions():
	if self.texture == neutral_Emoji:
		self.texture = happy_Emoji
		
	elif self.texture == happy_Emoji:
		self.texture = angry_Emoji
	
	elif self.texture == angry_Emoji:
		self.texture = sad_Emoji
	
	else:
		self.texture = neutral_Emoji  ## Cycle back to neutral


func _process(delta):
	emotionDuration += delta

	if emotionDuration >= cycle_Emotion:

		cycleEmotions()
		emotionDuration = 0.0  ## Reset the timer
