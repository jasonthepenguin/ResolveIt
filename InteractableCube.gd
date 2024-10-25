extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var affordance: Node = $Affordance

var original_color: Color = Color.WHITE
var original_scale: Vector3
var can_duplicate: bool = true
var is_interacting: bool = false


func _ready() -> void:
	setup_affordances()
	
	## Get the original material
	if mesh.get_surface_override_material(0) == null:
		## Create a new material if none exists
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		mesh.set_surface_override_material(0, material)
		
	original_color = mesh.get_surface_override_material(0).albedo_color
	original_scale = scale
	add_to_group("interactable")
	affordance.add_affordance("activate", activate)  # REMOVE THIS LIN
	print("Added activate affordance to cube")


func setup_affordances() -> void:
	match name.to_lower():
		"activatecube":
			affordance.add_affordance("activate", activate)
		"jumpcube":
			affordance.add_affordance("jump", jump)
		"runcube":
			affordance.add_affordance("run", run)
		"happycube":
			affordance.add_affordance("happy", happy)
		"shrinkcube":
			affordance.add_affordance("shrink", shrink)
		"dancecube":
			affordance.add_affordance("dance", dance)
		"duplicatecube":
			affordance.add_affordance("duplicate", duplicate_cube)


func activate() -> void:  # Default to green if no color specified
	if is_interacting:
		return
	
	is_interacting = true
	print("Cube activated - changing to red")
	change_color(Color.RED)
	
	await get_tree().create_timer(1.0).timeout
	reset_color()
	is_interacting = false
	

func jump() -> void:
	change_color(Color.BLUE)
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 2.0, 0.3)
	tween.tween_property(self, "position:y", position.y, 0.3)
	await tween.finished
	reset_color()


func run() -> void:
	change_color(Color.ORANGE)
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x + 2.0, 0.5)
	
	tween.tween_property(self, "position:x", position.x, 0.5)
	await tween.finished
	reset_color()
	

func happy() -> void:
	change_color(Color.GREEN)
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", rotation.y + PI * 2, 1.0)
	
	await tween.finished
	reset_color()


func shrink() -> void:
	change_color(Color.PURPLE)
	var tween = create_tween()
	
	tween.tween_property(self, "scale", original_scale * 0.5, 0.5)
	await get_tree().create_timer(1.0).timeout
	
	tween.tween_property(self, "scale", original_scale, 0.5)
	await tween.finished
	
	reset_color()


func dance() -> void:
	
	change_color(Color.YELLOW)
	var tween = create_tween()
	# Create a fun dance sequence
	
	for i in range(4):
		tween.tween_property(self, "position:y", position.y + 1.0, 0.2)
		tween.tween_property(self, "rotation:y", rotation.y + PI/2, 0.1)
		tween.tween_property(self, "position:y", position.y, 0.2)
	await tween.finished
	reset_color()


func duplicate_cube() -> void:
	
	if not can_duplicate:
		
		return
	
	change_color(Color.CYAN)
	can_duplicate = false # Prevent spam duplicating
	
	var new_cube = self.duplicate()
	new_cube.position += Vector3(2.0, 0, 0)
	new_cube.can_duplicate = false # Prevent duplicates from duplicating
	get_parent().add_child(new_cube)
	new_cube.add_to_group("interactable")
	
	await get_tree().create_timer(1.0).timeout
	reset_color()
	await get_tree().create_timer(5.0).timeout
	can_duplicate = true # Reset duplicate ability after cooldown



func change_color(color: Color) -> void:
	var material = mesh.get_surface_override_material(0)
	
	if material == null:
		material = StandardMaterial3D.new()
		
	material.albedo_color = color
	mesh.set_surface_override_material(0, material)



func reset_color() -> void:
	var material = mesh.get_surface_override_material(0)
	
	if material == null:
		material = StandardMaterial3D.new()
		
	material.albedo_color = original_color
	mesh.set_surface_override_material(0, material)
