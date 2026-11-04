extends Node

const ROOM_IDS := [&"room_01", &"room_02", &"room_03", &"room_04"]
var _manager: GameplayManager
var _seat_enabled: Dictionary = {}


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	if _manager == null:
		push_error("CinemaSeatSystem requires GameplayManager.")
		return
	_manager.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for room_id in ROOM_IDS:
		var enabled := _manager.is_room_activated(room_id) and _manager.is_room_fully_clean(room_id)
		if _seat_enabled.has(room_id) and bool(_seat_enabled[room_id]) == enabled:
			continue
		_seat_enabled[room_id] = enabled
		for seat in get_tree().get_nodes_in_group("cinema_seat"):
			if seat.room_id == room_id:
				seat.collision_layer = 2 if enabled else 0
