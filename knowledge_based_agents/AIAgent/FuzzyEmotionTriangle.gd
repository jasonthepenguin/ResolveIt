# Fuzzy logic emotions "triangle" model
# Concept by Lane
# Assistance from Claude Sonnet 3.5

class_name FuzzyEmotionTriangle extends Node

var show_debug = false

enum Emotion {
	NEUTRAL,
	HAPPY,
	ANGRY,
	SAD
}

# Triangle vertices coordinates (using equilateral triangle)
const HAPPY_POS = Vector2(0.0, -1.0)
const ANGRY_POS = Vector2(0.866, 0.5)
const SAD_POS = Vector2(-0.866, 0.5)
const NEUTRAL_POS = Vector2(0.0, 0.0)

# Adjusted membership parameters for better gradients
const VERTEX_CORE_RADIUS = 0.4     # Increased core zone
const VERTEX_SUPPORT_RADIUS = 1.2   # Increased support zone
const NEUTRAL_CORE_RADIUS = 0.1    # Decreased neutral zone
const NEUTRAL_SUPPORT_RADIUS = 0.3  # Adjusted neutral falloff

# Neutral emotion dampening factor
const NEUTRAL_WEIGHT = 0.5  # Reduce neutral's influence

# Calculate fuzzy membership value using a trapezoidal membership function
func calculate_membership(distance: float, core_radius: float, support_radius: float) -> float:
	if distance <= core_radius:
		return 1.0
	elif distance >= support_radius:
		return 0.0
	else:
		return 1.0 - (distance - core_radius) / (support_radius - core_radius)

# Get fuzzy membership degrees for each emotion
func get_fuzzy_memberships(pos: Vector2) -> Dictionary:
	var distances = {
		Emotion.HAPPY: pos.distance_to(HAPPY_POS),
		Emotion.ANGRY: pos.distance_to(ANGRY_POS),
		Emotion.SAD: pos.distance_to(SAD_POS),
		Emotion.NEUTRAL: pos.distance_to(NEUTRAL_POS)
	}
	
	var memberships = {
		Emotion.HAPPY: calculate_membership(distances[Emotion.HAPPY], VERTEX_CORE_RADIUS, VERTEX_SUPPORT_RADIUS),
		Emotion.ANGRY: calculate_membership(distances[Emotion.ANGRY], VERTEX_CORE_RADIUS, VERTEX_SUPPORT_RADIUS),
		Emotion.SAD: calculate_membership(distances[Emotion.SAD], VERTEX_CORE_RADIUS, VERTEX_SUPPORT_RADIUS),
		Emotion.NEUTRAL: calculate_membership(distances[Emotion.NEUTRAL], NEUTRAL_CORE_RADIUS, NEUTRAL_SUPPORT_RADIUS) * NEUTRAL_WEIGHT
	}
	
	# Print debug information
	if show_debug: 
		LogManager.add_message("Distances: ", distances)
		LogManager.add_message("Raw memberships before normalization: ", memberships)
		
	# Find highest non-neutral membership
	var max_non_neutral = 0.0
	for emotion in memberships:
		if emotion != Emotion.NEUTRAL and memberships[emotion] > max_non_neutral:
			max_non_neutral = memberships[emotion]

	# If we have significant non-neutral membership, reduce neutral's influence further
	if max_non_neutral > 0.3:
		memberships[Emotion.NEUTRAL] *= (1.0 - max_non_neutral)
	
	# Normalize memberships (fuzzy normalization)
	var total = 0.0
	for emotion in memberships:
		total += memberships[emotion]
	
	if total > 0:
		for emotion in memberships:
			memberships[emotion] /= total
			
	return memberships

# Defuzzification: Convert fuzzy memberships to crisp emotion
func defuzzify_emotion(memberships: Dictionary) -> Emotion:
	var max_membership = 0.0
	var crisp_emotion = Emotion.NEUTRAL
	
	for emotion in memberships:
		if memberships[emotion] > max_membership:
			max_membership = memberships[emotion]
			crisp_emotion = emotion
			
	return crisp_emotion

# Fuzzy emotion blending using weighted average
func blend_emotions(memberships: Dictionary) -> Vector2:
	var blended_pos = Vector2.ZERO
	var total_weight = 0.0
	
	for emotion in memberships:
		var pos = get_emotion_position(emotion)
		var weight = memberships[emotion]
		blended_pos += pos * weight
		total_weight += weight
	
	if total_weight > 0:
		blended_pos /= total_weight
		
	return blended_pos

# Get the position for a given emotion
func get_emotion_position(emotion: Emotion) -> Vector2:
	match emotion:
		Emotion.HAPPY: return HAPPY_POS
		Emotion.ANGRY: return ANGRY_POS
		Emotion.SAD: return SAD_POS
		Emotion.NEUTRAL: return NEUTRAL_POS
	return NEUTRAL_POS

# Example usage
func process_emotion(pos: Vector2) -> Dictionary:
	# Get fuzzy memberships
	var memberships = get_fuzzy_memberships(pos)
	
	# Get crisp emotion through defuzzification
	var crisp_emotion = defuzzify_emotion(memberships)
	
	# Get blended position
	var blended_pos = blend_emotions(memberships)
	
	return {
		"memberships": memberships,
		"crisp_emotion": crisp_emotion,
		"blended_position": blended_pos
	}
	
# Check if a point is inside the triangle
func is_point_in_triangle(point: Vector2) -> bool:
	# Using barycentric coordinates to check if point is inside triangle
	var denominator = ((SAD_POS.y - ANGRY_POS.y) * (HAPPY_POS.x - ANGRY_POS.x) + 
					  (ANGRY_POS.x - SAD_POS.x) * (HAPPY_POS.y - ANGRY_POS.y))
	
	var a = ((SAD_POS.y - ANGRY_POS.y) * (point.x - ANGRY_POS.x) + 
			 (ANGRY_POS.x - SAD_POS.x) * (point.y - ANGRY_POS.y)) / denominator
			
	var b = ((ANGRY_POS.y - HAPPY_POS.y) * (point.x - ANGRY_POS.x) + 
			 (HAPPY_POS.x - ANGRY_POS.x) * (point.y - ANGRY_POS.y)) / denominator
			
	var c = 1 - a - b
	
	return a >= 0 && a <= 1 && b >= 0 && b <= 1 && c >= 0 && c <= 1
