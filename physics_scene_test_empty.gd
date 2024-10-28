extends Node3D

@export_group("Sky Settings")
@export var sky_top_color: Color = Color(0.2, 0.4, 0.8, 1.0)
@export var sky_horizon_color: Color = Color(0.6, 0.7, 0.9, 1.0)
@export var ground_color: Color = Color(0.3, 0.3, 0.3, 1.0)
@export var ground_horizon_color: Color = Color(0.6, 0.7, 0.8, 1.0)
@export var sun_angle: Vector2 = Vector2(-45, -45)  # (pitch, yaw)
@export var sun_energy: float = 1.5

@export_group("Physics Test Settings")
@export var ball_test: RigidBodyCustom

var world_environment: WorldEnvironment
var sun: DirectionalLight3D

func _ready():
	setup_environment()
	setup_sun()
	apply_settings()
	
	# apply an impulse to the ball
	ball_test.apply_impulse(Vector3(-10,0,0))
	
	

func setup_environment():
	world_environment = WorldEnvironment.new()
	add_child(world_environment)
	
	var environment = Environment.new()
	world_environment.environment = environment
	
	var sky = ProceduralSkyMaterial.new()
	var sky_texture = Sky.new()
	sky_texture.sky_material = sky
	
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky_texture

func setup_sun():
	sun = DirectionalLight3D.new()
	add_child(sun)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05

func apply_settings():
	var sky_material = world_environment.environment.sky.sky_material
	
	# Sky colors
	sky_material.sky_top_color = sky_top_color
	sky_material.sky_horizon_color = sky_horizon_color
	sky_material.ground_bottom_color = ground_color
	sky_material.ground_horizon_color = ground_horizon_color
	
	# Sun settings
	sun.rotation_degrees = Vector3(sun_angle.x, sun_angle.y, 0)
	sun.light_energy = sun_energy
