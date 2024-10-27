extends CharacterBody3D

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

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
		
	if event.is_action_released("space"):
		# Create a new RigidBodyCustom instance
		spawn_rigid_body()

func spawn_rigid_body():
	var physics_handler = get_parent().get_node("PhysicsHandler")
	#var physics_handler = GlobalPhysicsHandler
	# Create the rigid body
	var rigid_body = RigidBodyCustom.new()
	rigid_body.mass = 1.0
	rigid_body.restitution = 0.8
	
	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	collision_shape.shape = shape
	rigid_body.add_child(collision_shape)
	
	# Add mesh for visualization
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh_instance.mesh = mesh
	rigid_body.add_child(mesh_instance)
	
	# Set initial position in front of the camera
	var spawn_pos = camera.global_position + (-camera.global_transform.basis.z * 2)
	rigid_body.position = spawn_pos
	
	# Add to PhysicsHandler instead of the player
	physics_handler.add_child(rigid_body)
	
	# Apply impulse in the direction the camera is facing
	# Wait one frame to ensure the rigid body is properly added to the scene
	# await get_tree().process_frame
	var impulse_strength = 10.0  # Adjust this value to change the force
	rigid_body.apply_impulse(-camera.global_transform.basis.z * impulse_strength)

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	# Get the camera's forward direction
	var forward_dir = camera.global_transform.basis.z  # Removed the negative sign here
	var right_dir = camera.global_transform.basis.x
	
	# Calculate movement direction
	var direction = (forward_dir * input_dir.y + right_dir * input_dir.x).normalized()
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector3.ZERO, SPEED)
	
	# Additional up/down movement with spacebar
	# if Input.is_action_pressed("ui_accept"): # spacebar
		#velocity.y += SPEED
	if Input.is_action_pressed("ui_down"): # Optional: key for moving down
		velocity.y -= SPEED
	
	if looked_object and holding_object:
		var cam_trans = camera.global_transform
		looked_object.global_transform.origin = (cam_trans.origin + cam_trans.basis.z * -1.0)
	
	move_and_slide()
