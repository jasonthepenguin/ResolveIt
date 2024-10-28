extends CanvasLayer

@export var redirect_to_console = false
@onready var log_container = $LogContainer
@onready var messages_container = $LogContainer/MessagesContainer

func _ready():
	# Connect to ChatLogManager singleton instance
	LogManager.message_added.connect(_on_message_added)
	
	# Load existing messages
	for message in LogManager.get_messages():
		_add_message_label(message)

func _on_message_added(text: String):
	if redirect_to_console:
		print(text)
		return
		
	_add_message_label(text)
	
	# Remove old messages if we have too many children
	while messages_container.get_child_count() > LogManager.MAX_MESSAGES:
		var first_child = messages_container.get_child(0)
		messages_container.remove_child(first_child)
		first_child.queue_free()

func _add_message_label(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	messages_container.add_child(label)
