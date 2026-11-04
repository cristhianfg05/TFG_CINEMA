class_name TrashDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var category: StringName
@export_range(1, 10, 1) var size_units: int = 1
@export_range(0, 100, 1) var reward: int = 1
@export var destination: StringName = &"trash_bin"
@export var model: PackedScene
@export_range(0.001, 10.0, 0.001) var model_scale: float = 1.0
@export var model_rotation_degrees: Vector3 = Vector3.ZERO
