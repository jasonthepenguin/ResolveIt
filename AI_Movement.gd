extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var emoji_controller: Sprite3D = $Sprite3D

	## Movement Variables
var m_NPC_WalkSpeed = 1.5
var m_Location = Vector3()

	## Time to pause after collision (in seconds)
var collision_pause_time = 1.0
var pause_timer = 0.0
var collided = false
var back_away_direction = Vector3.ZERO
var back_away_distance = 3.0
var distance_backed_away = 0.0


	## Detection Variables
@export var detection_radius: float = 3.0
var current_target: Node3D = null
var is_interacting: bool = false


func _ready():
	randomize()
		
	await get_tree().create_timer(0.1).timeout ## Wait for the NavigationServer to sync
	move_to_random_location()


func move_to_random_location():
	m_Location = getRandomLocation()
	agent.set_target_position(m_Location)
	print("Moving to new target location: ", m_Location)


func getRandomLocation():
	var xLoc = randf_range(-8.7, 2.7)
	var zLoc = randf_range(7, 22.5)
	
	return Vector3(xLoc, 0, zLoc)


func find_nearest_interactable():
	var nearest = INF
	var nearestObj = null
	
	var interactables = get_tree().get_nodes_in_group("interactable")

	for obj in interactables:
		if obj.has_node("Affordance"):

			var distance = global_position.distance_to(obj.global_position)

			if distance < detection_radius and distance < nearest:
				nearest = distance
				nearestObj = obj
	return nearestObj


func handle_interaction():
	if current_target and current_target.has_node("Affordance"):
		var affordance = current_target.get_node("Affordance")
		print("Found cube with affordance: ", current_target.name)  # Debug print
		

		if affordance.has_affordance("activate"):
			print("Triggering activate affordance")
			affordance.trigger_affordance("activate")
		
		is_interacting = true
		await get_tree().create_timer(2.0).timeout
		is_interacting = false
		current_target = null
		
			
func updateAI(delta):
	if not is_interacting:
			## Look for interactable objects first when angry
		if emoji_controller.texture == emoji_controller.angry_Emoji:
			var nearest_interactable = find_nearest_interactable()
			
			if nearest_interactable:
				var distance = global_position.distance_to(nearest_interactable.global_position)
			
				if distance <= 1.5:  ## Close enough to interact
					current_target = nearest_interactable
					handle_interaction()
					
					return
				else:
						## Move towards the interactable
					agent.set_target_position(nearest_interactable.global_position)
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
	
		## Normal movement when not angry or no interactables nearby
	if agent.is_navigation_finished():
		print("Navigation finished, moving to new location!")
		move_to_random_location()
		
	else:
		var nextLocation = agent.get_next_path_position()
		var travelDirection = (nextLocation - global_transform.origin).normalized()
		var collision = move_and_collide(travelDirection * m_NPC_WalkSpeed * delta)
		
		
		if collision:
			print("Collision detected, pausing movement.")
			collided = true
			pause_timer = collision_pause_time
			back_away_direction = -collision.get_normal().normalized()
			
			
func _physics_process(delta):
	updateAI(delta)
