extends CanvasLayer

@export var redirect_to_console = false
@onready var scroll = $ScrollContainer
@onready var vbox = $ScrollContainer/VBoxContainer
@onready var scrollbar = scroll.get_v_scroll_bar()

func _ready():
	# Connect to ChatLogManager singleton instance
	LogManager.message_added.connect(_on_message_added)
	
	# Connect to scroll update
	scrollbar.changed.connect(_on_scroll_changed)
	
	# Load existing messages
	for message in LogManager.get_messages():
		_add_message_label(message)

func _on_message_added(text: String):
	if redirect_to_console:
		print(text)
		return
		
	_add_message_label(text)
	
	# Remove old messages if we have too many children
	while vbox.get_child_count() > LogManager.MAX_MESSAGES:
		var first_child = vbox.get_child(0)
		vbox.remove_child(first_child)
		first_child.queue_free()

func _add_message_label(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(label)
	
func _on_scroll_changed():
	scroll.scroll_vertical = scrollbar.max_value
