extends StaticBody3D

@onready var desk: MeshInstance3D = $Desk

var _desk_material := StandardMaterial3D.new()
var _highlight_material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("manager_npc")
	_desk_material.albedo_color = Color("563b2d")
	_desk_material.roughness = 0.9
	_highlight_material.albedo_color = Color("d9a85f")
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("6d4219")
	_highlight_material.emission_energy_multiplier = 1.2
	desk.material_override = _desk_material
	$Body.material_override = _make_material(Color("456d78"))
	$Head.material_override = _make_material(Color("b98563"))


func set_focused(focused: bool) -> void:
	desk.material_override = _highlight_material if focused else _desk_material


func get_interaction_prompt() -> String:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		return ""
	var definition = manager.get_next_upgrade()
	if definition == null:
		return "Encargado: ya tienes las dos mejoras"
	if manager.coins >= int(definition.cost):
		return "E — Comprar %s (%d monedas)" % [definition.display_name, int(definition.cost)]
	return "%s cuesta %d — tienes %d" % [definition.display_name, int(definition.cost), manager.coins]


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.try_purchase_next_upgrade()


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
