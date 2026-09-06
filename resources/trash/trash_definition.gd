class_name TrashDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var category: StringName
@export_range(0.01, 10.0, 0.01) var volume: float = 1.0
@export_range(0, 100, 1) var reward: int = 1
@export var destination: StringName = &"trash_bin"
@export var model: PackedScene
