class_name EmotionController extends Node

signal emotion_changed(emotion: int, intensity: float)

@onready var emoji_manager: Sprite3D = get_parent().get_node("EmojiManager")

var fuzzy_emotions = FuzzyEmotionTriangle.new()
var current_emotion_position = Vector2.ZERO

# Core emotional settings
const EMOTION_LERP_SPEED = 8.0
const STRONG_EMOTION_THRESHOLD = 0.75
const MODERATE_EMOTION_THRESHOLD = 0.4

# Process time configuration
@export var update_interval: float = 0.05
var accumulator: float = 0.0

# Generic emotional influence tracking
var emotional_influences: Dictionary = {}

func _ready():
	add_child(fuzzy_emotions)

func _process(delta):
	accumulator += delta
	if accumulator >= update_interval:
		accumulator = 0.0
		update_emotional_state()

# Add a temporary emotional influence at a given position
func add_influence(id: String, position: Vector2, duration: float = 0.0):
	emotional_influences[id] = {
		"position": position,
		"duration": duration,
		"time_remaining": duration if duration > 0 else 0.0
	}

# Remove a specific emotional influence
func remove_influence(id: String):
	emotional_influences.erase(id)

# Clear all emotional influences
func clear_influences():
	emotional_influences.clear()

func update_emotional_state():
	var target_position = _calculate_target_position()
	_update_emotion_position(target_position, update_interval)

func _calculate_target_position() -> Vector2:
	var target = Vector2.ZERO
	var expired_influences = []
	
	# Process all active influences
	for id in emotional_influences:
		var influence = emotional_influences[id]
		
		# Update duration if temporary
		if influence.duration > 0:
			influence.time_remaining -= update_interval
			if influence.time_remaining <= 0:
				expired_influences.append(id)
				continue
				
		target += influence.position
	
	# Clean up expired influences
	for id in expired_influences:
		emotional_influences.erase(id)
	
	# Normalize if outside bounds
	if target.length() > 1.0:
		target = target.normalized() * 0.95
		
	return target

func _update_emotion_position(target_position: Vector2, delta: float):
	current_emotion_position = current_emotion_position.lerp(
		target_position,
		EMOTION_LERP_SPEED * delta
	)

	var result = fuzzy_emotions.process_emotion(current_emotion_position)
	_update_emoji(result.crisp_emotion)
	
	# Emit emotional state for any intensity above threshold
	for emotion in result.memberships:
		if result.memberships[emotion] > MODERATE_EMOTION_THRESHOLD:
			emotion_changed.emit(emotion, result.memberships[emotion])

func _update_emoji(emotion: FuzzyEmotionTriangle.Emotion):
	emoji_manager.display_emotion(emotion)
