# CharacterImpulseApplicator.gd
class_name ImpulseApplicator

var push_force: float = 2.0
var character: CharacterBody3D

func _physics_process():
	for i in character.get_slide_collision_count():
		var collision = character.get_slide_collision(i)
		if collision.get_collider() is RigidBody3D:
			var rb = collision.get_collider() as RigidBody3D
			var collision_point = collision.get_position()
			var impulse = -collision.get_normal() * push_force

			# Convert world collision point to position relative to RigidBody's center
			var point_relative = collision_point - rb.global_position

			rb.apply_impulse(impulse, point_relative)
