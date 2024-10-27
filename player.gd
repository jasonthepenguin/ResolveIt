extends CharacterBody3D

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var camera = $camholder/Camera3D
var holding_object = false
var looked_object = null
var detect_distance: float = 20.0
var target_layer: int = 1
var throw_force = 7.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.04))
	
	if event.is_action_pressed("use"):
		var look_test = is_looking_at_object()
		
		if holding_object:
			release_object()
		elif look_test:
			# Enhanced debug information
			print("=== Object Detection Debug ===")
			print("Object found: ", look_test)
			print("Object class: ", look_test.get_class())
			print("Is RigidBodyCustom: ", look_test is RigidBodyCustom)
			print("Parent: ", look_test.get_parent().get_class() if look_test.get_parent() else "No parent")
			
			# Try to cast to both RigidBody3D and your custom class
			if look_test is RigidBodyCustom:
				print("Successfully identified as RigidBodyCustom")
				grab_object(look_test)
			elif look_test is RigidBody3D:
				print("Identified as standard RigidBody3D")
				grab_object(look_test)
			else:
				print("Object type not supported for grabbing")
				print("All parent classes:")
				var current = look_test
				while current:
					print("- ", current.get_class())
					current = current.get_parent()

func is_looking_at_object():
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -detect_distance
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collision_mask = target_layer
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result.size() > 0:
		var collider = result["collider"]
		# Enhanced collision detection debug
		print("=== Raycast Debug ===")
		print("Hit something at position: ", result["position"])
		print("Collider: ", collider)
		print("Collision point: ", result["position"])
		print("Collision normal: ", result["normal"])
		return collider
	
	return null

func grab_object(object):
	looked_object = object
	holding_object = true
	
	if looked_object is RigidBodyCustom:
		# Handle RigidBodyCustom specific behavior
		looked_object.set_integrate_forces_enabled(false)  # Disable physics integration
		looked_object.set_gravity_enabled(false)
	else:
		# Regular RigidBody3D behavior
		looked_object.freeze = true
	
func release_object():
	holding_object = false
	if looked_object:
		if looked_object is RigidBodyCustom:
			# Re-enable physics integration for RigidBodyCustom
			looked_object.set_integrate_forces_enabled(true)
			looked_object.set_gravity_enabled(true)
			throw_grabbed_box()
		else:
			# Regular RigidBody3D behavior
			looked_object.freeze = false
			throw_grabbed_box()

func throw_grabbed_box():
	if looked_object:
		var cam_trans = camera.global_transform
		var throw_direction = -cam_trans.basis.z
		
		if looked_object is RigidBodyCustom:
			# Use RigidBodyCustom's methods
			looked_object.set_velocity(Vector3.ZERO)  # Reset velocity
			looked_object.apply_impulse(throw_direction * throw_force)
		else:
			# Regular RigidBody3D
			looked_object.linear_velocity = Vector3.ZERO
			looked_object.angular_velocity = Vector3.ZERO
			looked_object.apply_central_impulse(throw_direction * throw_force)
		
		looked_object = null

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if looked_object and holding_object:
		var cam_trans = camera.global_transform
		if looked_object is RigidBodyCustom:
			var new_transform = looked_object.global_transform
			new_transform.origin = cam_trans.origin + cam_trans.basis.z * -2.0
			new_transform.basis = cam_trans.basis  # This will match rotation to camera
			looked_object.set_trans(new_transform)
			
		else:
			looked_object.global_transform.origin = cam_trans.origin + cam_trans.basis.z * -1.0
	
	move_and_slide()
