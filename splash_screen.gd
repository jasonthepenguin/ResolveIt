extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

#func _gui_input(event):
	#if event is InputEventMouseButton:
		#get_tree().quit()
	#


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		#get_tree().quit()
		visible = true

func _on_gui_input(event):
	
	if event is InputEventMouseButton:
		get_tree().quit()
	
	pass # Replace with function body.
