extends Node3D

@export var material: Material


func _ready() -> void:
	_apply_material(self)


func _apply_material(node: Node) -> void:
	if node is MeshInstance3D and material != null:
		node.material_override = material
	for child in node.get_children():
		_apply_material(child)
