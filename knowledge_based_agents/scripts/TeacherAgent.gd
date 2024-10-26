# TeacherAgent.gd
class_name TeacherAgent
extends Node

var kb: AgentKnowledgeBase
var anger_level = 0  # 0: normal, 1: angry, 2: really angry, 3: totally angry

func _ready():
	kb = AgentKnowledgeBase.new()
	_seed_knowledge()
	add_child(kb)
	#test()

func update_state():
	# Check if we can teach
	var teaching_query = kb.query_goal("can_teach")
	if teaching_query.achieved:
		kb.add_fact("is_teaching")
		kb.add_fact("is_happy")
	else:
		kb.remove_fact("is_teaching")
		kb.remove_fact("is_happy")
		print("Cannot teach yet. Need: ", teaching_query.missing_conditions)
	
	# Check for disruption
	var disruption_query = kb.query_goal("is_disrupted")
	if disruption_query.achieved:
		anger_level = min(anger_level + 1, 3)
		kb.remove_fact("is_teaching")
		kb.remove_fact("is_happy")
		update_emotional_state()

func update_emotional_state():
	# Reset all emotional states first
	kb.remove_fact("is_angry")
	kb.remove_fact("is_really_angry")
	kb.remove_fact("is_totally_angry")
	
	# Set appropriate emotional state based on anger level
	match anger_level:
		1: 
			kb.add_fact("is_angry")
		2: 
			kb.add_fact("is_really_angry")
			start_yelling()
		3: 
			kb.add_fact("is_totally_angry")
			storm_out()

func storm_out():
	print("Teacher storms out of the room!")
	kb.remove_fact("is_in_classroom")

func start_yelling():
	print("Teacher starts yelling!")

func teach():
	print("Teacher is teaching happily!")
	
func _seed_knowledge():
	# Teaching requirements
	kb.add_rule("can_teach", [
		"is_in_classroom",
		"has_presentation_setup"
	])
	
	kb.add_rule("has_presentation_setup", [
		"computer_is_on",
		"projector_is_on"
	])
	
	# Disruption conditions
	kb.add_rule("is_disrupted", [
		"is_teaching",
		"equipment_failure"
	])
	
	kb.add_rule("equipment_failure", [
		"computer_is_broken"
	])
	
	kb.add_rule("equipment_failure", [
		"computer_is_off"
	])
	
	kb.add_rule("equipment_failure", [
		"projector_is_off"
	])

# Example usage
func test():
	# goal to query
	var query = "can_teach"
	# print query info
	var info = false
	# print result info
	var r_info = true
	
	# No facts - should show all missing conditions
	var result = kb.query_goal(query, info)
	if (r_info):
		print("Query:", query)
		print("Achieved: ", result.achieved)
		print("Missing:", result.missing_conditions)  # ["is_in_classroom", "computer_is_on", "projector_is_on"]

	# Add some facts
	if (r_info): print("Adding facts is_in_classroom, computer_is_on")
	kb.add_fact("is_in_classroom")
	kb.add_fact("computer_is_on")
	
	result = kb.query_goal(query, info)
	if (r_info):
		print("Query:", query)
		print("Achieved: ", result.achieved)
		print("Missing:", result.missing_conditions)  # ["projector_is_on"]

	# Add final fact
	if (r_info): print("Adding fact projector_is_on")
	kb.add_fact("projector_is_on")
	
	result = kb.query_goal(query, info)
	if (r_info):
		print("Query:", query)
		print("Achieved: ", result.achieved)
		print("Missing:", result.missing_conditions)  # should now be true
