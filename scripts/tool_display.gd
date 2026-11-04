class_name ToolDisplay
extends Node3D

@export var tool_id: StringName
@export var model_scene: PackedScene
@export var visual_scale := Vector3.ONE
@export var visual_rotation_degrees := Vector3.ZERO
@export var interaction_size := Vector3(0.8, 0.7, 0.8)

var _highlight_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("tool_display")
	var manager := get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.owns_tool(tool_id):
		queue_free()
		return
	_build_visual()
	_build_interaction_area()


func get_interaction_prompt() -> String:
	return "[E] Inspeccionar"


func interact(_player: Node) -> void:
	var shop := get_tree().get_first_node_in_group("tool_shop_panel")
	if shop and shop.has_method("open_tool"):
		shop.open_tool(tool_id, self)


func set_focused(focused: bool) -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		mesh.material_overlay = _get_highlight_material() if focused else null


func remove_after_purchase() -> void:
	queue_free()


func _build_visual() -> void:
	if model_scene == null:
		push_error("ToolDisplay %s requires its indicated model_scene" % tool_id)
		return
	var visual := model_scene.instantiate() as Node3D
	visual.name = "ToolModel"
	visual.scale = visual_scale
	visual.rotation_degrees = visual_rotation_degrees
	add_child(visual)


func _build_interaction_area() -> void:
	var area := Area3D.new()
	area.name = "InteractionArea"
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = interaction_size
	collision.shape = shape
	collision.position.y = interaction_size.y * 0.5
	area.add_child(collision)
	add_child(area)


func _get_highlight_material() -> StandardMaterial3D:
	if _highlight_material == null:
		_highlight_material = StandardMaterial3D.new()
		_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_highlight_material.albedo_color = Color(1.0, 0.72, 0.24, 0.18)
		_highlight_material.emission_enabled = true
		_highlight_material.emission = Color("d7a33e")
		_highlight_material.emission_energy_multiplier = 0.7
	return _highlight_material
