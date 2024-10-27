# StudentAgent.gd
class_name StudentAgent extends BaseAgent

var sadness_level = 0  # 0: normal, 1: sad, 2: really sad, 3: leaving

func _init():
	super()
	_seed_knowledge()

func _ready():
	test("can_study", 0, 1)

func update_state():
	# Check if we can study
	var study_query = kb.query_goal("can_study")
	if study_query.achieved:
		kb.add_fact("is_studying")
		kb.add_fact("is_happy")
		sadness_level = max(0, sadness_level - 1)  # Gradually become less sad when studying
	else:
		kb.remove_fact("is_studying")
		kb.remove_fact("is_happy")
		sadness_level = min(sadness_level + 1, 3)
		print("Cannot study yet. Need: ", study_query.missing_conditions)
		update_emotional_state()

func update_emotional_state():
	# Reset all emotional states first
	kb.remove_fact("is_sad")
	kb.remove_fact("is_crying")
	kb.remove_fact("has_left_room")
	
	# Set appropriate emotional state based on sadness level
	match sadness_level:
		1:
			kb.add_fact("is_sad")
		2:
			kb.add_fact("is_crying")
			start_crying()
		3:
			kb.add_fact("has_left_room")
			leave_room()

func start_crying():
	print("Student starts crying!")

func leave_room():
	print("Student leaves the room!")
	kb.remove_fact("is_in_classroom")

func study():
	print("Student is studying happily!")

func _seed_knowledge():
	# Study requirements
	kb.add_rule("can_study", [
		"is_in_study_location",
		"computer_is_on",
		"teacher_is_teaching"
	])
	
	# Study location can be classroom
	kb.add_rule("is_in_study_location", [
		"is_in_classroom"
	])
	
	# Teacher teaching requirement
	kb.add_rule("teacher_is_teaching", [
		"teacher_has_presentation",
		"teacher_is_present"
	])
	
	kb.add_rule("teacher_has_presentation", [
		"computer_is_on",
		"projector_is_on"
	])

# Example usage
func test(query: String, q_info: bool, r_info: bool):
	# No facts - should show all missing conditions
	var result = kb.query_goal(query, q_info)
	if (r_info):
		print("Query:", query)
		print("Achieved: ", result.achieved)
		print("Missing:", result.missing_conditions)

	# Add some initial facts
	if (r_info): print("Adding facts is_in_classroom, computer_is_on")
	kb.add_fact("is_in_classroom")
	kb.add_fact("computer_is_on")
	kb.add_fact("teacher_is_present")
	
	result = kb.query_goal(query, q_info)
	if (r_info):
		print("Query:", query)
		print("Achieved: ", result.achieved)
		print("Missing:", result.missing_conditions)

	# Add remaining facts
	if (r_info): print("Adding fact projector_is_on")
	kb.add_fact("projector_is_on")
	
	result = kb.query_goal(query, q_info)
	if (r_info):
		print("Query:", query)
		print("Achieved: ", result.achieved)
		print("Missing:", result.missing_conditions)
