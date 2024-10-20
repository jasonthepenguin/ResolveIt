### TLDR Brief: Move AI within the virtual world using Navigation Mesh
### Author: William Halling

extends Node3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
var m_NPC_WalkSpeed = 1.5
var m_Location = Vector3()


func _ready():
	randomize()
	move_to_random_location()

	# Debugging: Confirm that the NavigationAgent3D is active
	if agent:
		print("Navigation Agent Ready!")
		
		
	else:
		print("Navigation Agent Not Found!")


func move_to_random_location():
	
	m_Location = getRandomLocation()
	agent.set_target_position(m_Location)
	
	# Debugging: Print the target location to confirm
	print("Moving to new target location: ", m_Location)


func getRandomLocation():
	var xLoc = randf_range(-8.7, 2.7)
	var zLoc = randf_range(7, 22.5)
	return Vector3(xLoc, 0, zLoc)


func _process(delta):
	updateAI(delta)


func updateAI(delta):
	# Check if navigation is finished and set new target location
	if agent.is_navigation_finished():
		print("Navigation finished, moving to new location!")
		move_to_random_location()

	# Get the next path position and calculate the movement direction
	var nextLocation = agent.get_next_path_position()
	var travelDirection = (nextLocation - global_transform.origin).normalized()

	# Debugging: Print current direction and next location
	print("Next location: ", nextLocation)
	print("Travel direction: ", travelDirection)

	# Set the velocity based on travel direction
	agent.set_velocity(travelDirection * m_NPC_WalkSpeed)

	# Directly move the AI by updating position
	position += travelDirection * m_NPC_WalkSpeed * delta
