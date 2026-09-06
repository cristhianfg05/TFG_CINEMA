class_name LostItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_range(0, 1000, 1) var return_reward: int
@export_range(0, 1000, 1) var destruction_penalty: int
@export var model: PackedScene
