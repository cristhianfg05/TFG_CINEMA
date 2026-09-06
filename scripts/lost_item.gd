extends StaticBody3D

@export var definition: Resource

var _mesh_parts: Array[MeshInstance3D] = []
var _base_material := StandardMaterial3D.new()
var _highlight_material := StandardMaterial3D.new()
var _focused := false
var _time := 0.0


func _ready() -> void:
	add_to_group("lost_item")
	_build_watch_placeholder()


func _process(delta: float) -> void:
	_time += delta
	if not _focused:
		_base_material.emission_energy_multiplier = 0.7 + sin(_time * 3.0) * 0.2


func set_focused(focused: bool) -> void:
	_focused = focused
	for mesh_part in _mesh_parts:
		mesh_part.material_override = _highlight_material if focused else _base_material


func get_interaction_prompt() -> String:
	if definition == null:
		return ""
	return "E — Guardar %s  |  Clic — Tirar (-%d)" % [
		definition.display_name,
		int(definition.destruction_penalty),
	]


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.collect_lost_item(self)


func primary_interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.destroy_lost_item(self)


func collect() -> void:
	set_focused(false)
	collision_layer = 0
	queue_free()


func _build_watch_placeholder() -> void:
	_base_material.albedo_color = Color("c89b3c")
	_base_material.metallic = 0.65
	_base_material.roughness = 0.28
	_base_material.emission_enabled = true
	_base_material.emission = Color("9b6c16")
	_base_material.emission_energy_multiplier = 0.7
	_highlight_material.albedo_color = Color("ffe59a")
	_highlight_material.metallic = 0.8
	_highlight_material.roughness = 0.2
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("ffbd38")
	_highlight_material.emission_energy_multiplier = 2.2

	var face := MeshInstance3D.new()
	face.name = "WatchFace"
	var face_mesh := CylinderMesh.new()
	face_mesh.height = 0.07
	face_mesh.bottom_radius = 0.18
	face_mesh.top_radius = 0.18
	face_mesh.radial_segments = 12
	face.mesh = face_mesh
	face.rotation_degrees.x = 90.0
	face.position.y = 0.08
	face.material_override = _base_material
	add_child(face)
	_mesh_parts.append(face)

	var strap := MeshInstance3D.new()
	strap.name = "Strap"
	var strap_mesh := BoxMesh.new()
	strap_mesh.size = Vector3(0.12, 0.035, 0.62)
	strap.mesh = strap_mesh
	strap.position.y = 0.05
	strap.material_override = _base_material
	add_child(strap)
	_mesh_parts.append(strap)

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.38, 0.16, 0.66)
	collision.shape = shape
	collision.position.y = 0.08
	add_child(collision)
