extends Node

signal message_added(text: String)

const MAX_MESSAGES = 50
var messages = []

# Use a single Array parameter instead of spread operator
func add_message(args1, args2=null, args3=null, args4=null, args5=null) -> void:
	var parts = []
	
	# Add each non-null argument to parts array
	for arg in [args1, args2, args3, args4, args5]:
		if arg != null:
			parts.append(str(arg))
	
	# Join all parts with spaces
	var final_text = " ".join(parts)
	
	_submit_message(final_text)
	
func id_format(id: String) -> String:
	return (id + ":")
	
func seek_affordance_format(type: Affordance.Type) -> String:
	return ("seeking affordance " + Affordance.to_str(type))
	
func found_affordance_format() -> String:
	return ("affordance found")
	
func get_messages() -> Array:
	return messages
	
func _submit_message(message: String) -> void:
	messages.append(message)
	if messages.size() > MAX_MESSAGES:
		messages.pop_front()
	message_added.emit(message)
