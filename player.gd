extends CharacterBody3D


@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
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
		
		
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
	
	if event.is_action_pressed("use"):
		var look_test = is_looking_at_object()
		
		if holding_object:
			release_object()
		elif look_test:
			if look_test is RigidBody3D:
				grab_object(look_test)

func is_looking_at_object():
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -detect_distance
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collision_mask = target_layer
	
	var result = space_state.intersect_ray(query)
	
	if result.size() > 0:
		return result["collider"] as Node3D
	
	return null


func grab_object(object):
	looked_object = object
	holding_object = true
	#looked_object.get_node("Timer").paused = true
	#looked_object.freeze = true
	#looked_object.freeze = false
	
	# set freeze mode to kinematic so grabbing stuff is ruined by forces of rigid
	looked_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	looked_object.freeze = true
	#------
	
	
	
	


func release_object():
	holding_object = false
	if looked_object:
		#looked_object.get_node("Timer").paused = false
		
		# reset freeze mode when letting go :(
		looked_object.freeze = false
		throw_grabbed_box()
		

func throw_grabbed_box():
	if looked_object:
		var cam_trans = camera.global_transform
		var throw_direction = -cam_trans.basis.z
		looked_object.apply_central_impulse(throw_direction * throw_force)
		looked_object = null

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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
		looked_object.global_transform.origin = (cam_trans.origin + cam_trans.basis.z * -1.0)
	
	move_and_slide()
