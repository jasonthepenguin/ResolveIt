class_name SocialStudentBehaviour extends AgentBaseBehaviour

const FRIEND_INTERACTION = Vector2(0, -0.9)     # Strong happiness from social interaction
const REJECTION_SADNESS = Vector2(-0.8, 0.2)    # Primary sadness from being excluded
const PEER_CONFLICT = Vector2(0.7, 0.4)         # Anger with some arousal from conflicts


func _init():
	super()
	agent_name = "SocialStudent"
	_initialize_knowledge()
	_initialize_emotional_influences()
	update_interval = 1.0


func _initialize_knowledge():
		## Social interaction requirements
	kb.add_rule("can_socialize", ["is_in_social_area", "friends_are_present"])


		## Rules for presence in social areas
	kb.add_rule("is_in_social_area", ["is_in_cafeteria"])
	
		## Conflict scenarios	
	kb.add_rule("conflict_arising", ["is_in_argument", "peer_is_annoyed"])

		## Map emotional actions
	map_emotional_action("is_celebrating", express_excitement)
	map_emotional_action("is_sulking", withdraw)
	map_emotional_action("is_confronting", confront_peer)
	map_emotional_action("is_annoyed", show_annoyance)


func _initialize_emotional_influences():
		## Map facts to emotional influences
	map_emotional_influence("is_socializing", "social", FRIEND_INTERACTION)
	map_emotional_influence("is_excluded", "rejection", REJECTION_SADNESS)
	map_emotional_influence("in_argument", "conflict", PEER_CONFLICT)

		## Map emotions to facts
	map_emotion_state(FuzzyEmotionTriangle.Emotion.HAPPY, EmotionController.STRONG_EMOTION_THRESHOLD, "is_celebrating")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.SAD, EmotionController.STRONG_EMOTION_THRESHOLD, "is_sulking")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.ANGRY, EmotionController.STRONG_EMOTION_THRESHOLD, "is_confronting")
	map_emotion_state(FuzzyEmotionTriangle.Emotion.ANGRY, EmotionController.MODERATE_EMOTION_THRESHOLD, "is_annoyed")


func _handle_state():
		## Check if the student can socialize
	var socialize_query = kb.query_goal("can_socialize")
	if socialize_query.achieved:
		kb.add_fact("is_socializing")
		kb.remove_fact("is_excluded")

	else:
		kb.remove_fact("is_socializing")
		kb.add_fact("is_excluded")
		
		# Add appropriate emotional response based on missing social interaction
		if not kb.has_fact("friends_are_present"):
			kb.add_fact("is_sulking")

		if show_debug:
			LogManager.add_message(LogManager.id_format(agent_name), 
				"Can't socialize yet. Missing: ", socialize_query.missing_conditions)

	# Check for conflict scenarios
	var conflict_query = kb.query_goal("conflict_arising")
	if conflict_query.achieved:
		kb.add_fact("in_argument")
		if kb.has_fact("peer_is_annoyed"):
			kb.add_fact("is_confronting")



	## Social student-specific actions
func express_excitement():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "I'm so happy to be with my friends!")
		
			## Notes animation here


func withdraw():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "I feel left out... maybe I’ll just stay quiet.")
			
			## Notes animation to display sadness


func confront_peer():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "Hey, that’s not cool!")
		
	
		## Notes Add animation to show confrontation


func show_annoyance():
	if show_debug:
		LogManager.add_message(LogManager.id_format(agent_name), "Ugh, that's irritating.")
		

	## Notes Add Display subtle annoyance, such as rolling eyes or shaking head
