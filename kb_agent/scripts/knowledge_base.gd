class_name AgentKnowledgeBase extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _init():
	self.facts = []
	self.rules = []

# Add a new fact to the knowledge base
func add_fact(fact: String):
	fact = fact.to_lower()
	if fact not in self.facts:
		self.facts.append(fact)
		
# Add a rule to the knowledge base
func add_rule(condition: Array, conclusion: String):
	self.rules.append([condition, conclusion])
	
# Query the knowledge base to check if a fact is true
func query(query: String) -> bool:
	query = query.to_lower()
	if query in self.facts:
		return true
	
	# Attempt to derive new facts using rules
	var new_facts = true
	while new_facts:
		new_facts = false
		for rule in self.rules:
			var conditions = rule[0]
			var conclusion = rule[1]
			var all_conditions_met = true
			for condition in conditions:
				if condition not in self.facts:
					all_conditions_met = false
					break
			if all_conditions_met and conclusion not in self.facts:
				self.facts.append(conclusion)
				new_facts = true
				if conclusion == query:
					return true
	return false
				
	
