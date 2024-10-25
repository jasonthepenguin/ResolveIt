extends CharacterBody3D

@onready var navAgent: NavigationAgent3D = $NavigationAgent3D

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

## Affordance Detection Variables
@export var detection_radius: float = 3.0
var current_interaction_target: Node3D = null
var is_interacting: bool = false

enum AIState {
	WANDERING,
	APPROACHING_TARGET,
	INTERACTING,
	BACKING_AWAY
}

var current_state: AIState = AIState.WANDERING

func _ready():
	randomize()
	move_to_random_location()

func move_to_random_location():
	if is_interacting:
		return
	m_Location = getRandomLocation()
	navAgent.set_target_position(m_Location)
	print("Moving to new location: ", m_Location)

func getRandomLocation():
	var xLoc = randf_range(-8.7, 2.7)
	var zLoc = randf_range(7, 22.5)
	return Vector3(xLoc, 0, zLoc)

func findInteractable():
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
	if not current_interaction_target or is_interacting:
		return
		
	is_interacting = true
	
	if current_interaction_target.has_node("Affordance"):
		var affordance = current_interaction_target.get_node("Affordance")
		check_affordances(affordance)
		await get_tree().create_timer(1.0).timeout
	
	is_interacting = false
	current_interaction_target = null
	current_state = AIState.WANDERING

func check_affordances(affordance: Node) -> void:
	var available_actions = ["activate", "jump", "run", "happy", 
						   "shrink", "dance", "duplicate"]
	
	for action in available_actions:
		if affordance.has_affordance(action):
			print("Found %s affordance, triggering..." % action)
			affordance.trigger_affordance(action)
			await get_tree().create_timer(1.5).timeout

func updateAI(delta):
	match current_state:
		AIState.WANDERING:
			if not collided:
				# Look for interactable objects while wandering
				var nearest_interactable = findInteractable()
				if nearest_interactable and not is_interacting:
					current_interaction_target = nearest_interactable
					current_state = AIState.APPROACHING_TARGET
					navAgent.set_target_position(current_interaction_target.global_position)
					return
				
				# Normal wandering behavior
				if navAgent.is_navigation_finished():
					move_to_random_location()
				
				var nextLocation = navAgent.get_next_path_position()
				var travelDirection = (nextLocation - global_transform.origin).normalized()
				var collision = move_and_collide(travelDirection * m_NPC_WalkSpeed * delta)
				
				if collision:
					handle_collision(collision)
			else:
				handle_backing_away(delta)
				
		AIState.APPROACHING_TARGET:
			if not is_instance_valid(current_interaction_target):
				current_state = AIState.WANDERING
				return
			
			var distance = global_position.distance_to(current_interaction_target.global_position)
			if distance <= 1.5:  # Close enough to interact
				current_state = AIState.INTERACTING
				handle_interaction()
			else:
				var nextLocation = navAgent.get_next_path_position()
				var travelDirection = (nextLocation - global_transform.origin).normalized()
				var collision = move_and_collide(travelDirection * m_NPC_WalkSpeed * delta)
				
				if collision:
					handle_collision(collision)
		
		AIState.INTERACTING:
			# Handled by handle_interaction()
			pass
		
		AIState.BACKING_AWAY:
			handle_backing_away(delta)

func handle_collision(collision):
	print("Collision detected, pausing movement.")
	collided = true
	pause_timer = collision_pause_time
	back_away_direction = -collision.get_normal().normalized()
	print("Backing away in direction: ", back_away_direction)

func handle_backing_away(delta):
	pause_timer -= delta
	if pause_timer <= 0:
		var move_vector = back_away_direction * m_NPC_WalkSpeed * delta
		var collision = move_and_collide(move_vector)
		distance_backed_away += move_vector.length()
		if distance_backed_away >= back_away_distance or collision:
			collided = false
			distance_backed_away = 0.0
			current_state = AIState.WANDERING
			move_to_random_location()

func _physics_process(delta):
	updateAI(delta)
