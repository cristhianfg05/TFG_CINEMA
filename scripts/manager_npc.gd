extends StaticBody3D

@onready var desk: MeshInstance3D = get_node_or_null("Desk") as MeshInstance3D

var _desk_material := StandardMaterial3D.new()
var _highlight_material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("manager_desk")
	_desk_material.albedo_color = Color("563b2d")
	_desk_material.roughness = 0.9
	_highlight_material.albedo_color = Color("d9a85f")
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("6d4219")
	_highlight_material.emission_energy_multiplier = 1.2
	if desk:
		desk.material_override = _desk_material


func set_focused(focused: bool) -> void:
	if desk:
		desk.material_override = _highlight_material if focused else _desk_material


func get_interaction_prompt() -> String:
	return "E — Abrir mesa de herramientas"


func interact(_player: Node) -> void:
	var tool_shop := get_tree().get_first_node_in_group("tool_shop_panel")
	if tool_shop:
		tool_shop.open_shop()
