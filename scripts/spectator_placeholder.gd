extends Node3D

@export var shirt_color := Color("6b4e8b")
@export var phase_offset: float = 0.0

var _time := 0.0
var _head: MeshInstance3D


func _ready() -> void:
	add_to_group("spectator")
	_build_placeholder()


func _process(delta: float) -> void:
	_time += delta
	if _head:
		_head.rotation.y = sin(_time * 0.8 + phase_offset) * 0.09
		_head.position.y = 1.73 + sin(_time * 1.2 + phase_offset) * 0.012


func _build_placeholder() -> void:
	var skin := _make_material(Color("b98563"))
	var clothes := _make_material(shirt_color)
	var dark := _make_material(Color("252933"))

	_add_capsule("Body", Vector3(0, 1.15, 0.2), 0.32, 0.95, clothes)
	_head = _add_sphere("Head", Vector3(0, 1.73, 0.18), 0.25, skin)
	_add_box("LeftLeg", Vector3(-0.17, 0.65, -0.12), Vector3(0.2, 0.22, 0.72), dark)
	_add_box("RightLeg", Vector3(0.17, 0.65, -0.12), Vector3(0.2, 0.22, 0.72), dark)


func _add_capsule(
	part_name: String,
	part_position: Vector3,
	radius: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.position = part_position
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 3
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
	return instance


func _add_sphere(
	part_name: String,
	part_position: Vector3,
	radius: float,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.position = part_position
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
	return instance


func _add_box(
	part_name: String,
	part_position: Vector3,
	size: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.position = part_position
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
	return instance


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
