class_name UpgradeDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(0, 1000, 1) var cost: int
@export var effect: StringName
@export var value: float
