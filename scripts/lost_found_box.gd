extends StaticBody3D

@onready var mesh: MeshInstance3D = $Mesh

var _base_material := StandardMaterial3D.new()
var _highlight_material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("lost_found")
	_base_material.albedo_color = Color("315f82")
	_base_material.roughness = 0.8
	_highlight_material.albedo_color = Color("75c9ff")
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("246f9c")
	_highlight_material.emission_energy_multiplier = 1.4
	mesh.material_override = _base_material


func set_focused(focused: bool) -> void:
	mesh.material_override = _highlight_material if focused else _base_material


func get_interaction_prompt() -> String:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.lost_item_state == "carried":
		return "E — Entregar reloj perdido (+8 monedas)"
	if manager and manager.lost_item_state == "returned":
		return "Objetos perdidos: reloj entregado"
	return "Cajón de objetos perdidos"


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.deposit_lost_items()
