# EmotionController.gd
class_name EmotionController

signal emotion_changed(emotion: int, intensity: float)

var emoji_manager: Sprite3D
var update_interval: float = 0.05
var emotion_lerp_speed: float = 8.0
var strong_emotion_threshold: float = 0.75
var moderate_emotion_threshold: float = 0.4

var __accumulator: float = 0.0
var __current_emotion_position = Vector2.ZERO
var __fuzzy_emotions: FuzzyEmotionTriangle

# Generic emotional influence tracking
var __emotional_influences: Dictionary = {}

# Core emotional settings
const EMOTION_LERP_SPEED = 8.0
const STRONG_EMOTION_THRESHOLD = 0.75
const MODERATE_EMOTION_THRESHOLD = 0.4

func _init():
	__fuzzy_emotions = FuzzyEmotionTriangle.new()

func _process(delta):
	__accumulator += delta
	if __accumulator >= update_interval:
		__accumulator = 0.0
		update_emotional_state()

# Add a temporary emotional influence at a given position
func add_influence(id: String, position: Vector2, duration: float = 0.0):
	__emotional_influences[id] = {
		"position": position,
		"duration": duration,
		"time_remaining": duration if duration > 0 else 0.0
	}

# Remove a specific emotional influence
func remove_influence(id: String):
	__emotional_influences.erase(id)

# Clear all emotional influences
func clear_influences():
	__emotional_influences.clear()

func update_emotional_state():
	var target_position = _calculate_target_position()
	_update_emotion_position(target_position, update_interval)

func _calculate_target_position() -> Vector2:
	var target = Vector2.ZERO
	var expired_influences = []
	
	# Process all active influences
	for id in __emotional_influences:
		var influence = __emotional_influences[id]
		
		# Update duration if temporary
		if influence.duration > 0:
			influence.time_remaining -= update_interval
			if influence.time_remaining <= 0:
				expired_influences.append(id)
				continue
				
		target += influence.position
	
	# Clean up expired influences
	for id in expired_influences:
		__emotional_influences.erase(id)
	
	# Normalize if outside bounds
	if target.length() > 1.0:
		target = target.normalized() * 0.95
		
	return target

func _update_emotion_position(target_position: Vector2, delta: float):
	__current_emotion_position = __current_emotion_position.lerp(
		target_position,
		EMOTION_LERP_SPEED * delta
	)

	var result = __fuzzy_emotions.process_emotion(__current_emotion_position)
	_update_emoji(result.crisp_emotion)
	
	# Emit emotional state for any intensity above threshold
	for emotion in result.memberships:
		if result.memberships[emotion] > MODERATE_EMOTION_THRESHOLD:
			emotion_changed.emit(emotion, result.memberships[emotion])

func _update_emoji(emotion: FuzzyEmotionTriangle.Emotion):
	emoji_manager.display_emotion(emotion)
