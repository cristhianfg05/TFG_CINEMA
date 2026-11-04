class_name CinemaSeatInteractable
extends Area3D

var room_id: StringName
var seat_id: StringName
var seat_body: Node3D
var facing_y := 0.0
var aisle_x := 0.0
var rear_direction := 1.0


func can_be_selected_from(player: Node3D) -> bool:
	if player == null or seat_body == null:
		return false
	# The screen-facing direction is the only approach side where the cushion
	# can be entered, independently of how a future room is rotated.
	var offset := player.global_position - seat_body.global_position
	var front := Vector3.FORWARD.rotated(Vector3.UP, facing_y)
	return offset.dot(front) > 0.38 and Vector2(offset.x, offset.z).length() < 3.1


func get_interaction_prompt() -> String:
	var manager := get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if manager == null or not manager.is_room_activated(room_id) or not manager.is_room_fully_clean(room_id):
		return ""
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if not can_be_selected_from(player):
		return ""
	return "[E] Sentarse a ver la película"


func interact(player: Node) -> void:
	if get_interaction_prompt().is_empty() or not player is PlayerController or not can_be_selected_from(player):
		return
	(player as PlayerController).sit_in_cinema_seat(self)


func get_sitting_position() -> Vector3:
	return seat_body.global_position + Vector3.UP * 0.06


func get_exit_candidates() -> Array[Vector3]:
	var at := seat_body.global_position
	return [
		at + Vector3(0.0, 0.0, -rear_direction * 1.05),
		at + Vector3(0.0, 0.0, -rear_direction * 1.22),
		Vector3(aisle_x, at.y, at.z - rear_direction * 0.4),
		Vector3(aisle_x, at.y, at.z),
	]
