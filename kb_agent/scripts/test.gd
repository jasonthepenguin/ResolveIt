@tool
extends Node

#@export var execute: bool = false:
	#set(value):
		#_on_execute()

func execute() -> void:
	print("Hello, World!")
