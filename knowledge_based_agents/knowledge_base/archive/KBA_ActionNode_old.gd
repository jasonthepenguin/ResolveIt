@tool
class_name KBA_ActionNode extends Resource

@export var action_name: String
@export var action_script: Script:
	set(value):
		action_script = value
		if value:
			loaded_script = load(value.resource_path)
			# Update available functions when script changes
			_update_function_list()
			notify_property_list_changed()
	get:
		return action_script

var loaded_script : Script = null

# Store function name for the inspector
var selected_function_name: String:
	set(value):
		selected_function_name = value if value in available_functions.keys() else ""
		# Update the actual function reference when name changes
		if selected_function_name and selected_function_name in available_functions:
			selected_function = available_functions[selected_function_name]
		else:
			selected_function = Callable()  # Empty Callable instead of null
	get:
		return selected_function_name

# Store the actual function reference
var selected_function: Callable = Callable()

# Dictionary to store both names and function references
var available_functions: Dictionary = {}

# Call the selected function if it exists
func perform(args: Array = []) -> Variant:
	if selected_function.is_valid():
		return selected_function.callv(args)
	return null

func _update_function_list() -> void:
	available_functions.clear()
	if loaded_script:
		# Get all methods from the script
		var script_methods = loaded_script.get_script_method_list()
		var script_instance = loaded_script.new()
		
		for method in script_methods:
			var method_name = method["name"]
			# Store both the name and the function reference
			available_functions[method_name] = Callable(script_instance, method_name)

# Property hint for the function selector
func _get_property_list() -> Array:
	var properties = []
	if !available_functions.is_empty():
		properties.append({
			"name": "selected_function_name",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(available_functions.keys())
		})
	return properties
