class_name CharacterImpulseApplicator extends Node

@export var push_force = 2.0
@onready var character = get_parent()

func _physics_process(_delta):
	if not character.is_on_floor_only():
		apply_impulse()

func apply_impulse():
	for i in character.get_slide_collision_count():
		var collision = character.get_slide_collision(i)
		if collision.get_collider() is RigidBodyCustom:
			print("found")
			var rb = collision.get_collider() as RigidBodyCustom
			var collision_point = collision.get_position()
			var impulse = -collision.get_normal() * push_force

			# Convert world collision point to position relative to RigidBody's center
			var point_relative = collision_point - rb.global_position
			#rb.apply_impulse(impulse, point_relative)
			rb.apply_impulse_off_centre(impulse, point_relative)
			
		if collision.get_collider() is RigidBody3D:
			var rb = collision.get_collider() as RigidBody3D
			var collision_point = collision.get_position()
			var impulse = -collision.get_normal() * push_force

			# Convert world collision point to position relative to RigidBody's center
			var point_relative = collision_point - rb.global_position

			rb.apply_impulse(impulse, point_relative)
