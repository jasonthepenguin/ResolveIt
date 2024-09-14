extends Node3D



# My $2 fake plastic alibaba rigidbody class

var ps = PhysicsServer3D
var rs = RenderingServer

var body_rid
var mesh_rid
@onready var mesh_shape
@onready var collision_shape

var body_trans = self.global_transform

# i will eventually have accumulators for all variables. torque, impulse, etc
# i will plan to add more variables here eg inertia tensors and all that shit

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	pass


func set_trans(new_trans):
	body_trans = new_trans
	self.global_transform = body_trans

func get_trans():
	
	return body_trans



func add_pos(new_pos):
	body_trans = body_trans.translated(new_pos)
	self.global_transform = body_trans

# transform, collision shape, mesh shape
func init_body(c_shape: String, m_shape: String ):
	
	#ps = n_ps
	#rs = n_rs
	
	#physics server to track our collision body and to tell us if our collision body is touching anything
	# only using it for collision detection information so dont worry
	
	
	# prototype obvioulsy will be doing other shit here
	match c_shape:
		"box":
			print("creating box collision shape primitive")
		"sphere":
			collision_shape = SphereShape3D.new()
			print("creating sphere collision shape primitive")
		_:
			
			print("invalid collision shape: defaulting to some shit")
	
	match m_shape:
		"box":
			print("b m shape")
		"sphere":
			mesh_shape = SphereMesh.new()
			print("s m shape")
		_:
			print("default mesh shape")
	
	# setting our body state
	
	body_rid = ps.body_create()
	
	ps.body_set_max_contacts_reported(body_rid, 5)
	ps.body_set_collision_layer(body_rid, 1)
	ps.body_set_collision_mask(body_rid, 1)
	
	#body_rid = ps.body_create()
	ps.body_set_space(body_rid, get_world_3d().space)
	ps.body_add_shape(body_rid, collision_shape)
	#ps.body_set_state(sphere_body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, our_trans)
	ps.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, get_trans())
	ps.body_set_shape_transform(body_rid, 0, Transform3D(Basis.IDENTITY, Vector3.ZERO))
	
	
	# setting render state
	mesh_rid = rs.instance_create2(mesh_shape, get_world_3d().scenario)
	rs.instance_set_transform(mesh_rid, get_trans())
	
	# etc disabling settings and setting modes
	ps.body_set_omit_force_integration(get_body_rid(), true)
	ps.body_set_mode(get_body_rid(), PhysicsServer3D.BODY_MODE_RIGID)
	
	pass


func get_body_rid():
	return body_rid

func set_body_rid(rid_val):
	body_rid = rid_val

func update_server_transforms(delta):
	
	# updating the physics server so it knows where my new transform is, so next physics update it can tell us if we hit anything
	PhysicsServer3D.body_set_state(body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, get_trans())
	# updating rendering server so we can see our mesh in its new transform position
	RenderingServer.instance_set_transform(mesh_rid, get_trans())
	
	
	pass

func apply_global_forces():
	
	
	pass


func apply_impulse():
	
	pass

func apply_force():
	
	
	pass


func integrate_forces(deltaTime):
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



