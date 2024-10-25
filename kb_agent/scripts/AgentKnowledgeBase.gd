class_name AgentKnowledgeBase extends Node

var facts: Array = []
var rules: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _init():
	pass

# Add a new fact to the knowledge base
func add_fact(fact: String) -> void:
	if not facts.has(fact.to_lower()):
		facts.append(fact.to_lower())
		
# Add a rule to the knowledge base
func add_rule(conditions: Array, conclusion: String) -> void:
	rules.append({
		"conditions": conditions,
		"conclusion": conclusion
	})
	
# Query the knowledge base to check if a fact is true
func query(query: String) -> bool:
	query = query.to_lower()
	if facts.has(query):
		return true
	
	var new_facts: bool = true
	while new_facts:
		new_facts = false
		for rule in rules:
			var conditions_met = true
			for condition in rule.conditions:
				if not facts.has(condition):
					conditions_met = false
					break
			
			if conditions_met and not facts.has(rule.conclusion):
				facts.append(rule.conclusion)
				new_facts = true
				if rule.conclusion == query:
					return true
	
	return false
				

