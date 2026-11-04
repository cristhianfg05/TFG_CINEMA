class_name DocumentPickup
extends Area3D

@export var document_id := ""

@onready var paper: Node3D = $Paper

var _visual_meshes: Array[MeshInstance3D] = []
var _base_overlays: Dictionary = {}
var _highlight_material: StandardMaterial3D
var _collected := false


func _ready() -> void:
	add_to_group("document_pickup")
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.albedo_color = Color(1.0, 0.84, 0.45, 0.17)
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("8f651d")
	_highlight_material.emission_energy_multiplier = 0.15
	for descendant in paper.find_children("*", "MeshInstance3D", true, false):
		var mesh_part := descendant as MeshInstance3D
		if mesh_part != null and mesh_part.visible:
			_visual_meshes.append(mesh_part)
			_base_overlays[mesh_part] = mesh_part.material_overlay
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		push_error("DocumentPickup '%s' requiere GameplayManager." % name)
		return
	manager.document_found.connect(_on_document_found)
	if not manager.has_document_definition(document_id):
		push_error("DocumentPickup '%s' usa un document_id desconocido: '%s'." % [name, document_id])
		visible = false
		collision_layer = 0
		return
	if manager.is_document_found(document_id):
		_collected = true
		queue_free()


func get_interaction_prompt() -> String:
	return "" if _collected else "E — Recoger documento"


func interact(_player: Node) -> void:
	if _collected:
		return
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and manager.collect_document(document_id, self):
		_collected = true


func set_focused(focused: bool) -> void:
	for mesh_part in _visual_meshes:
		if is_instance_valid(mesh_part):
			mesh_part.material_overlay = _highlight_material if focused else _base_overlays.get(mesh_part)


func collect() -> void:
	_collected = true
	set_focused(false)
	collision_layer = 0
	collision_mask = 0
	queue_free()


func _on_document_found(found_document_id: String) -> void:
	if found_document_id == document_id and not _collected:
		collect()
