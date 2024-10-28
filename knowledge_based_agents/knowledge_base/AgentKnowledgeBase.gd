# AgentKnowledgeBase.gd
class_name AgentKnowledgeBase

var facts = {}
var rules = {}

func add_fact(fact: String):
	facts[fact] = null

func remove_fact(fact: String):
	facts.erase(fact)

func has_fact(fact: String) -> bool:
	return facts.has(fact)

func add_rule(conclusion: String, premises: Array):
	if not rules.has(conclusion):
		rules[conclusion] = []
	rules[conclusion].append(premises)

# Returns both whether the goal is achievable and what conditions are needed
func query_goal(goal: String, info: bool = false, depth: int = 0) -> Dictionary:
	var indent = "  ".repeat(depth)
	if (info): print(indent, "Querying goal: ", goal)

	var result = {
		"achieved": false,
		"missing_conditions": []
	}
	
	# If we already have the fact, goal is achieved
	if has_fact(goal):
		if (info): print(indent, "Goal ", goal, " is already achieved")
		result.achieved = true
		return result

	# If there are no rules for this goal, it needs to be added as a fact
	if not rules.has(goal):
		if (info): print(indent, "No rules found for goal: ", goal, " - needs to be added as fact")
		result.missing_conditions = [goal]
		return result

	if (info): print(indent, "Checking rules for: ", goal)
	var shortest_path_length = -1
	
	# Check each possible rule path to achieve the goal
	for premises in rules[goal]:
		if (info): print(indent, "Checking premises: ", premises)
		var current_path_missing = []
		var all_premises_achieved = true

		for premise in premises:
			if (info): print(indent, "Checking premise: ", premise)
			var premise_result = query_goal(premise, info, depth + 1)

			if not premise_result.achieved:
				if (info): print(indent, "Premise ", premise, " is not achieved")
				all_premises_achieved = false
				# Add all missing conditions from this premise
				current_path_missing += premise_result.missing_conditions
			else:
				if (info): print(indent, "Premise ", premise, " is achieved")

		# If all premises in this path are achieved, the goal is achieved
		if all_premises_achieved:
			result.achieved = true
			result.missing_conditions = []
			if (info): print(indent, "All premises achieved - goal is achieved")
			break
		# Otherwise update missing conditions if this is the first valid path
		# or if this path has fewer requirements
		elif shortest_path_length == -1 or current_path_missing.size() < shortest_path_length:
			shortest_path_length = current_path_missing.size()
			result.missing_conditions = current_path_missing.duplicate()
			if (info): print(indent, "Found better path with missing conditions: ", result.missing_conditions)

	if (info): print(indent, "Final result for ", goal, ": ", result)
	return result

