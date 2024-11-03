# re-work of Will Hallings EmojiManager.gd

class_name EmojiManager extends Sprite3D

## Emoji Textures
var neutral_Emoji = load("res://Neutral.png")
var happy_Emoji = load("res://Happy.png")
var angry_Emoji = load("res://Angry.png")
var sad_Emoji = load("res://Sad.png")

## Emotion states
enum State {
	NEUTRAL,
	HAPPY,
	ANGRY,
	SAD
}

## Mapping Emotions to Textures
var emotion_textures = {
	State.NEUTRAL: neutral_Emoji,
	State.HAPPY: happy_Emoji,
	State.ANGRY: angry_Emoji,
	State.SAD: sad_Emoji
}
	
func display_emotion(state: State):
	self.texture = emotion_textures[state]
