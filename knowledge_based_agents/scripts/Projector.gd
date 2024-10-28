class_name Projector extends MeshInstance3D

@onready var world_state: WorldState = WorldState.find(get_tree())
@onready var material = mesh.surface_get_material(0)

func _ready():
	material.emission_enabled = world_state.get_state("projector_on")

func set_projector(projector_on: bool):
	world_state.set_state("projector_on", projector_on)
	material.emission_enabled = projector_on
