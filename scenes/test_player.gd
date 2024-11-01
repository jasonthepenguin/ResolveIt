extends CharacterBody3D

@export var FLY_SPEED = 10.0
@export var ACCELERATION = 5.0
@export var shared_body_count: int = 0
@onready var camera = $camholder/Camera3D
var holding_object = false
var looked_object = null
var detect_distance: float = 20.0
var target_layer: int = 2
var throw_force = 7.0

# Add vertical movement controls
var vertical_velocity = 0.0
var direction = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Disable collision detection since we're noclipping
	set_collision_layer(0)
	set_collision_mask(0)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.04))
		# Add vertical camera rotation
		camera.rotate_x(deg_to_rad(event.relative.y * -0.04))
		# Clamp the camera rotation to prevent over-rotation
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event.is_action_pressed("use"):
		spawn_rigid_body()

func spawn_rigid_body():
	var physics_handler = get_parent().get_node("PhysicsHandler")
	
	shared_body_count = shared_body_count + 1
	
	var rigid_body = RigidBodyCustom.new()
	rigid_body.mass = 1.0
	rigid_body.restitution = 0.8
	
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	collision_shape.shape = shape
	rigid_body.add_child(collision_shape)
	
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh_instance.mesh = mesh
	rigid_body.add_child(mesh_instance)
	
	var spawn_pos = camera.global_position + (-camera.global_transform.basis.z * 2)
	rigid_body.position = spawn_pos
	
	physics_handler.add_child(rigid_body)
	
	var impulse_strength = 10.0
	rigid_body.apply_impulse(-camera.global_transform.basis.z * impulse_strength)

func _physics_process(delta):
	direction = Vector3.ZERO
	
	# Get camera's basis vectors
	var camera_basis = camera.global_transform.basis
	
	# Forward/Backward movement in camera's direction
	if Input.is_action_pressed("forward"):
		direction -= camera_basis.z
	if Input.is_action_pressed("back"):
		direction += camera_basis.z
		
	# Left/Right movement relative to camera
	if Input.is_action_pressed("left"):
		direction -= camera_basis.x
	if Input.is_action_pressed("right"):
		direction += camera_basis.x
	
	# Up/Down movement
	if Input.is_action_pressed("ui_accept"): # Space for up
		direction.y += 1
	if Input.is_key_pressed(KEY_SHIFT): # Shift for down
		direction.y -= 1
	
	# Normalize direction to prevent faster diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()
	
	# Smoothly interpolate velocity for better control
	velocity = velocity.lerp(direction * FLY_SPEED, ACCELERATION * delta)
	
	# Move the character
	move_and_slide()
