# KnowledgeBase.gd
extends Object

	## Dictionary to hold the facts
var facts = {}


	## Adds or updates a fact in the knowledge base
func add_fact(name: String, value: Variant):

	facts[name] = value



	### Retrieves a fact by name

func get_fact(name: String) -> Variant:

	return facts.get(name, null)


	## Updates a fact if it exists

func update_fact(name: String, value: Variant):

	if name in facts:

		facts[name] = value

	else:
		add_fact(name, value)
