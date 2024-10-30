class_name FocusedStudentBehaviour extends AgentBaseBehaviour

const LEARNING_JOY = Vector2(0, -0.9) 
const CONFUSION_SADNESS = Vector2(-0.6, 0.2)
const DISRUPTION_ANGER = Vector2(0.8, 0.3)

func _init():
	super()
	agent_name = "FocusedStudent"
	_initialize_emotional_influences()
	update_interval = 1.0
	
	
func _initialize_emotional_influences():
	map_emotional_influence("is_understanding", "learning", LEARNING_JOY)
	map_emotional_influence("is_confused", "confusion", CONFUSION_SADNESS)
	map_emotional_influence("is_disrupted", "disruption",DISRUPTION_ANGER)
	
	
	map_emotion_state(FuzzyEmotionTriangle.Emotion.HAPPY, EmotionController.STRONG_EMOTION_THRESHOLD, "celebrate_achievement")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.SAD, EmotionController.MODERATE_EMOTION_THRESHOLD, "express_confusion")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.ANGRY, EmotionController.MODERATE_EMOTION_THRESHOLD, "show_disruption_anger")
	
	
func celebrate_achievement():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "Yes! I got it right!")
			# Animation Jump and interact


func express_confusion():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "Hmm, I'm not getting this...")
			# Animation: have model looking down while sad emoji displays
		
		
func show_disruption_anger():		
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "Can you please keep it down?")
		# Animation: frustrated gesture (e.g., covering ears)
