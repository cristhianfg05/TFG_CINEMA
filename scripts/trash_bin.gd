extends StaticBody3D

@onready var mesh: MeshInstance3D = $Mesh

var _base_material := StandardMaterial3D.new()
var _highlight_material := StandardMaterial3D.new()


func _ready() -> void:
	_base_material.albedo_color = Color("315c46")
	_base_material.roughness = 0.95
	_highlight_material.albedo_color = Color("ffe66d")
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("7a6500")
	_highlight_material.emission_energy_multiplier = 1.5
	mesh.material_override = _base_material


func set_focused(focused: bool) -> void:
	mesh.material_override = _highlight_material if focused else _base_material


func get_interaction_prompt() -> String:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.bag_volume > 0.0:
		return "E — Vaciar bolsa"
	return "Bolsa vacía"


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.empty_bag()
