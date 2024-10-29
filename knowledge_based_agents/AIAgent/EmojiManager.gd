# re-work of Will Hallings EmojiManager.gd

extends Sprite3D

## Emoji Textures
var neutral_Emoji = load("res://Neutral.png")
var happy_Emoji = load("res://Happy.png")
var angry_Emoji = load("res://Angry.png")
var sad_Emoji = load("res://Sad.png")

## Mapping Emotions to Textures
var emotion_textures = {
	FuzzyEmotionTriangle.Emotion.NEUTRAL: neutral_Emoji,
	FuzzyEmotionTriangle.Emotion.HAPPY: happy_Emoji,
	FuzzyEmotionTriangle.Emotion.ANGRY: angry_Emoji,
	FuzzyEmotionTriangle.Emotion.SAD: sad_Emoji
}
	
func display_emotion(emotion: FuzzyEmotionTriangle.Emotion):
	var selected
	match emotion:
		FuzzyEmotionTriangle.Emotion.NEUTRAL: selected = neutral_Emoji
		FuzzyEmotionTriangle.Emotion.HAPPY: selected = happy_Emoji
		FuzzyEmotionTriangle.Emotion.ANGRY: selected = angry_Emoji
		FuzzyEmotionTriangle.Emotion.SAD: selected = sad_Emoji
	self.texture = selected
