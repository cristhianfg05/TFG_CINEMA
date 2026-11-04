extends Node

var _manager: GameplayManager
var _player: PlayerController
var _global_music: CinemaGlobalMusic


func _ready() -> void:
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	_global_music = get_parent().get_node_or_null("CinemaGlobalMusic") as CinemaGlobalMusic
	if _manager == null or _player == null or _global_music == null:
		push_error("Cinema room audio system requires gameplay, player and global music nodes.")
		return
	_manager.room_activated.connect(_on_room_activated)
	_player.room_changed.connect(_on_room_changed)
	_update_global_music()


func _on_room_activated(_room_id: StringName) -> void:
	_update_global_music()


func _on_room_changed(_room_id: StringName) -> void:
	_update_global_music()


func _update_global_music() -> void:
	var current_room := _player.get_current_room_id()
	var duck := false
	if _manager.is_room_activated(current_room):
		for controller in get_children():
			if controller.get("room_id") == current_room and controller.has_method("has_enabled_music"):
				duck = controller.has_enabled_music()
				break
	_global_music.set_ducked(duck)
