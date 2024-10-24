# CharacterMovement.gd
extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D

## Movement Variables
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


func move_to_random_location():
	m_Location = getRandomLocation()
	agent.set_target_position(m_Location)
	print("Moving to new target location: ", m_Location)


func getRandomLocation():
	var xLoc = randf_range(-8.7, 2.7)
	var zLoc = randf_range(7, 22.5)
	return Vector3(xLoc, 0, zLoc)



func updateAI(delta):
	if collided:
		pause_timer -= delta
		if pause_timer <= 0:
			var move_vector = back_away_direction * m_NPC_WalkSpeed * delta
			var collision = move_and_collide(move_vector)
			distance_backed_away += move_vector.length()

			if distance_backed_away >= back_away_distance or collision:
				collided = false
				distance_backed_away = 0.0
				move_to_random_location()
		return

	if agent.is_navigation_finished():
		print("Navigation finished, moving to new location!")
		move_to_random_location()

	var nextLocation = agent.get_next_path_position()
	var travelDirection = (nextLocation - global_transform.origin).normalized()
	print("Next location: ", nextLocation)
	print("Travel direction: ", travelDirection)

	var collision = move_and_collide(travelDirection * m_NPC_WalkSpeed * delta)

	if collision:
		print("Collision detected, pausing movement.")
		collided = true
		pause_timer = collision_pause_time
		back_away_direction = -collision.get_normal().normalized()
		print("Backing away in direction: ", back_away_direction)

func _process(delta):
	updateAI(delta)
