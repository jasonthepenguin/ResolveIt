extends CharacterBody3D

# Export variables for setup
@export var target_character: CharacterBody3D
@export var pickup_object: Node3D
@export var movement_speed: float = 5.0
@export var throw_force: float = 5.0
@export var pickup_distance: float = 2.0
@export var throw_distance: float = 5.0
@export var cooldown_time: float = 5.0

# Holding position configuration
@export_group("Holding Position")
@export var hold_distance: float = 1.2
@export var hold_height: float = 0.5
@export var hold_up_tilt: float = 15.0

# State management
enum NPCState { IDLE, WALKING_TO_OBJECT, PICKING_UP, WALKING_TO_TARGET, THROWING, COOLDOWN }
var current_state: NPCState = NPCState.IDLE

# Instance variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var picked_up_object: Node3D = null
var cooldown_timer: Timer
var is_on_cooldown: bool = false

# ========== Utility Functions (Could be moved to a separate class) ==========

static func move_npc_towards(npc: CharacterBody3D, target_pos: Vector3, speed: float) -> void:
	"""
	Moves an NPC towards a target position and handles rotation.
	"""
	var direction = (target_pos - npc.global_position)
	direction.y = 0  # Keep movement on horizontal plane
	
	if direction.length_squared() > 0.01:
		# Set velocity
		npc.velocity.x = direction.normalized().x * speed
		npc.velocity.z = direction.normalized().z * speed
		
		# Handle rotation
		make_npc_face_target(npc, target_pos)
	else:
		npc.velocity.x = 0
		npc.velocity.z = 0

static func make_npc_face_target(npc: CharacterBody3D, target_pos: Vector3, smooth_turn: bool = false, turn_speed: float = 10.0) -> void:
	"""
	Makes the NPC face towards a target position.
	Optionally can do smooth turning.
	"""
	var direction = (target_pos - npc.global_position)
	direction.y = 0  # Keep level
	
	if direction.length_squared() > 0.01:
		var target_transform = npc.global_transform.looking_at(npc.global_position + direction)
		
		if smooth_turn:
			# Smoothly interpolate rotation
			var current_basis = npc.global_transform.basis
			var target_basis = target_transform.basis
			npc.global_transform.basis = current_basis.slerp(target_basis, turn_speed)
		else:
			# Instant rotation
			npc.global_transform = target_transform

static func is_within_distance(from_pos: Vector3, to_pos: Vector3, distance: float) -> bool:
	"""
	Checks if two positions are within a specified distance.
	"""
	var direction = (to_pos - from_pos)
	direction.y = 0  # Check horizontal distance only
	return direction.length() < distance

static func update_held_object(
	npc: CharacterBody3D, 
	held_object: Node3D, 
	hold_config: Dictionary
) -> void:
	"""
	Updates the position and orientation of a held object relative to the NPC.
	hold_config should contain: distance, height, tilt
	"""
	var forward = -npc.global_transform.basis.z
	var hold_position = npc.global_position + (forward * hold_config.distance)
	hold_position.y += hold_config.height
	
	# Create object transform
	var new_transform = held_object.global_transform
	new_transform.origin = hold_position
	
	# Create rotation to tilt the object
	var tilt_rotation = Transform3D()
	tilt_rotation = tilt_rotation.rotated(Vector3.RIGHT, deg_to_rad(hold_config.tilt))
	new_transform.basis = npc.global_transform.basis * tilt_rotation.basis
	
	# Update object transform
	held_object.set_trans(new_transform)

static func handle_object_pickup(npc: CharacterBody3D, object: Node3D) -> bool:
	"""
	Handles the physics changes needed when an NPC picks up an object.
	Returns success status.
	"""
	if object.has_method("set_integrate_forces_enabled"):
		object.set_integrate_forces_enabled(false)
		object.set_gravity_enabled(false)
		return true
	return false

static func throw_object(
	npc: CharacterBody3D,
	object: Node3D, 
	target_pos: Vector3, 
	force: float
) -> void:
	"""
	Handles throwing an object at a target position.
	"""
	if !object.has_method("set_integrate_forces_enabled"):
		return
		
	# Re-enable physics
	object.set_integrate_forces_enabled(true)
	object.set_gravity_enabled(true)
	
	# Calculate throw trajectory
	var distance = target_pos.distance_to(object.global_position)
	var height_factor = clamp(distance / 10.0, 0.2, 0.6)
	
	var throw_direction = (target_pos - object.global_position).normalized()
	throw_direction += Vector3(0, height_factor, 0)
	throw_direction = throw_direction.normalized()
	
	# Apply throw force
	object.apply_impulse(throw_direction * force)

# ========== Main Process Functions ==========

func _ready():
	if !target_character:
		push_error("Target character not set!")
	if !pickup_object:
		push_error("Pickup object not set!")
	
	setup_cooldown_timer()

func setup_cooldown_timer():
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	match current_state:
		NPCState.IDLE:
			handle_idle_state()
		
		NPCState.WALKING_TO_OBJECT:
			handle_walking_to_object_state()
		
		NPCState.PICKING_UP:
			handle_pickup_state()
		
		NPCState.WALKING_TO_TARGET:
			handle_walking_to_target_state()
		
		NPCState.THROWING:
			handle_throw_state()
		
		NPCState.COOLDOWN:
			pass # Wait for cooldown
	
	move_and_slide()

# ========== State Handler Functions ==========

func handle_idle_state():
	if !is_on_cooldown and target_character and pickup_object:
		current_state = NPCState.WALKING_TO_OBJECT

func handle_walking_to_object_state():
	if is_within_distance(global_position, pickup_object.global_position, pickup_distance):
		current_state = NPCState.PICKING_UP
	else:
		move_npc_towards(self, pickup_object.global_position, movement_speed)

func handle_pickup_state():
	if handle_object_pickup(self, pickup_object):
		picked_up_object = pickup_object
		current_state = NPCState.WALKING_TO_TARGET

func handle_walking_to_target_state():
	if picked_up_object:
		# Update held object position
		var hold_config = {
			"distance": hold_distance,
			"height": hold_height,
			"tilt": hold_up_tilt
		}
		update_held_object(self, picked_up_object, hold_config)
		
		# Check distance and move towards target
		if is_within_distance(global_position, target_character.global_position, throw_distance):
			current_state = NPCState.THROWING
		else:
			move_npc_towards(self, target_character.global_position, movement_speed)

func handle_throw_state():
	if picked_up_object:
		throw_object(
			self,
			picked_up_object, 
			target_character.global_position, 
			throw_force
		)
		picked_up_object = null
	
	start_cooldown()
	current_state = NPCState.COOLDOWN

# ========== Cooldown Functions ==========

func start_cooldown():
	is_on_cooldown = true
	cooldown_timer.start()

func _on_cooldown_timer_timeout():
	is_on_cooldown = false
	current_state = NPCState.IDLE
