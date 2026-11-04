extends Node

# Discovers recordings at gameplay events and serializes playback through the
# existing GameIntro cassette/typewriter UI. Discovered IDs persist in the manager.
const ENTRANCE_POSITION := Vector2(14.75, -14.64)
const ENTRANCE_RADIUS_SQUARED := 3.5 * 3.5

var _manager: GameplayManager
var _player: PlayerController
var _intro: GameIntro
var _menu: UpgradeMenu
var _pending: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_manager = get_tree().get_first_node_in_group("gameplay_manager") as GameplayManager
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	_intro = get_tree().get_first_node_in_group("game_intro") as GameIntro
	_menu = get_tree().get_first_node_in_group("upgrade_menu") as UpgradeMenu
	if _manager == null or _player == null or _intro == null or _menu == null:
		push_error("RecordingDirector requires manager, player, intro and upgrade menu")
		set_process(false)
		return
	_manager.recording_found.connect(_on_recording_found)
	_manager.state_changed.connect(_evaluate_progress)
	_manager.collectible_found.connect(_on_collectible_found)
	_player.room_changed.connect(_on_room_changed)
	_menu.document_closed.connect(_on_document_closed)
	for definition in _manager.get_found_recording_definitions():
		var recording_id := String(definition.id)
		if recording_id != "01" and not _manager.is_recording_heard(recording_id):
			_enqueue(recording_id)
	call_deferred("_evaluate_progress")
	call_deferred("_evaluate_figure_milestones")


func _process(_delta: float) -> void:
	if not _manager.is_recording_found("08") and _player.get_current_room_id() == &"lobby":
		var position := _player.global_position
		if Vector2(position.x, position.z).distance_squared_to(ENTRANCE_POSITION) <= ENTRANCE_RADIUS_SQUARED:
			_discover("08")
	if _pending.is_empty() or _menu.is_open() or get_tree().paused or not _intro.can_play_recording():
		return
	var recording_id := _pending[0]
	if _intro.play_recording(recording_id):
		_pending.remove_at(0)


func _discover(recording_id: String) -> void:
	_manager.discover_recording(recording_id)


func _enqueue(recording_id: String) -> void:
	if not _pending.has(recording_id):
		_pending.append(recording_id)


func _on_recording_found(recording_id: String) -> void:
	if recording_id != "01":
		_enqueue(recording_id)


func _evaluate_progress() -> void:
	if _manager.room_completed:
		_discover("02")
	if not _manager.is_recording_found("14") and _manager.is_hammer_unlocked():
		_discover("14")


func _on_room_changed(room_id: StringName) -> void:
	match room_id:
		&"manager_office": _discover("03")
		&"room_02": _discover("05")
		&"lobby": _discover("07")
		&"room_04": _discover("11")
		&"room_03": _discover("12")


func _on_document_closed(document_id: String) -> void:
	match document_id:
		"Doc5": _discover("04")
		"Doc4": _discover("06")
		"Doc9": _discover("13")
		"Doc11": _discover("16")


func _on_collectible_found(collectible_id: String) -> void:
	var definition := _manager.get_collectible_definition(collectible_id)
	if not _is_figure(definition):
		return
	_evaluate_figure_milestones()


func _evaluate_figure_milestones() -> void:
	var figure_count := 0
	for collectible in _manager.get_collectible_definitions(true):
		if _is_figure(collectible):
			figure_count += 1
	if figure_count >= 1:
		_discover("09")
	if figure_count >= 5:
		_discover("10")
	if figure_count >= 10:
		_discover("17")


func _is_figure(definition: Dictionary) -> bool:
	var number := int(definition.get("number", 0))
	return not definition.is_empty() and number >= 1 and number <= 10 and String(definition.get("display_type", "")) != "poster"
