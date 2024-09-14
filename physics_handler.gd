extends Node3D



# handle our all rigidbodies

var rgb_array: Array[Node3D] = [] # array of just our Rigidbody
var rid_map: Dictionary = {} # making a map of our RID -> Rigidbody object

var ps = PhysicsServer3D
var rs = RenderingServer


var rgb3d = preload("res://proto_rigid.tscn") # loading so i can spam out rigidbody nodes while testing in gdscript

func add_bodies():
	
	# we could create all our rigid bodies here maybe idk lmao im prototyping stuff
	# instantiate node from scene
	# place it as child of physics_world node
	var ball_1_rgb = rgb3d.instantiate()
	add_child(ball_1_rgb)
	ball_1_rgb.init_body("sphere", "sphere") # collision shape string, mesh shape string
	rgb_array.append(ball_1_rgb)
	rid_map[ball_1_rgb.get_body_rid()] = ball_1_rgb
	
	var ball_2_rgb = rgb3d.instantiate()
	add_child(ball_2_rgb)
	ball_2_rgb.init_body("sphere", "sphere") # collision shape string, mesh shape string
	rgb_array.append(ball_2_rgb)
	rid_map[ball_2_rgb.get_body_rid()] = ball_2_rgb
	
	rgb_array[0].add_pos(Vector3(0, 1.5, -3)) # translating the transform from the origin (0,0,0)
	rgb_array[1].add_pos(Vector3(-0.9, 1.5, -3))
	
	
	
	pass
	

# Called when the node enters the scene tree for the first time.
func _ready():
	
	add_bodies() # getting some predefined sort of hard coded rigidbodies into our scene
	
	pass # Replace with function body.




func _physics_process(delta):
	
	# perhaps iterate through all the rigidbodies which are children of this node
	# ask physics server if they have collided
	# if so, calculate impulse, call our rigid bodies apply_impulse
	# at the end once loop is done, call integrate_forces of each rigidbody in a separate loop
	# at very end actually update collsion shape transforms in the physics server
	
	
	#print("array_size : ", rgb_array.size())
	
	for rgb in rgb_array:
		
		rgb.apply_global_forces()
		
		# documentation says direct body state should (please god) have collision info
		var state = PhysicsServer3D.body_get_direct_state(rgb.get_body_rid())
		# maybe check collisions here, calc collison impulse, call rgb.apply_impulse, etc
		# id imagine we would need to figure out a fair amount of optimization here 
		var contact_count = 0
		
		
		# RID assigned from physics server that we placed in our rigidbody
		# so we can keep reference of our "unique" collision shape
		# that the physics server is keeping track of
		
		# ALTERNATIVE METHOD COMMENTED OUT AT THE VERY VERY BOTTOM OF THIS FILE. IM KEEPING IT AT THE BOTTOM AS I BELIEVE IT HAS INFORMATION WE WILL FIND USEFUL LATER ON
		if (state != null):
			# to accumulate forces/impulses etc but not apply them yet, as tons of shit could yet happen and we only want to apply once we have accumulated all the horrible things that will happen to our body
			contact_count = state.get_contact_count()
			#print(contact_count)
			for i in range(contact_count):
				
				#print("Contact!")
				
				#print("I am RID : ", rgb.get_body_rid())
				#return colliders RID
				#rint(state.get_contact_collider(i))
				
				# returns collider object
				# state.get_contact_collider_object(i)
				
				# get Objects ID, and Colliders RID
				# state.get_contact_collider_id
				
				var collider_id = state.get_contact_collider_id(i)
				var collision_point = state.get_contact_collider_position(i)
				var collision_normal = state.get_contact_local_normal(i)
				
				var contact_local_pos = state.get_contact_local_position(i)
				var penetration_depth = (collision_point - contact_local_pos).dot(collision_normal)
				
				var other_rid = state.get_contact_collider(i)
				# quick way of making sure we are only dealing with my rigid bodies right now
				if rid_map.has(other_rid): # means we hit another one of our rigid bodies yay!
					var other_rgb = rid_map[other_rid] 
					print("---")
					print("COLLISION DETECTED!!!!")
					print("Current RID : ", rgb.get_body_rid())
					print("Other RigidBody RID : ", other_rid)
					print("---")
					#resolveCollisionImpulse(rgb, other_rgb )
				else:
					print("---")
					print("COLLISION DETECTED!!!!")
					print("im being hit by NOT a rigidbody, probably your characterbody lmao")
					print("Current RID : ", rgb.get_body_rid())
					# we can easily check what type later, right now i dont care
					print("Other body (static or character) RID : ", other_rid)
					print("---")
					#print("something other than a rigidbody was hit and i dont care about that right now")
				
				
				#print("---")
				#print("My RID : ", rgb.get_body_rid())
				#print("Other RID : ", other_rid)
				#print("---")
				#print("collider_id : ", collider_id)
				#print("collision_point : ", collision_point)
				#print("collision normal : ",  collision_normal)
				#print("penetration depth : ", penetration_depth)
				#print("im in so much pain")
				
			
			
			
			
		
	
	# get all our calculated forces and impulses to take effect of our velocity etc causing new transform
	integrate_all_body_forces(delta)
	
	# update -  rendering server transform so we can see our change
		# update -  physics server collsion shape so we it knows where our
		# collision shape should be
	for rgb in rgb_array:
		rgb.update_server_transforms(delta)
	



func integrate_all_body_forces(delta):
	
	for rgb in rgb_array:
		rgb.integrate_forces(delta)
	
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass





func _potential_useful_collision_info():
	## maybe can create our own "space" from physics server. I will see if that # actually helps us or not to separate the spaces for (our) implementation
	#var space_state = PhysicsServer3D.space_get_direct_state(get_world_3d().space)
	#var shape_query = PhysicsShapeQueryParameters3D.new()
	#var shape_id = PhysicsServer3D.body_get_shape(rgb.our_RID, 0)
	##var shape_transform = PhysicsServer3D.body_get_shape_transform(rgb.our_RID, 0)
	#var shape_transform = PhysicsServer3D.body_get_state(rgb.our_RID, PhysicsServer3D.BODY_STATE_TRANSFORM)
	##shape_query.shape_rid = rgb.our_RID
	#shape_query.shape_rid = shape_id  
	##shape_query.transform = rgb.global_transform
	#shape_query.transform = shape_transform
	#shape_query.collide_with_bodies = true
	#shape_query.collide_with_areas = false
	#
	## test to see if we can get collision info this way
	## intersect_shape, collide_shape, cast_motion
	#
	## intersect_shape test and result
	#var max_results = 32
	#
	## seeing if our shape has touched anything
	## then if so, get a dictionary of the collision info
	## eg surface normal of collision point, intersection point, etc
	#var results = space_state.intersect_shape(shape_query, max_results)
	#
	#var info_dic = space_state.get_rest_info(shape_query)
	#var info_array = []
	#
	## If it collides with more than one shape, the nearest one is selected
	#info_array.append(info_dic.values())
	#
	##print("---------------")
	##print(info_array.size())
	##print(info_array[0].size())
	##print("---------------")
	#
	##print(info_dic)
	#
	##print("info_array size : " , info_array.size())
	##print("result size : ", results.size())
	#
	##if (info_array.size() > 1):
	##print("We are colliding with something")
	#
	#
	## wait why is counting collisions with itself? maybe check
	## if larger than 1 and starts results from second element onwards?
	##if results.size() > 1:
	##print("I am rgb RID : ", rgb.our_RID, " and our number of intersect_shape results : ", results.size())
	##for i in range(1, results.size()):
	##var result = results[i]
	##print("Collided with : ", result)
	##
	##
	##print("---")
	#
	pass 
