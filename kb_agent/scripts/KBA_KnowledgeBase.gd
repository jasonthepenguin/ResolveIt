class_name KBA_KnowledgeBase extends Node

var facts : Dictionary = {} # (Object ID, [facts set])
var rules: Array = [] # {[Conditions], Conclusion}

func _ready():
	_run_test()
	#pass

func add_fact(obj: Node, fact: String):
	var key = obj.get_instance_id()
	
	if key not in facts:
		facts[key] = {}
	
	fact = fact.to_lower()
	facts[key][fact] = null

func remove_fact(obj:Node, fact: String):
	fact = fact.to_lower()
	facts[obj.get_instance_id()].remove(fact)

func add_rule(conditions: Array[String], conclusion: String) -> void:
	var conditions_toLower = []
	for condition in conditions:
		conditions_toLower.append(condition.to_lower())
	
	rules.append({
		"conditions": conditions_toLower,
		"conclusion": conclusion.to_lower()
	})

# checks if a fact is in database, otherwise uses forward-chaining
# to derive other rules that may prove the fact
func query(obj: Node, fact: String) -> bool:
	fact = fact.to_lower()
	var key = obj.get_instance_id()
	var fact_set = facts[key]
	if _has_fact(fact_set, fact):
		return true
	
	var found_new_fact = true
	while found_new_fact:
		found_new_fact = false
		for rule in rules:
			if _all_conditions_met(fact_set, rule.conditions) and not _has_fact(fact_set, rule.conclusion):
				facts[key][rule.conclusion] = null
				found_new_fact = true
				if rule.conclusion == fact:
					return true
	return false

func _has_fact(factset: Dictionary, fact: String) -> bool:
	return fact in factset

func _all_conditions_met(factset: Dictionary, conditions: Array) -> bool:
	for condition in conditions:
		if not _has_fact(factset, condition):
			return false
	return true
	
func _run_test():
	add_rule(["has fur", "says meow"], "is cat")
	add_rule(["is cat"], "is mammal")
	add_rule(["is mammal"], "needs food")
	
	add_fact(self, "has fur")
	print("KBA_KB test incomplete data: ", "pass" if not query(self, "needs food") else "fail")
	
	add_fact(self, "says meow")
	print("KBA_KB test   complete data: ", "pass" if query(self, "needs food") else "fail")
