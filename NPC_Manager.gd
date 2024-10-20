### TLDR Brief: A Singleton used to Manage mutliple AI within the virtual environment

### Script is made to help manage multiple AI within the virtual world
### Author: William Halling 

extends Node

var registered_AIs = []  ## A list to store all registered AI nodes


	## Register a new AI object (e.g., a new NPC)
func registerAI(newAI):
	
	registered_AIs.append(newAI)


func _process(delta):
	updateAI(delta)


	## Update all registered AIs in the scene
func updateAI(delta):
	
	for ai in registered_AIs:
		
		if ai.has_method("updateAI"):  ## Check if the AI has the method before calling it
			
			ai.updateAI(delta)
