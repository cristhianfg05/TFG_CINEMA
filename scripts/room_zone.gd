class_name RoomZone
extends Area3D

@export var room_id: StringName


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_current_room_id"):
		body.set_current_room_id(room_id)
