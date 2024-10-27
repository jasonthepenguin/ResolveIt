extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var emoji_controller: Sprite3D = $Sprite3D
@onready var animation_player: AnimationPlayer = $Rogue_Hooded2/AnimationPlayer
@onready var character_model: Node3D = $Rogue_Hooded2

	## Movement Variables
var m_NPC_WalkSpeed = 1.5
var m_Location = Vector3()


	## Time to pause after collision (in seconds)
var collided = false
var pause_timer = 0.0
var back_away_distance = 3.0
var collision_pause_time = 1.0
var distance_backed_away = 0.0
var back_away_direction = Vector3.ZERO


	## Detection Variables
@export var detection_radius: float = 3.0
var current_target: Node3D = null
var is_interacting: bool = false


	## Add animation states
enum AnimationState {
	IDLE,
	WALK,
	INTERACT
}

var current_animation: AnimationState = AnimationState.IDLE


func _ready():
	print("Checking animations...")
	if animation_player:
		var animations = animation_player.get_animation_list()
		
		for anim in animations:
			print("- ", anim)
	
	randomize()
	await get_tree().create_timer(0.1).timeout
	move_to_random_location()
	play_animation(AnimationState.IDLE)  # Start with idle animation
	

func play_animation(anim_state: AnimationState):
	if current_animation == anim_state:
		return
		
	current_animation = anim_state
	match anim_state:
		AnimationState.IDLE:
			animation_player.play("Unarmed_Idle")
		AnimationState.WALK:
			animation_player.play("Walking_A")
		AnimationState.INTERACT:
			if emoji_controller.texture == emoji_controller.angry_Emoji:
				animation_player.play("PickUp")
			else:
				animation_player.play("Use_Item")


func update_model_rotation(direction: Vector3):
	if direction != Vector3.ZERO:
		var angle = atan2(direction.x, direction.z)
		character_model.rotation.y = angle



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
			print("AI Emotion: ", "Angry" if emoji_controller.texture == emoji_controller.angry_Emoji else "Happy/Neutral")
			play_animation(AnimationState.INTERACT)
			affordance.trigger_affordance("activate")
		
		is_interacting = true
		await get_tree().create_timer(2.0).timeout
		is_interacting = false
		current_target = null
	
		
func handle_movement(delta):
	var nextLocation = agent.get_next_path_position()
	var travelDirection = (nextLocation - global_transform.origin).normalized()
	
	update_model_rotation(travelDirection)
	play_animation(AnimationState.WALK)
	
	var collision = move_and_collide(travelDirection * m_NPC_WalkSpeed * delta)
	return collision


func handle_collision(collision):
	print("Collision detected, pausing")
	collided = true
	pause_timer = collision_pause_time
	back_away_direction = -collision.get_normal().normalized()
	play_animation(AnimationState.IDLE)


func handle_collision_state(delta):
	pause_timer -= delta
	if pause_timer <= 0:
		var move_vector = back_away_direction * m_NPC_WalkSpeed * delta
		var collision = move_and_collide(move_vector)
		distance_backed_away += move_vector.length()
		
		if distance_backed_away >= back_away_distance or collision:
			collided = false
			distance_backed_away = 0.0
			move_to_random_location()


func updateAI(delta):
	if not is_interacting:
		if emoji_controller.texture == emoji_controller.angry_Emoji:
			print("AI is Angry - Looking for objects to interact with")
			# When angry, look for objects to interact with
			var nearest_interactable = find_nearest_interactable()
			if nearest_interactable:
				var distance = global_position.distance_to(nearest_interactable.global_position)
				if distance <= 1.5:
					current_target = nearest_interactable
					handle_angry_interaction()
				else:
					agent.set_target_position(nearest_interactable.global_position)
			else:
				if agent.is_navigation_finished():
					print("Angry AI - No interactable nearby, moving to new location!")
					move_to_random_location()
			var collision = handle_movement(delta)
			if collision:
				handle_collision(collision)

		elif emoji_controller.texture == emoji_controller.happy_Emoji:
			print("AI is Happy - Looking to make things green!")
			# When happy, look for objects to turn green
			var nearest_interactable = find_nearest_interactable()
			if nearest_interactable:
				var distance = global_position.distance_to(nearest_interactable.global_position)
				if distance <= 1.5:
					current_target = nearest_interactable
					handle_happy_interaction()  # Turn object green
			
			# Casual roaming
			if agent.is_navigation_finished():
				print("Happy AI - Casually moving to new location")
				move_to_random_location()
			var collision = handle_movement(delta)
			if collision:
				handle_collision(collision)

		elif emoji_controller.texture == emoji_controller.sad_Emoji:
			print("AI is Sad - Running to corner")
			# When sad, run to nearest corner and look around
			move_to_corner()
			rotate_sad()
			
		elif emoji_controller.texture == emoji_controller.neutral_Emoji:
			print("AI is Neutral - Walking around")
			# When neutral, just walk around
			if agent.is_navigation_finished():
				print("Navigation finished, moving to new location!")
				move_to_random_location()
			var collision = handle_movement(delta)
			if collision:
				handle_collision(collision)
	
	if collided:
		handle_collision_state(delta)

# Add these new functions for handling different emotional interactions
func handle_angry_interaction():
	if current_target and current_target.has_node("Affordance"):
		var affordance = current_target.get_node("Affordance")
		if affordance.has_affordance("activate"):
			print("Angry - turning object red")
			play_animation(AnimationState.INTERACT)
			affordance.trigger_affordance("activate")  # Default red color
		
		is_interacting = true
		await get_tree().create_timer(2.0).timeout
		is_interacting = false
		current_target = null


func handle_happy_interaction():
	if current_target and current_target.has_node("Affordance"):
		var affordance = current_target.get_node("Affordance")
		if affordance.has_affordance("activate"):
			print("Happy - turning object green")
			play_animation(AnimationState.INTERACT)
		is_interacting = true
		await get_tree().create_timer(2.0).timeout
		is_interacting = false
		current_target = null
		

func move_to_corner():
	# Find nearest corner based on your room dimensions
	var corners = [
		Vector3(-8.7, 0, 7),    # Back left
		Vector3(2.7, 0, 7),     # Back right
		Vector3(-8.7, 0, 22.5), # Front left
		Vector3(2.7, 0, 22.5)   # Front right
	]
	
	var nearest_corner = corners[0]
	var nearest_dist = global_position.distance_to(corners[0])
	
	for corner in corners:
		var dist = global_position.distance_to(corner)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_corner = corner
	
	agent.set_target_position(nearest_corner)

func rotate_sad():
	if not is_interacting:
		# Create a tween for smooth rotation
		var tween = create_tween()
		tween.tween_property(character_model, "rotation:y", PI/4, 1.0)  # Look right
		await tween.finished
		tween = create_tween()
		tween.tween_property(character_model, "rotation:y", -PI/4, 1.0)  # Look left
		await tween.finished
		
		# Repeat the rotation if still sad
		if emoji_controller.texture == emoji_controller.sad_Emoji:
			rotate_sad()
			
func _physics_process(delta):
	updateAI(delta)
