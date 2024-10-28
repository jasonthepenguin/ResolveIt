extends Node

signal message_added(text: String)

const MAX_MESSAGES = 50
var messages = []

# Use a single Array parameter instead of spread operator
func add_message(args: Array) -> void:
	var parts = []
	
	# Convert each argument to string and add to parts
	for arg in args:
		parts.append(str(arg))
	
	# Join all parts with spaces
	var final_text = " ".join(parts)
	
	messages.append(final_text)
	if messages.size() > MAX_MESSAGES:
		messages.pop_front()
	message_added.emit(final_text)
	
func get_messages() -> Array:
	return messages
