extends CharacterBody3D

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var camera = $camholder/Camera3D
var holding_object = false
var looked_object = null
var detect_distance: float = 20.0
var target_layer: int = 2
var throw_force = 7.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(event.relative.x * -0.04))
		
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event.is_action_pressed("use"):
		# create a new rigidbody
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
	var impulse_strength = 5.0  # Adjust this value to change the force
	rigid_body.apply_impulse(-camera.global_transform.basis.z * impulse_strength)



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
	
	
	
	move_and_slide()
