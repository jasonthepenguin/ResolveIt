extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var emoji_controller: Sprite3D = $Sprite3D
@onready var animation_player: AnimationPlayer = $Rogue_Hooded2/AnimationPlayer
@onready var character_model: Node3D = $Rogue_Hooded2

## Movement Variables
var m_NPC_WalkSpeed = 1.5
var m_Location = Vector3()
var last_emotion = null

## Time to pause after collision (in seconds)
var collided = false
var pause_timer = 0.0
var back_away_distance = 3.0
var collision_pause_time = 1.0
var distance_backed_away = 0.0
var back_away_direction = Vector3.ZERO

## Sad State Variables
var is_in_corner: bool = false
var sad_look_angle: float = PI/3
var sad_rotation_speed: float = 0.5  # Slower rotation

## Detection Variables
var is_interacting: bool = false
var current_target: Node3D = null
@export var detection_radius: float = 3.0

## Animation States
enum AnimationState {
	IDLE,
	WALK,
	RUN,
	JUMP,
	INTERACT
}

var current_animation: AnimationState = AnimationState.IDLE
var animation_locked: bool = false

func _ready():
	randomize()
	await get_tree().create_timer(0.1).timeout
	move_to_random_location()
	play_animation(AnimationState.IDLE)


func handle_emotion_change():
	print("Emotion changed to: ", "Angry" if emoji_controller.texture == emoji_controller.angry_Emoji 
		else "Happy" if emoji_controller.texture == emoji_controller.happy_Emoji 
		else "Sad" if emoji_controller.texture == emoji_controller.sad_Emoji 
		else "Neutral")
	
	m_NPC_WalkSpeed = 1.5  # Reset to default speed
	is_in_corner = false
	current_target = null
	is_interacting = false


func play_animation(anim_state: AnimationState):
	if current_animation == anim_state or animation_locked:
		return
		
	current_animation = anim_state
	match anim_state:
		AnimationState.IDLE:
			animation_player.play("Unarmed_Idle")
		AnimationState.WALK:
			animation_player.play("Walking_A")
		AnimationState.RUN:
			animation_player.play("Running")
		AnimationState.JUMP:
			animation_player.play("Jump_Full_Long")
		AnimationState.INTERACT:
			if emoji_controller.texture == emoji_controller.angry_Emoji:
				animation_player.play("PickUp")
			else:
				animation_player.play("Use_Item")
	
	animation_locked = true
	await get_tree().create_timer(1.0).timeout
	animation_locked = false

func update_model_rotation(direction: Vector3):
	if direction != Vector3.ZERO:
		var angle = atan2(direction.x, direction.z)
		character_model.rotation.y = angle


func move_to_random_location():
	m_Location = getRandomLocation()
	agent.set_target_position(m_Location)


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


func handle_angry_interaction():
	if current_target and current_target.has_node("Affordance"):
		var affordance = current_target.get_node("Affordance")
		if affordance.has_affordance("activate"):
			play_animation(AnimationState.INTERACT)
			affordance.trigger_affordance("activate")  # Default red color
			m_NPC_WalkSpeed = 2.5  # Move faster when angry
		
		is_interacting = true
		await get_tree().create_timer(2.0).timeout
		is_interacting = false
		current_target = null


func handle_happy_interaction():
	if current_target and current_target.has_node("Affordance"):
		var affordance = current_target.get_node("Affordance")
		if affordance.has_affordance("activate"):
			play_animation(AnimationState.INTERACT)
			affordance.trigger_affordance("activate", Color.GREEN)
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

func move_to_corner():
	if is_in_corner:
		return
		
	var corners = [
		Vector3(-8.7, 0, 7),    # Back left
		Vector3(2.7, 0, 7),     # Back right
		Vector3(-8.7, 0, 22.5), # Front left
		Vector3(2.7, 0, 22.5)   # Front right
	]
	
	var furthest_corner = corners[0]
	var furthest_dist = 0
	
	for corner in corners:
		var dist = global_position.distance_to(corner)
		if dist > furthest_dist:
			furthest_dist = dist
			furthest_corner = corner
			
	m_NPC_WalkSpeed = 3.0  # Run to corner faster
	agent.set_target_position(furthest_corner)
	await get_tree().create_timer(0.1).timeout
	is_in_corner = true

func rotate_sad():
	if not is_interacting and is_in_corner:
		play_animation(AnimationState.IDLE)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(character_model, "rotation:y", sad_look_angle, sad_rotation_speed)
		await tween.finished
		
		if emoji_controller.texture != emoji_controller.sad_Emoji:
			return
			
		tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(character_model, "rotation:y", -sad_look_angle, sad_rotation_speed)
		await tween.finished
		
		if emoji_controller.texture == emoji_controller.sad_Emoji:
			rotate_sad()

func handle_angry_state():
	if not is_interacting:
		var nearest_interactable = find_nearest_interactable()
		if nearest_interactable:
			var distance = global_position.distance_to(nearest_interactable.global_position)
			if distance <= 1.5:
				current_target = nearest_interactable
				handle_angry_interaction()
			else:
				agent.set_target_position(nearest_interactable.global_position)
				play_animation(AnimationState.RUN)
		else:
			if agent.is_navigation_finished():
				move_to_random_location()
				play_animation(AnimationState.RUN)

func handle_happy_state():
	if not is_interacting:
		var nearest_interactable = find_nearest_interactable()
		if nearest_interactable:
			var distance = global_position.distance_to(nearest_interactable.global_position)
			if distance <= 1.5:
				current_target = nearest_interactable
				handle_happy_interaction()
			else:
				agent.set_target_position(nearest_interactable.global_position)
				play_animation(AnimationState.WALK)
		else:
			if agent.is_navigation_finished():
				move_to_random_location()
				play_animation(AnimationState.WALK)
		
		if not animation_locked:
			play_animation(AnimationState.JUMP)
			await get_tree().create_timer(1.0).timeout

func handle_sad_state():
	move_to_corner()
	rotate_sad()

func handle_neutral_state():
	if not is_interacting and agent.is_navigation_finished():
		move_to_random_location()
		play_animation(AnimationState.WALK)

func updateAI(delta):
	match emoji_controller.texture:
		emoji_controller.angry_Emoji:
			handle_angry_state()
		emoji_controller.happy_Emoji:
			handle_happy_state()
		emoji_controller.sad_Emoji:
			handle_sad_state()
		emoji_controller.neutral_Emoji:
			handle_neutral_state()
	
	var collision = handle_movement(delta)
	if collision:
		handle_collision(collision)
	
	if collided:
		handle_collision_state(delta)

func _physics_process(delta):
	if last_emotion != emoji_controller.texture:
		handle_emotion_change()
		last_emotion = emoji_controller.texture
	
	updateAI(delta)
