extends Sprite3D
## Emoji Manager.gd
## Enum for Emotions
enum Emotions {
	NEUTRAL,
	HAPPY,
	ANGRY,
	SAD
}

## Emoji Textures
var neutral_Emoji = load("res://Neutral.png")
var happy_Emoji = load("res://Happy.png")
var angry_Emoji = load("res://Angry.png")
var sad_Emoji = load("res://Sad.png")

## Mapping Emotions to Textures
var emotion_textures = {
	Emotions.NEUTRAL: neutral_Emoji,
	Emotions.HAPPY: happy_Emoji,
	Emotions.ANGRY: angry_Emoji,
	Emotions.SAD: sad_Emoji
}

var current_emotion = Emotions.NEUTRAL

var emotionDuration = 0.0         ## Monitors time passed since last change
var force_emotion: bool = false   ## Prevents cycling of emotions

# Custom durations for each emotion (in seconds)
var emotion_durations = {
	Emotions.NEUTRAL: 6.0,
	Emotions.HAPPY: 10.0,
	Emotions.ANGRY: 7.0,
	Emotions.SAD: 10.0
}

func _ready():
	randomize()
	var emotions = [Emotions.NEUTRAL, Emotions.HAPPY, Emotions.ANGRY, Emotions.SAD]
	current_emotion = emotions[randi() % emotions.size()]
	update_texture()
	emotionDuration = 0.0


func update_texture():
	self.texture = emotion_textures[current_emotion]


func cycleEmotions():
	if force_emotion:
		return

	match current_emotion:
		Emotions.NEUTRAL:
			current_emotion = Emotions.HAPPY
		Emotions.HAPPY:
			current_emotion = Emotions.ANGRY
		Emotions.ANGRY:
			current_emotion = Emotions.SAD
		Emotions.SAD:
			current_emotion = Emotions.NEUTRAL
		_:
			current_emotion = Emotions.NEUTRAL  # Default to neutral

	update_texture()
	emotionDuration = 0.0  ## Reset the timer


func setEmotion(emotion):
	current_emotion = emotion
	update_texture()
	force_emotion = true
	emotionDuration = 0.0  ## Reset the timer

	await get_tree().create_timer(4.0).timeout
	force_emotion = false


func _process(delta):
	if not force_emotion:
		emotionDuration += delta

	var current_duration = emotion_durations.get(current_emotion, 4.0)
	if emotionDuration >= current_duration:
		cycleEmotions()
