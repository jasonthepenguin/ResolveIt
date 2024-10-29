extends MeshInstance3D

var material: Material
var accumulator = 0.0
var world_state: WorldState

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().scene
	material = mesh.surface_get_material(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	accumulator += delta
	if (accumulator > 1.2):
		material.emission_enabled = not material.emission_enabled
		accumulator = 0.0
		
func set_projector(is_on: bool):
	material.emission_enabled = is_on
	
func is_on() -> bool:
	return material.emission_enabled
