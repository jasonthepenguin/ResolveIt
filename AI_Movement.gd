extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
var m_NPC_WalkSpeed = 1.5
var m_Location = Vector3()

	## Time to pause after collision (in seconds)
var collision_pause_time = 1.0
var pause_timer = 0.0
var collided = false
var back_away_direction = Vector3.ZERO

	## Distance to back away after collision
var back_away_distance = 3.0
var distance_backed_away = 0.0

func _ready():
	randomize()
	move_to_random_location()

		## Debugging: Confirm that the NavigationAgent3D is active
	if agent:
		print("Navigation Agent Ready!")
		
	else:
		print("Navigation Agent Not Found!")

func move_to_random_location():
	m_Location = getRandomLocation()
	agent.set_target_position(m_Location)
	
		## Debugging: Print the target location to confirm
	print("Moving to new target location: ", m_Location)


func getRandomLocation():
	
	var xLoc = randf_range(-8.7, 2.7)
	var zLoc = randf_range(7, 22.5)

	return Vector3(xLoc, 0, zLoc)


func _process(delta):
	
	updateAI(delta)


func updateAI(delta):
	
	if collided:
			## Decrease the timer after a collision
		pause_timer -= delta
		
		if pause_timer <= 0:
				## Move away in the opposite direction after the pause
			var move_vector = back_away_direction * m_NPC_WalkSpeed * delta
			var collision = move_and_collide(move_vector)
			
				## Track how far we have moved away
			distance_backed_away += move_vector.length()
			
				## Check if the agent has backed away far enough
			if distance_backed_away >= back_away_distance or collision:
				
				collided = false
				distance_backed_away = 0.0  # Reset the distance counter
				
				move_to_random_location()  # Move to a new random location after backing away
		return

		## Check if navigation is finished and set new target location
	if agent.is_navigation_finished():
		
		print("Navigation finished, moving to new location!")
		
		move_to_random_location()


		## Get the next path position and calculate the movement direction
	var nextLocation = agent.get_next_path_position()
	var travelDirection = (nextLocation - global_transform.origin).normalized()

		## Debugging: Print current direction and next location
	print("Next location: ", nextLocation)
	print("Travel direction: ", travelDirection)

		## Move the agent and detect collisions
	var collision = move_and_collide(travelDirection * m_NPC_WalkSpeed * delta)
	
	
	if collision:
		print("Collision detected, pausing movement.")
		collided = true
		pause_timer = collision_pause_time

			## Get the opposite direction based on the collision normal to back away
		back_away_direction = -collision.get_normal().normalized()

			## Debugging: Print the back-away direction
		print("Backing away in direction: ", back_away_direction)
