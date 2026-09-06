extends StaticBody3D

@export var definition: Resource

var _mesh_instance: MeshInstance3D
var _base_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("trash_item")
	_build_placeholder()


func set_focused(focused: bool) -> void:
	if _mesh_instance:
		_mesh_instance.material_override = _highlight_material if focused else _base_material


func get_interaction_prompt() -> String:
	if definition == null:
		return ""
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager == null:
		return ""
	if manager.can_collect(definition):
		return "E — Recoger: %s" % definition.display_name
	return "Bolsa llena — vacíala en el contenedor"


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.try_collect(self)


func collect() -> void:
	set_focused(false)
	collision_layer = 0
	queue_free()


func _build_placeholder() -> void:
	if definition == null:
		push_error("TrashItem requires a TrashDefinition")
		return

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "Mesh"
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var item_id := String(definition.id)
	var dimensions := _get_dimensions(item_id)
	_mesh_instance.mesh = _make_mesh(item_id, dimensions)
	_mesh_instance.position.y = dimensions.y * 0.5
	collision.shape = _make_shape(item_id, dimensions)
	collision.position.y = dimensions.y * 0.5

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = _get_color(item_id)
	_base_material.roughness = 0.85
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color("ffe66d")
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color("9a6f00")
	_highlight_material.emission_energy_multiplier = 1.8
	_mesh_instance.material_override = _base_material

	add_child(_mesh_instance)
	add_child(collision)


func _get_dimensions(item_id: String) -> Vector3:
	match item_id:
		"ticket": return Vector3(0.34, 0.025, 0.14)
		"napkin": return Vector3(0.3, 0.02, 0.26)
		"cup": return Vector3(0.28, 0.3, 0.28)
		"bottle": return Vector3(0.18, 0.46, 0.18)
		"can": return Vector3(0.18, 0.26, 0.18)
		"straw": return Vector3(0.025, 0.025, 0.4)
		"popcorn": return Vector3(0.14, 0.12, 0.14)
		"bucket": return Vector3(0.36, 0.34, 0.36)
		_: return Vector3(0.2, 0.2, 0.2)


func _make_mesh(item_id: String, dimensions: Vector3) -> PrimitiveMesh:
	if item_id in ["cup", "bottle", "can", "bucket"]:
		var cylinder := CylinderMesh.new()
		cylinder.height = dimensions.y
		cylinder.bottom_radius = dimensions.x * 0.5
		cylinder.top_radius = dimensions.x * (0.58 if item_id in ["cup", "bucket"] else 0.5)
		cylinder.radial_segments = 8
		return cylinder
	if item_id == "popcorn":
		var sphere := SphereMesh.new()
		sphere.radius = dimensions.x * 0.5
		sphere.height = dimensions.y
		sphere.radial_segments = 8
		sphere.rings = 4
		return sphere
	var box := BoxMesh.new()
	box.size = dimensions
	return box


func _make_shape(item_id: String, dimensions: Vector3) -> Shape3D:
	if item_id in ["cup", "bottle", "can", "bucket"]:
		var cylinder := CylinderShape3D.new()
		cylinder.height = dimensions.y
		cylinder.radius = dimensions.x * 0.5
		return cylinder
	if item_id == "popcorn":
		var sphere := SphereShape3D.new()
		sphere.radius = dimensions.x * 0.5
		return sphere
	var box := BoxShape3D.new()
	box.size = dimensions
	return box


func _get_color(item_id: String) -> Color:
	match item_id:
		"ticket": return Color("d8c99b")
		"napkin": return Color("e7ddd2")
		"cup": return Color("d94b4b")
		"bottle": return Color("4d9a78")
		"can": return Color("7ca6c8")
		"straw": return Color("f05d9b")
		"popcorn": return Color("f4c95d")
		"bucket": return Color("c73737")
		_: return Color("ffffff")
