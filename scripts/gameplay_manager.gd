class_name GameplayManager
extends Node

signal state_changed
signal notification_requested(message: String)
signal coin_rewarded(amount: int, source_world_position: Vector3)
signal trash_collected
signal lost_item_collected
signal pickup_rejected
signal vacuum_activity_changed(active: bool)
signal document_found(document_id: String)
signal document_read(document_id: String)
signal collectible_found(collectible_id: String)
signal collectible_viewed(collectible_id: String)
signal recording_found(recording_id: String)
signal final_wall_struck(hit_count: int)
signal final_wall_opened
signal discovery_found(discovery_type: StringName, item_id: String, notification_title: String, notification_hint: String, target_section: StringName)
signal room_activated(room_id: StringName)
signal movie_cycle_watched(room_id: StringName)
signal trash_deposited(definition_id: String, units: int, earned: int)
signal broom_swept

const SAVE_PATH := "user://cinema_cleaner_save.json"
const SAVE_VERSION := 14
const Rules := preload("res://resources/upgrades/incremental_rules.gd")
const CINEMA_ROOM_IDS := [&"room_01", &"room_02", &"room_03", &"room_04", &"room_05"]
const STANDARD_MOVIE_ROOM_IDS := [&"room_01", &"room_02", &"room_03", &"room_04"]
const HAMMER_REQUIRED_AREAS: Array[StringName] = [&"room_01", &"left_corridor", &"manager_office", &"room_02", &"room_03", &"lobby", &"right_corridor", &"room_04"]
const FINAL_WALL_HITS := 4
const TRASH_SCENE := preload("res://scenes/gameplay/trash_item.tscn")
const LOST_ITEM_SCENE := preload("res://scenes/gameplay/lost_item.tscn")
const SEALED_BAG_SCENE := preload("res://scenes/gameplay/sealed_bag.tscn")
const WATCH_DEFINITION := preload("res://resources/lost_items/cheap_watch.tres")
const ROOM_LOST_ITEM_TOTAL := 1
const CARRIED_SACK_ABSORB_DISTANCE := 1.0
const SACK_THROW_SPEED := 6.4
const SACK_THROW_UPWARD_SPEED := 3.45
const PICKUP_REJECT_FEEDBACK_COOLDOWN := 0.12
const BIN_DELIVERY_STREAMS := [
	preload("res://assets/audio/sfx/trash/bin_delivery_01.wav"),
	preload("res://assets/audio/sfx/trash/bin_delivery_02.wav"),
	preload("res://assets/audio/sfx/trash/bin_delivery_03.wav"),
	preload("res://assets/audio/sfx/trash/bin_delivery_04.wav"),
	preload("res://assets/audio/sfx/trash/bin_delivery_05.wav"),
]
const TRASH_PICKUP_STREAM := preload("res://assets/audio/sfx/trash/trash_pickup_v2_05.wav")
const COIN_REWARD_STREAMS := [
	preload("res://assets/audio/sfx/rewards/coin_reward_v2_01.wav"),
	preload("res://assets/audio/sfx/rewards/coin_reward_v2_02.wav"),
	preload("res://assets/audio/sfx/rewards/coin_reward_v2_03.wav"),
	preload("res://assets/audio/sfx/rewards/coin_reward_v2_04.wav"),
	preload("res://assets/audio/sfx/rewards/coin_reward_v2_05.wav"),
]
const BAG_FULL_STREAM := preload("res://assets/audio/sfx/bags/bag_full_04.wav")
const BAG_SEAL_STREAM := preload("res://assets/audio/sfx/bags/bag_seal_05.wav")
const BAG_THROW_STREAM := preload("res://assets/audio/sfx/bags/bag_throw_04.wav")
const DOCUMENT_PICKUP_STREAM := preload("res://assets/audio/sfx/documents/document_pickup_sheet_02_first_half.wav")
const VACUUM_START_SHORT_STREAM := preload("res://assets/audio/sfx/tools/vacuum_start_01_half.wav")
const VACUUM_SUCTION_LOOP_STREAM := preload("res://assets/audio/sfx/tools/vacuum_suction_03_steady_loop.wav")
const FIRST_ARCADE_HARD_POSTER_ID := "arcade_reel_rescue_hard_poster"
const SECOND_ARCADE_HARD_POSTER_ID := "arcade_second_game_hard_poster"
const VACUUM_LOOP_VOLUME_DB := -13.0
const VACUUM_LOOP_SILENT_DB := -48.0
const VACUUM_PLAYER_CAPTURE_DISTANCE := 0.82
const VACUUM_CONE_DOT := 0.58
const VACUUM_PULL_ACCELERATION := 19.0
const UpgradeCatalog := preload("res://resources/upgrades/upgrade_catalog.gd")
const DocumentCatalog := preload("res://resources/documents/document_catalog.gd")
const CollectibleCatalog := preload("res://resources/collectibles/collectible_catalog.gd")
const RecordingCatalog := preload("res://resources/recordings/recording_catalog.gd")
const ONE_UNIT_DEFINITIONS: Array[Resource] = [
	preload("res://resources/trash/ticket.tres"), preload("res://resources/trash/napkin.tres"),
	preload("res://resources/trash/cup.tres"), preload("res://resources/trash/can.tres"),
	preload("res://resources/trash/straw.tres"), preload("res://resources/trash/popcorn.tres"),
]
const TWO_UNIT_DEFINITIONS: Array[Resource] = [
	preload("res://resources/trash/bottle.tres"), preload("res://resources/trash/bucket.tres"),
]
const TRASH_RAMP_FRONT_Z := -10.25
const TRASH_RAMP_REAR_Z := 9.70
const TRASH_RAMP_REAR_HEIGHT := 1.17
const TRASH_SEAT_ROW_RISE := 0.13
const TRASH_SEATING_INNER_X := 1.0
const TRASH_SEATING_OUTER_X := 9.2
const TRASH_DROP_HEIGHT := 0.25
const TRASH_FLOOR_GUARD_BATCH_SIZE := 16
const TRASH_FLOOR_MIN_CLEARANCE := 0.008
const TRASH_STREAM_INTERVAL := 0.45
const TRASH_VISIBLE_DISTANCE_SQUARED := 24.0 * 24.0
const TRASH_SIMULATE_DISTANCE_SQUARED := 30.0 * 30.0
const ROOM_ONE_COIN_TRASH_COUNT := 380
const ROOM_TWO_COIN_TRASH_COUNT := 20
const ROOM_TRASH_COUNT := ROOM_ONE_COIN_TRASH_COUNT + ROOM_TWO_COIN_TRASH_COUNT
const ROOM_BASE_COIN_TOTAL := ROOM_ONE_COIN_TRASH_COUNT + ROOM_TWO_COIN_TRASH_COUNT * 2
const TRASH_ON_SEAT_COUNT := 60
const TRASH_UNDER_SEAT_COUNT := 100
const TRASH_BETWEEN_ROWS_COUNT := 108
const TRASH_OPEN_FLOOR_COUNT := 132
const SEAT_ROW_POSITIONS: Array[float] = [-9.3, -7.3, -5.3, -3.3, -1.3, 0.7, 2.7, 4.7, 6.7, 8.7]
const SEAT_COLUMN_POSITIONS: Array[float] = [-8.36, -7.0, -5.64, -4.28, -2.92, -1.54, 1.54, 2.92, 4.28, 5.64, 7.0, 8.36]
const SPAWN_POSITIONS: Array[Vector3] = [
	Vector3(-0.46, 0, -9.40), Vector3(0.46, 0, -9.40), Vector3(-0.46, 0, -7.40), Vector3(0.46, 0, -7.40),
	Vector3(-0.46, 0, -5.40), Vector3(0.46, 0, -5.40), Vector3(-0.46, 0, -3.40), Vector3(0.46, 0, -3.40),
	Vector3(-0.46, 0, -1.40), Vector3(0.46, 0, -1.40), Vector3(-0.46, 0, 0.60), Vector3(0.46, 0, 0.60),
	Vector3(-0.46, 0, 2.60), Vector3(0.46, 0, 2.60), Vector3(-0.46, 0, 4.60), Vector3(0.46, 0, 4.60),
	Vector3(-0.46, 0, 6.60), Vector3(0.46, 0, 6.60), Vector3(-0.46, 0, 8.60), Vector3(0.46, 0, 8.60),
	Vector3(-10.05, 0, -9.60), Vector3(-10.05, 0, -8.18), Vector3(-10.05, 0, -6.76), Vector3(-10.05, 0, -5.34),
	Vector3(-10.05, 0, -3.92), Vector3(-10.05, 0, -2.50), Vector3(-10.05, 0, -1.08), Vector3(-10.05, 0, 0.34),
	Vector3(-10.05, 0, 1.76), Vector3(-10.05, 0, 3.18), Vector3(-10.05, 0, 4.60), Vector3(-10.05, 0, 6.02),
	Vector3(-10.05, 0, 7.44), Vector3(-10.05, 0, 8.86), Vector3(10.05, 0, -9.60), Vector3(10.05, 0, -8.18),
	Vector3(10.05, 0, -6.76), Vector3(10.05, 0, -5.34), Vector3(10.05, 0, -3.92), Vector3(10.05, 0, -2.50),
	Vector3(10.05, 0, -1.08), Vector3(10.05, 0, 0.34), Vector3(10.05, 0, 1.76), Vector3(10.05, 0, 3.18),
	Vector3(10.05, 0, 4.60), Vector3(10.05, 0, 6.02), Vector3(10.05, 0, 7.44), Vector3(10.05, 0, 8.86),
	Vector3(-7.0, 0, -11.30), Vector3(-5.5, 0, -12.00), Vector3(-4.3, 0, -11.30), Vector3(-3.1, 0, -12.00),
	Vector3(-1.8, 0, -11.30), Vector3(1.8, 0, -12.00), Vector3(3.1, 0, -11.30), Vector3(4.3, 0, -12.00),
	Vector3(5.5, 0, -11.30), Vector3(7.0, 0, -12.00), Vector3(-8.2, 0, -11.30), Vector3(8.2, 0, -12.00),
]

@export var bag_capacity: int = 25
@export var base_bag_capacity: int = 25
@export var base_deposit_interval := 0.60
@export var base_pickup_cooldown: float = 0.75
@export var use_legacy_vacuum_audio := false

var bag_volume: int = 0
var coins: int = 0
var loaded_save := false
var remaining_trash: int = 0
var total_trash: int = 0
var pickup_cooldown: float = 0.75
var held_lost_items: Array[String] = []
var lost_item_state := "available"
var upgrade_levels: Dictionary = {}
var purchased_tools: Dictionary = {}
var equipped_tool := ""
var room_completed := false
var recycle_multiplier := 1
var manual_pickup_count := 1
var manual_reach := 1.5
var max_active_sacks := 0
var vacuum_reach := 1.5
var vacuum_battery := 8.0
var vacuum_recharge := 1.0
var broom_interval := 1.20
var broom_width := 0.75
var bag_contents: Dictionary = {}
var legacy_bag_units := 0
var claimed_objective_rewards: Dictionary = {}
var moved_trash: Dictionary = {}
var legacy_layout_pending := false
var legacy_layout_migrated: Dictionary = {}
var _legacy_reward_baseline := false
var _objective_reward_timer := 0.0
var _deposit_target: Node3D
var _deposit_timer := 0.0
var _broom_cooldown := 0.0
var _save_dirty := false
var _autosave_elapsed := 0.0
var carried_sack: Dictionary = {}
var document_definitions: Array[Dictionary] = []
var last_selected_document_id := ""
var collectible_definitions: Array[Dictionary] = []
var last_selected_collectible_id := ""
var ability_ready_at_unix: Dictionary = {}
var trash_bin_guidance_triggered := false
var trash_bin_guidance_completed := false
var room_trash_totals: Dictionary = {}
var room_trash_remaining: Dictionary = {}
var room_trash_unit_totals: Dictionary = {}
var room_trash_units_remaining: Dictionary = {}
var activated_rooms: Dictionary = {}
var movie_watched_rooms: Dictionary = {}
var first_room_exit_seen := false
var arcade_discovered := false
var second_arcade_discovered := false
var lobby_unlocked := false
var right_corridor_unlocked := false
var hammer_taken := false
var final_wall_damage := 0
var final_wall_open := false
var final_wall_hit_points: Array[Vector2] = []
var _last_player_room_id: StringName = &"room_01"

var _pending_base_value := 0
var _pickup_cooldown_remaining := 0.0
var _pickup_reject_feedback_remaining := 0.0
var _reserved_bag_units := 0
var _saved_sacks: Array = []
var _carried_sack_node: SealedBag
var _trash_layout_seed := 0
var _trash_floor_guard_cursor := 0
var _trash_stream_elapsed := TRASH_STREAM_INTERVAL
var _document_definitions_by_id: Dictionary = {}
var _found_document_ids: Dictionary = {}
var _read_document_ids: Dictionary = {}
var _collectible_definitions_by_id: Dictionary = {}
var _found_collectible_ids: Dictionary = {}
var _viewed_collectible_ids: Dictionary = {}
var _found_recording_ids: Dictionary = {}
var _heard_recording_ids: Dictionary = {}
var _all_seeing_active_remaining := 0.0
var _all_seeing_room_id: StringName = &""
var _collected_world_trash_ids: Dictionary = {}
var _vacuum_charge := 0.0
var _vacuum_initialized := false
var _vacuum_trigger_held := false
var _vacuum_active := false
var _bin_delivery_randomizer: AudioStreamRandomizer
var _coin_reward_randomizer: AudioStreamRandomizer

@onready var trash_items: Node3D = $TrashItems
@onready var lost_items: Node3D = $LostItems
@onready var sealed_bags: Node3D = $SealedBags
@onready var pickup_audio: AudioStreamPlayer = $PickupAudio
@onready var trash_pickup_audio: AudioStreamPlayer = $TrashPickupAudio
@onready var coin_reward_audio: AudioStreamPlayer = $CoinRewardAudio
@onready var empty_audio: AudioStreamPlayer = $EmptyAudio
@onready var bin_delivery_audio: AudioStreamPlayer = $BinDeliveryAudio
@onready var bag_full_audio: AudioStreamPlayer = $BagFullAudio
@onready var bag_seal_audio: AudioStreamPlayer = $BagSealAudio
@onready var bag_throw_audio: AudioStreamPlayer = $BagThrowAudio
@onready var reject_audio: AudioStreamPlayer = $RejectAudio
@onready var vacuum_audio: AudioStreamPlayer = $VacuumAudio
@onready var vacuum_transition_audio: AudioStreamPlayer = $VacuumTransitionAudio
@onready var document_pickup_audio: AudioStreamPlayer = $DocumentPickupAudio
var _vacuum_audio_fade: Tween


func _ready() -> void:
	pickup_audio.stream = _make_tone(430.0, 0.06)
	empty_audio.stream = _make_tone(170.0, 0.14)
	reject_audio.stream = _make_reject_tone()
	if use_legacy_vacuum_audio:
		vacuum_audio.stream = _make_vacuum_wind()
		vacuum_audio.volume_db = -17.0
	else:
		var suction_loop := VACUUM_SUCTION_LOOP_STREAM.duplicate(true) as AudioStreamWAV
		suction_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		suction_loop.loop_begin = 0
		suction_loop.loop_end = suction_loop.data.size() / 4 # PCM16 stereo: four bytes per frame.
		vacuum_audio.stream = suction_loop
		vacuum_transition_audio.stream = VACUUM_START_SHORT_STREAM
	_bin_delivery_randomizer = AudioStreamRandomizer.new()
	_bin_delivery_randomizer.random_pitch = 1.025
	_bin_delivery_randomizer.random_volume_offset_db = 0.5
	for delivery_stream in BIN_DELIVERY_STREAMS:
		_bin_delivery_randomizer.add_stream(_bin_delivery_randomizer.get_streams_count(), delivery_stream, 1.0)
	bin_delivery_audio.stream = _bin_delivery_randomizer
	trash_pickup_audio.stream = TRASH_PICKUP_STREAM
	_coin_reward_randomizer = AudioStreamRandomizer.new()
	_coin_reward_randomizer.random_pitch = 1.02
	_coin_reward_randomizer.random_volume_offset_db = 0.4
	for coin_stream in COIN_REWARD_STREAMS:
		_coin_reward_randomizer.add_stream(_coin_reward_randomizer.get_streams_count(), coin_stream, 1.0)
	coin_reward_audio.stream = _coin_reward_randomizer
	bag_full_audio.stream = BAG_FULL_STREAM
	bag_seal_audio.stream = BAG_SEAL_STREAM
	bag_throw_audio.stream = BAG_THROW_STREAM
	document_pickup_audio.stream = DOCUMENT_PICKUP_STREAM
	var unit_audio := AudioStreamPlayer.new()
	unit_audio.name = "UnitDepositAudio"
	var unit_stream := AudioStreamRandomizer.new()
	unit_stream.add_stream(0, load("res://assets/audio/sfx/trash/bin_paper_plastic_soft_02.wav"))
	unit_stream.random_pitch = 1.025
	unit_stream.random_volume_offset_db = 0.6
	unit_audio.stream = unit_stream
	unit_audio.max_polyphony = 3
	unit_audio.volume_db = -13.0
	unit_audio.bus = "Trash"
	add_child(unit_audio)
	var sweep_audio := AudioStreamPlayer.new()
	sweep_audio.name = "BroomSweepAudio"
	var sweep_stream := AudioStreamRandomizer.new()
	sweep_stream.add_stream(0, load("res://assets/audio/sfx/tools/broom_soft_sweep_01.wav"))
	sweep_stream.random_pitch = 1.03
	sweep_stream.random_volume_offset_db = 0.4
	sweep_audio.stream = sweep_stream
	sweep_audio.volume_db = -10.0
	sweep_audio.bus = "Tools"
	add_child(sweep_audio)
	var upgrade_audio := AudioStreamPlayer.new()
	upgrade_audio.name = "UpgradePurchaseAudio"
	upgrade_audio.process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_audio.bus = "UI"
	upgrade_audio.volume_db = -6.0
	upgrade_audio.max_polyphony = 2
	var upgrade_stream := AudioStreamRandomizer.new()
	upgrade_stream.add_stream(0,load("res://assets/audio/sfx/ui/upgrade_levelup_03.wav"))
	upgrade_stream.random_pitch = 1.015
	upgrade_stream.random_volume_offset_db = 0.25
	upgrade_audio.stream = upgrade_stream
	add_child(upgrade_audio)
	_load_document_catalog()
	_load_collectible_catalog()
	_load_progress()
	_apply_document_progress()
	_apply_collectible_progress()
	_apply_upgrades()
	_trigger_trash_bin_guidance_if_needed()
	_spawn_trash()
	_spawn_saved_sacks()
	_spawn_lost_item_if_needed()
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("room_changed"):
		player.room_changed.connect(_on_player_room_changed)
	call_deferred("_restore_carried_sack_visual")
	state_changed.emit()
	call_deferred("_evaluate_room_completion")


func _input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.ctrl_pressed
		and event.shift_pressed
		and event.keycode == KEY_F8
	):
		debug_unlock_and_clean_all()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		reset_authored_room_trash_for_debug()
		get_tree().reload_current_scene()
	elif event.is_action_pressed("ability_1") and not event.is_echo():
		try_use_active_ability(0)
	elif event.is_action_pressed("ability_2") and not event.is_echo():
		try_use_active_ability(1)
	elif event.is_action_pressed("seal_bag") and not event.is_echo() and max_active_sacks > 0:
		# Legacy B binding remains accepted for existing saves and controllers.
		try_seal_full_bag()


func _physics_process(delta: float) -> void:
	_update_progressive_deposit(delta)
	_broom_cooldown = maxf(0.0, _broom_cooldown - delta)
	_objective_reward_timer += delta
	_autosave_elapsed += delta
	if _objective_reward_timer >= 0.25:
		_objective_reward_timer = 0.0
		_check_monetary_objectives()
	if _save_dirty and _autosave_elapsed >= 0.75:
		_save_progress()
	_trash_stream_elapsed += delta
	if _trash_stream_elapsed >= TRASH_STREAM_INTERVAL:
		_trash_stream_elapsed = 0.0
		_update_trash_streaming()
	_pickup_cooldown_remaining = maxf(0.0, _pickup_cooldown_remaining - delta)
	_pickup_reject_feedback_remaining = maxf(0.0, _pickup_reject_feedback_remaining - delta)
	if _all_seeing_active_remaining > 0.0:
		_all_seeing_active_remaining = maxf(0.0, _all_seeing_active_remaining - delta)
		if is_zero_approx(_all_seeing_active_remaining):
			_set_all_seeing_reveal(false)
			_all_seeing_room_id = &""
			state_changed.emit()
		else:
			_refresh_all_seeing_room()
	_keep_trash_above_floor_batch()
	_update_vacuum(delta)
	if is_instance_valid(_carried_sack_node):
		if find_accepting_sack_bin(_carried_sack_node, CARRIED_SACK_ABSORB_DISTANCE):
			request_sack_absorption(_carried_sack_node)


func reset_authored_room_trash_for_debug() -> void:
	# Room 1 is generated afresh on reload. Authored zones use stable IDs, so R
	# must explicitly forget those IDs before the save is loaded again.
	_collected_world_trash_ids.clear()
	for room_key in room_trash_totals:
		room_trash_remaining[room_key] = int(room_trash_totals[room_key])
		room_trash_units_remaining[room_key] = int(room_trash_unit_totals.get(room_key, 0))
	_save_progress()
	state_changed.emit()


func debug_unlock_and_clean_all() -> void:
	coins = maxi(coins, 999999)
	for tool_id in UpgradeCatalog.TOOL_DEFINITIONS:
		purchased_tools[String(tool_id)] = true
	for branch in UpgradeCatalog.BRANCHES:
		upgrade_levels[String(branch.id)] = (branch.costs as Array).size()
	equipped_tool = "vacuum" if owns_tool(&"vacuum") else ""
	ability_ready_at_unix.clear()
	_all_seeing_active_remaining = 0.0
	_all_seeing_room_id = &""
	_set_all_seeing_reveal(false)

	# Dense trash includes objects without a nearby interaction node. Retire
	# their data as well, so debug cleanup cannot recreate them on the next tick.
	var registry := get_dense_registry()
	if registry != null:
		for index in registry.entries.size():
			if registry.entries[index].alive:
				_collected_world_trash_ids[String(registry.entries[index].id)] = true
				registry.remove_entry(index)
	for item in get_tree().get_nodes_in_group("trash_item"):
		if item.has_method("get_world_item_id"):
			var world_item_id := String(item.get_world_item_id())
			if not world_item_id.is_empty():
				_collected_world_trash_ids[world_item_id] = true
		item.queue_free()
	remaining_trash = 0
	for room_key in room_trash_totals:
		room_trash_remaining[room_key] = 0
		room_trash_units_remaining[room_key] = 0
	room_completed = true
	bag_volume = 0
	_pending_base_value = 0
	_reserved_bag_units = 0

	for sack in get_tree().get_nodes_in_group("sealed_bag"):
		if sack.get_parent():
			sack.get_parent().remove_child(sack)
		sack.queue_free()
	carried_sack.clear()
	_carried_sack_node = null
	_saved_sacks.clear()

	for definition in document_definitions:
		var document_id := String(definition.id)
		_found_document_ids[document_id] = true
		_read_document_ids[document_id] = true
		_sync_document_definition_state(document_id)
	for definition in collectible_definitions:
		var collectible_id := String(definition.id)
		_found_collectible_ids[collectible_id] = true
		_viewed_collectible_ids[collectible_id] = true
		_sync_collectible_definition_state(collectible_id)
	for pickup in get_tree().get_nodes_in_group("document_pickup"):
		pickup.queue_free()
	for pickup in get_tree().get_nodes_in_group("collectible_pickup"):
		pickup.queue_free()
	for display in get_tree().get_nodes_in_group("tool_display"):
		display.queue_free()

	lost_item_state = "returned"
	held_lost_items.clear()
	for lost_item in get_tree().get_nodes_in_group("lost_item"):
		lost_item.queue_free()
	trash_bin_guidance_triggered = true
	trash_bin_guidance_completed = true
	_apply_upgrades()
	_save_progress()
	state_changed.emit()
	notification_requested.emit("DEBUG: contenido desbloqueado y zonas limpiadas.")


func can_collect(definition: Resource) -> bool:
	return definition != null and carried_sack.is_empty() and bag_volume + _reserved_bag_units + int(definition.size_units) <= bag_capacity


func try_collect(item: Node, bypass_cooldown: bool = false) -> bool:
	if item == null or not is_instance_valid(item) or item.definition == null:
		return false
	if item.has_method("is_being_collected") and item.is_being_collected():
		return false
	if not bypass_cooldown and not can_pick_up_now():
		return false
	if not can_collect(item.definition):
		return false
	_pickup_cooldown_remaining = pickup_cooldown
	return _complete_trash_collection(item)


func request_collect(item: Node, collector: Node = null) -> bool:
	if item == null or not is_instance_valid(item) or item.definition == null:
		return false
	if item.has_method("is_being_collected") and item.is_being_collected():
		return false
	if not carried_sack.is_empty():
		_play_pickup_rejected_feedback()
		return false
	if not can_collect(item.definition):
		_play_pickup_rejected_feedback()
		return false
	if not can_pick_up_now():
		if get_upgrade_level(&"quick_hands") == 0:
			_play_pickup_rejected_feedback()
		return false
	var collector_3d := collector as Node3D
	if collector_3d == null:
		collector_3d = get_tree().get_first_node_in_group("player") as Node3D
	if collector_3d == null or not item.has_method("begin_collection"):
		return try_collect(item)
	_pickup_cooldown_remaining = pickup_cooldown
	var started := _begin_reserved_collection(item, collector_3d)
	if started and manual_pickup_count > 1:
		_collect_visible_neighbors(item, collector_3d, manual_pickup_count - 1)
	return started


func _play_pickup_rejected_feedback() -> void:
	if _pickup_reject_feedback_remaining > 0.0:
		return
	_pickup_reject_feedback_remaining = PICKUP_REJECT_FEEDBACK_COOLDOWN
	pickup_rejected.emit()
	if DisplayServer.get_name() != "headless":
		reject_audio.play()


func _begin_reserved_collection(item: Node, collector: Node3D) -> bool:
	if not can_collect(item.definition):
		return false
	var reserved_units := int(item.definition.size_units)
	_reserved_bag_units += reserved_units
	if item.begin_collection(collector, Callable(self, "_finish_animated_collection").bind(reserved_units)):
		return true
	_reserved_bag_units = maxi(0, _reserved_bag_units - reserved_units)
	return false


func _collect_visible_neighbors(primary: Node3D, collector: Node3D, amount: int) -> void:
	var candidates: Array[Node] = []
	for child in get_tree().get_nodes_in_group("trash_item"):
		if child == primary or not child is Node3D:
			continue
		if child.has_method("is_being_collected") and child.is_being_collected():
			continue
		if primary.global_position.distance_to(child.global_position) <= 1.15:
			candidates.append(child)
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool: return primary.global_position.distance_squared_to(a.global_position) < primary.global_position.distance_squared_to(b.global_position))
	var collected := 0
	for candidate in candidates:
		if collected >= amount or not can_collect(candidate.definition):
			break
		if _has_collection_line_of_sight(collector, candidate) and _begin_reserved_collection(candidate, collector):
			collected += 1


func _has_collection_line_of_sight(collector: Node3D, item: Node3D) -> bool:
	var origin := collector.global_position + Vector3.UP * 1.55
	var query := PhysicsRayQueryParameters3D.create(origin, item.global_position + Vector3.UP * 0.08, 3)
	if collector is CollisionObject3D:
		query.exclude = [(collector as CollisionObject3D).get_rid()]
	query.collide_with_areas = true
	var hit := collector.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	return collider == item or (collider != null and collider.get_parent() == item)


func _finish_animated_collection(item: Node, reserved_units: int) -> void:
	_reserved_bag_units = maxi(0, _reserved_bag_units - reserved_units)
	_complete_trash_collection(item)


func _complete_trash_collection(item: Node) -> bool:
	if item == null or not is_instance_valid(item) or item.definition == null:
		return false
	var was_bag_full := bag_volume >= bag_capacity
	bag_volume += int(item.definition.size_units)
	_pending_base_value += int(item.definition.reward)
	var definition_id := String(item.definition.id)
	bag_contents[definition_id] = int(bag_contents.get(definition_id, 0)) + 1
	var collected_room_id := String(item.get_room_id()) if item.has_method("get_room_id") else "room_01"
	var world_item_id := String(item.get_world_item_id()) if item.has_method("get_world_item_id") else ""
	if collected_room_id == "room_01":
		remaining_trash = maxi(0, remaining_trash - 1)
	room_trash_remaining[collected_room_id] = maxi(0, int(room_trash_remaining.get(collected_room_id, 0)) - 1)
	room_trash_units_remaining[collected_room_id] = maxi(0, int(room_trash_units_remaining.get(collected_room_id, 0)) - int(item.definition.size_units))
	if not world_item_id.is_empty():
		_collected_world_trash_ids[world_item_id] = true
	item.collect()
	if DisplayServer.get_name() != "headless":
		if trash_pickup_audio.stream:
			trash_pickup_audio.play()
		else:
			pickup_audio.play()
	if not was_bag_full and bag_volume >= bag_capacity:
		_play_bag_full_feedback()
	trash_collected.emit()
	_trigger_trash_bin_guidance_if_needed()
	state_changed.emit()
	_evaluate_room_completion()
	if not world_item_id.is_empty():
		_save_dirty = true
	return true


func can_pick_up_now() -> bool:
	return get_pickup_cooldown_remaining() <= 0.0


func get_pickup_cooldown_remaining() -> float:
	return _pickup_cooldown_remaining


func empty_bag() -> bool:
	if not carried_sack.is_empty():
		if is_instance_valid(_carried_sack_node):
			return request_sack_absorption(_carried_sack_node)
		var orphaned_base_value := int(carried_sack.get("base_value", 0))
		carried_sack.clear()
		_award_sack_value(orphaned_base_value)
		return true
	if bag_volume <= 0:
		return false
	# Compatibility entry point: a click now delivers one object, never the bag.
	return deposit_one()


func format_money(amount: int) -> String:
	return Rules.money(amount)


func get_deposit_interval() -> float:
	return base_deposit_interval * pickup_cooldown / base_pickup_cooldown

func get_trash_definition(definition_id: String) -> Resource:
	for definition in ONE_UNIT_DEFINITIONS + TWO_UNIT_DEFINITIONS:
		if String(definition.id)==definition_id: return definition
	return null


func is_depositing() -> bool:
	return is_instance_valid(_deposit_target)


func begin_deposit(bin: Node3D) -> void:
	if bin == null or bag_volume <= 0 or not carried_sack.is_empty():
		return
	if _deposit_target == bin:
		return
	_deposit_target = bin
	if _deposit_timer<=0.00001:
		_deposit_timer = get_deposit_interval()
		deposit_one()


func stop_deposit() -> void:
	if _deposit_target != null:
		_deposit_target = null
		_save_progress()


func _update_progressive_deposit(delta: float) -> void:
	_deposit_timer=maxf(0.0,_deposit_timer-delta)
	if _deposit_target == null:
		return
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if not is_instance_valid(_deposit_target) or player == null or get_tree().paused or player.is_sitting() or not player.is_cleaning_input_allowed() or not Input.is_action_pressed("interact") or player.get_interaction_target() != _deposit_target:
		stop_deposit()
		return
	# Preserve cooldown across releases/restarts and never burst several pieces
	# together after a delayed frame.
	if _deposit_timer<=0.00001:
		if not deposit_one():
			stop_deposit()
			return
		_deposit_timer = get_deposit_interval()
	if bag_volume == 0:
		stop_deposit()


func deposit_one() -> bool:
	if bag_volume <= 0 or not carried_sack.is_empty():
		return false
	var key := ""
	var units := 1
	var base_value := 1
	for definition_id in bag_contents:
		if int(bag_contents[definition_id]) > 0:
			key = String(definition_id)
			break
	if not key.is_empty():
		var definition := get_trash_definition(key)
		if definition == null: return false
		units = int(definition.size_units)
		base_value = int(definition.reward)
		bag_contents[key] = int(bag_contents[key]) - 1
		if int(bag_contents[key]) == 0:
			bag_contents.erase(key)
	elif legacy_bag_units > 0:
		legacy_bag_units -= 1
		key = "legacy"
	else:
		return false
	bag_volume = maxi(0, bag_volume - units)
	_pending_base_value = maxi(0, _pending_base_value - base_value)
	var earned := base_value * recycle_multiplier
	coins += earned
	trash_deposited.emit(key, units, earned)
	_complete_trash_bin_guidance()
	if is_instance_valid(_deposit_target) and _deposit_target.has_method("play_unit_deposit"):
		_deposit_target.play_unit_deposit(key)
	else:
		play_unit_deposit_feedback()
	_save_dirty = true
	state_changed.emit()
	return true


func play_unit_deposit_feedback() -> void:
	if DisplayServer.get_name() != "headless" and has_node("UnitDepositAudio"):
		$UnitDepositAudio.play()


func _get_trash_bin_position() -> Vector3:
	var trash_bin := get_tree().get_first_node_in_group("trash_bin") as Node3D
	return trash_bin.global_position if trash_bin else Vector3.ZERO


func _get_trash_bin_absorption_position() -> Vector3:
	var trash_bin := get_tree().get_first_node_in_group("trash_bin") as Node3D
	if trash_bin == null:
		return Vector3.ZERO
	if trash_bin.has_method("get_absorption_point"):
		return trash_bin.get_absorption_point()
	return trash_bin.global_position + Vector3.UP * 0.68


func play_coin_reward_feedback() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if coin_reward_audio.stream:
		coin_reward_audio.play()


func _play_bag_full_feedback() -> void:
	if DisplayServer.get_name() != "headless" and bag_full_audio.stream:
		bag_full_audio.play()


func _play_bag_seal_feedback() -> void:
	if DisplayServer.get_name() != "headless" and bag_seal_audio.stream:
		bag_seal_audio.play()


func _play_bag_throw_feedback() -> void:
	if DisplayServer.get_name() != "headless" and bag_throw_audio.stream:
		bag_throw_audio.play()


func _play_empty_feedback(trash_bin: Node = null) -> void:
	_complete_trash_bin_guidance()
	if trash_bin == null:
		trash_bin = get_tree().get_first_node_in_group("trash_bin")
	if trash_bin and trash_bin.has_method("play_deposit_animation"):
		trash_bin.play_deposit_animation()
	if DisplayServer.get_name() != "headless":
		if bin_delivery_audio.stream:
			bin_delivery_audio.play()
		else:
			empty_audio.play()
	_save_progress()
	state_changed.emit()


func _trigger_trash_bin_guidance_if_needed() -> void:
	if trash_bin_guidance_triggered or bag_volume < bag_capacity:
		return
	trash_bin_guidance_triggered = true
	trash_bin_guidance_completed = false
	_save_progress()


func _complete_trash_bin_guidance() -> void:
	if not trash_bin_guidance_triggered or trash_bin_guidance_completed:
		return
	trash_bin_guidance_completed = true


func is_trash_bin_guidance_active() -> bool:
	return trash_bin_guidance_triggered and not trash_bin_guidance_completed


func try_seal_full_bag() -> bool:
	if max_active_sacks <= 0:
		return false
	if bag_volume < bag_capacity:
		return false
	if get_active_sack_count() >= max_active_sacks:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return false
	var sack := SEALED_BAG_SCENE.instantiate()
	sack.contained_units = bag_capacity
	sack.contained_base_value = _pending_base_value
	sack.created_room_id = &"room_01"
	sack.delivered = false
	sealed_bags.add_child(sack)
	sack.global_position = _find_safe_sack_position(player)
	sack.linear_velocity = Vector3.DOWN * 1.35
	bag_volume = 0
	_pending_base_value = 0
	bag_contents.clear()
	legacy_bag_units = 0
	_play_bag_seal_feedback()
	call_deferred("_make_sack_non_blocking_for_player", sack)
	_save_progress()
	state_changed.emit()
	return true


func pick_up_sealed_bag(sack: Node) -> bool:
	if not carried_sack.is_empty() or sack == null:
		return false
	var typed_sack := sack as SealedBag
	var anchor := _get_sack_carry_anchor()
	if typed_sack == null or anchor == null or not typed_sack.begin_carry(anchor):
		return false
	carried_sack = {"units": typed_sack.contained_units, "base_value": typed_sack.contained_base_value, "created_room_id": String(typed_sack.created_room_id), "delivered": false}
	_carried_sack_node = typed_sack
	_save_progress()
	state_changed.emit()
	return true


func has_carried_sack() -> bool:
	return not carried_sack.is_empty() and is_instance_valid(_carried_sack_node)


func drop_carried_sack() -> bool:
	return _release_carried_sack(Vector3.ZERO, false)


func throw_carried_sack(direction: Vector3 = Vector3.ZERO) -> bool:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if direction.is_zero_approx() and player:
		var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
		direction = -camera.global_basis.z if camera else -player.global_basis.z
	var launch_velocity := direction.normalized() * SACK_THROW_SPEED + Vector3.UP * SACK_THROW_UPWARD_SPEED
	if player:
		launch_velocity += Vector3(player.velocity.x, 0.0, player.velocity.z)
	return _release_carried_sack(launch_velocity, true)


func _release_carried_sack(release_velocity: Vector3, thrown: bool) -> bool:
	if carried_sack.is_empty() or not is_instance_valid(_carried_sack_node):
		return false
	var sack := _carried_sack_node
	var release_transform := sack.global_transform
	var safe_release := _resolve_safe_sack_release_transform(sack, release_transform)
	if safe_release.is_empty():
		return false
	release_transform = safe_release.transform
	if not sack.release_to(sealed_bags, release_transform, release_velocity):
		return false
	if thrown:
		_play_bag_throw_feedback()
	carried_sack.clear()
	_carried_sack_node = null
	call_deferred("_make_sack_non_blocking_for_player", sack)
	_save_progress()
	state_changed.emit()
	return true


func _resolve_safe_sack_release_transform(sack: SealedBag, desired: Transform3D) -> Dictionary:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	var collision := sack.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if player == null or collision == null or not collision.shape is SphereShape3D:
		return {"transform": desired}
	var camera := player.get_node_or_null("Head/Camera3D") as Camera3D
	var ray_origin := camera.global_position if camera else player.global_position + Vector3.UP * 1.3
	var desired_center := collision.global_position
	var radius := (collision.shape as SphereShape3D).radius
	var direction := ray_origin.direction_to(desired_center)
	var ray_end := desired_center + direction * (radius + 0.06)
	var release_exclusions: Array[RID] = [player.get_rid(), sack.get_rid()]
	# Loose litter is movable, not an architectural obstacle. With dense trash
	# it must not prevent dropping a full sack next to an otherwise clear wall.
	for node in get_tree().get_nodes_in_group("trash_item"):
		var item := node as CollisionObject3D
		if item != null and item.global_position.distance_squared_to(player.global_position) < 16.0:
			release_exclusions.append(item.get_rid())
	var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)
	ray_query.exclude = release_exclusions
	var hit := player.get_world_3d().direct_space_state.intersect_ray(ray_query)
	var candidates: Array[Vector3] = [desired_center]
	if not hit.is_empty():
		candidates[0] = (hit.position as Vector3) - direction * (radius + 0.065)

	var horizontal_forward := -player.global_basis.z
	horizontal_forward.y = 0.0
	horizontal_forward = horizontal_forward.normalized()
	var side := horizontal_forward.cross(Vector3.UP).normalized()
	var fallback_center := player.global_position + Vector3.UP * (radius + 0.06)
	for offset in [
		-horizontal_forward, side, -side,
		(-horizontal_forward + side).normalized(), (-horizontal_forward - side).normalized(),
	]:
		candidates.append(fallback_center + offset * (radius + 0.48))

	for candidate_center in candidates:
		if not _has_clear_sack_release_path(player, ray_origin, candidate_center, release_exclusions):
			continue
		if not _is_sack_release_space_clear(player, collision.shape, candidate_center, release_exclusions):
			continue
		var result := desired
		result.origin += candidate_center - desired_center
		return {"transform": result}
	return {}


func _has_clear_sack_release_path(
	player: CharacterBody3D, from: Vector3, to: Vector3, exclusions: Array[RID]
) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = exclusions
	return player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _is_sack_release_space_clear(
	player: CharacterBody3D, shape: Shape3D, center: Vector3, exclusions: Array[RID]
) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = 1
	query.margin = 0.025
	query.exclude = exclusions
	return player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func find_accepting_sack_bin(sack: SealedBag, radius: float) -> Node3D:
	var nearest: Node3D
	var distance := INF
	for candidate in get_tree().get_nodes_in_group("trash_bin"):
		if not candidate is Node3D or not candidate.has_method("can_accept_sack"):
			continue
		var candidate_distance := sack.global_position.distance_squared_to(candidate.global_position)
		if candidate_distance < distance and candidate.can_accept_sack(sack, radius):
			nearest = candidate
			distance = candidate_distance
	return nearest


func request_sack_absorption(sack: SealedBag) -> bool:
	if sack == null or not is_instance_valid(sack) or sack.delivered or sack.is_absorbing():
		return false
	if sack != _carried_sack_node and sack.get_parent() != sealed_bags:
		return false
	var radius := CARRIED_SACK_ABSORB_DISTANCE if sack == _carried_sack_node else SealedBag.BIN_ABSORB_DISTANCE
	var trash_bin := find_accepting_sack_bin(sack, radius)
	if trash_bin == null:
		return false
	var base_value := sack.contained_base_value
	var target: Vector3 = trash_bin.get_absorption_point()
	var callback := Callable(self, "_finish_sack_absorption").bind(sack, base_value, trash_bin)
	if not sack.begin_absorption(sealed_bags, target, callback):
		return false
	if sack == _carried_sack_node:
		carried_sack.clear()
		_carried_sack_node = null
	state_changed.emit()
	return true


func _finish_sack_absorption(sack: SealedBag, base_value: int, trash_bin: Node3D) -> void:
	if is_instance_valid(sack):
		if sack.get_parent():
			sack.get_parent().remove_child(sack)
		sack.queue_free()
	_award_sack_value(base_value, trash_bin)


func _award_sack_value(base_value: int, trash_bin: Node3D = null) -> void:
	var sack_value := base_value * recycle_multiplier
	coins += sack_value
	coin_rewarded.emit(sack_value, trash_bin.global_position if is_instance_valid(trash_bin) else _get_trash_bin_position())
	_play_empty_feedback(trash_bin if is_instance_valid(trash_bin) else null)


func get_active_sack_count() -> int:
	return sealed_bags.get_child_count() + (0 if carried_sack.is_empty() else 1)


func _get_sack_carry_anchor() -> Node3D:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_sack_carry_anchor"):
		return player.get_sack_carry_anchor() as Node3D
	return null


func _restore_carried_sack_visual() -> void:
	if carried_sack.is_empty() or is_instance_valid(_carried_sack_node):
		return
	var anchor := _get_sack_carry_anchor()
	if anchor == null:
		return
	var sack := SEALED_BAG_SCENE.instantiate() as SealedBag
	sack.contained_units = int(carried_sack.get("units", 0))
	sack.contained_base_value = int(carried_sack.get("base_value", 0))
	sack.created_room_id = StringName(carried_sack.get("created_room_id", "room_01"))
	sack.delivered = false
	sealed_bags.add_child(sack)
	if sack.begin_carry(anchor):
		_carried_sack_node = sack
		state_changed.emit()
	else:
		sack.queue_free()


func _find_safe_sack_position(player: Node3D) -> Vector3:
	var target := player.global_position - player.global_basis.z * 1.35
	var query := PhysicsRayQueryParameters3D.create(target + Vector3.UP * 1.4, target + Vector3.DOWN * 3.4, 1)
	if player is CollisionObject3D:
		query.exclude = [(player as CollisionObject3D).get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return Vector3(target.x, (hit.position as Vector3).y + 1.25, target.z)
	return target + Vector3.UP * 1.25


func get_clean_percent(room_id: StringName = &"room_01") -> float:
	if room_id != &"room_01":
		return get_room_clean_percent(room_id)
	if total_trash <= 0: return 100
	return Rules.percent(total_trash - remaining_trash, total_trash)


func register_room_trash(room_id: StringName, object_total: int, unit_total: int) -> void:
	var key := String(room_id)
	room_trash_totals[key] = object_total
	room_trash_unit_totals[key] = unit_total
	var collected_objects := 0
	var collected_units := 0
	for item_id in _collected_world_trash_ids:
		if String(item_id).begins_with(key + ":"):
			collected_objects += 1
			collected_units += 2 if String(item_id).contains(":large:") else 1
	room_trash_remaining[key] = maxi(0, object_total - collected_objects)
	room_trash_units_remaining[key] = maxi(0, unit_total - collected_units)


func is_world_trash_collected(world_item_id: String) -> bool:
	return bool(_collected_world_trash_ids.get(world_item_id, false))


func get_room_clean_percent(room_id: StringName) -> float:
	var key := String(room_id)
	var room_total := int(room_trash_totals.get(key, 0))
	if room_total <= 0:
		return 100
	return Rules.percent(room_total - int(room_trash_remaining.get(key, room_total)), room_total)


func are_required_areas_clean(required_areas: Array[StringName], threshold: int = 95) -> bool:
	for room_id in required_areas:
		var total := int(room_trash_totals.get(String(room_id), 0))
		var remaining := int(room_trash_remaining.get(String(room_id), total))
		if total <= 0 or (total - remaining) * 100 < total * threshold:
			return false
	return true


func is_hammer_unlocked() -> bool:
	return are_required_areas_clean(HAMMER_REQUIRED_AREAS, 100)


func take_hammer() -> bool:
	if hammer_taken or not is_hammer_unlocked():
		return false
	hammer_taken = true
	set_vacuum_trigger_held(false)
	_save_progress()
	state_changed.emit()
	return true


func register_final_wall_hit(hit_point: Vector2 = Vector2(1.2, 0.0)) -> bool:
	if not hammer_taken or final_wall_open or not is_hammer_unlocked():
		return false
	final_wall_hit_points.append(Vector2(clampf(hit_point.x, 0.15, 2.65), clampf(hit_point.y, -2.75, 2.75)))
	final_wall_damage = mini(FINAL_WALL_HITS, final_wall_damage + 1)
	if final_wall_damage >= FINAL_WALL_HITS:
		final_wall_open = true
	_save_progress()
	final_wall_struck.emit(final_wall_damage)
	if final_wall_open:
		final_wall_opened.emit()
	state_changed.emit()
	return true


func unlock_lobby() -> void:
	if lobby_unlocked:
		return
	lobby_unlocked = true
	_save_progress()
	state_changed.emit()


func unlock_right_corridor() -> void:
	if right_corridor_unlocked:
		return
	right_corridor_unlocked = true
	_save_progress()
	state_changed.emit()


func is_room_activated(room_id: StringName) -> bool:
	return bool(activated_rooms.get(String(room_id), false))


func is_room_fully_clean(room_id: StringName) -> bool:
	var key := String(room_id)
	return int(room_trash_totals.get(key, 0)) > 0 and int(room_trash_remaining.get(key, -1)) == 0


func can_activate_room(room_id: StringName) -> bool:
	# An unbuilt room has no registered trash; the display helper returns 100%
	# for an empty total, but that must not unlock a future room's lever.
	return (
		room_id in STANDARD_MOVIE_ROOM_IDS
		and is_room_fully_clean(room_id)
		and not is_room_activated(room_id)
	)


func activate_room(room_id: StringName) -> bool:
	if not can_activate_room(room_id):
		return false
	activated_rooms[String(room_id)] = true
	_save_progress()
	room_activated.emit(room_id)
	state_changed.emit()
	return true


func is_movie_watched(room_id: StringName) -> bool:
	return bool(movie_watched_rooms.get(String(room_id), false))


func mark_movie_watched(room_id: StringName) -> bool:
	if not is_room_activated(room_id) or is_movie_watched(room_id):
		return false
	movie_watched_rooms[String(room_id)] = true
	_save_progress()
	movie_cycle_watched.emit(room_id)
	state_changed.emit()
	return true


func mark_arcade_discovered() -> void:
	if arcade_discovered:
		return
	arcade_discovered = true
	_save_progress()
	state_changed.emit()


func mark_second_arcade_discovered() -> void:
	if second_arcade_discovered:
		return
	second_arcade_discovered = true
	_save_progress()
	state_changed.emit()


func get_cinema_objectives() -> Array[Dictionary]:
	var objectives: Array[Dictionary] = []
	if not first_room_exit_seen:
		return objectives
	if arcade_discovered:
		var first_arcade_won := is_collectible_found(FIRST_ARCADE_HARD_POSTER_ID)
		objectives.append({"id": "arcade_found", "title": "¿Tienen consolas?", "description": "Supera Rescata el carrete en Difícil.", "progress": "Completado" if first_arcade_won else "Gana en Difícil", "completed": first_arcade_won, "hint": "La primera recreativa está en el pasillo derecho."})
	if second_arcade_discovered:
		var second_arcade_won := is_collectible_found(SECOND_ARCADE_HARD_POSTER_ID)
		objectives.append({"id": "arcade_second", "title": "¡¿Otra consola más?!", "description": "Supera El último acomodador en Difícil.", "progress": "Completado" if second_arcade_won else "Gana en Difícil", "completed": second_arcade_won, "hint": "La segunda recreativa está en el pasillo izquierdo."})
	objectives.append({
		"id": "movies_reactivated",
		"title": "Reactiva las películas %d/4" % _get_standard_movie_activation_count(),
		"description": "Las cuatro salas vuelven a proyectar películas.",
		"progress": "%d / 4" % _get_standard_movie_activation_count(),
		"completed": _get_standard_movie_activation_count() >= STANDARD_MOVIE_ROOM_IDS.size(),
		"hint": "Las palancas están en la sala del manager, al fondo del pasillo.",
	})
	var room_two_percent: float = get_room_clean_percent(&"room_02") if int(room_trash_totals.get("room_02", 0)) > 0 else 0.0
	objectives.append({"id":"room_03_clean","title":"Limpia la Sala 3","description":"La sala de acción está completamente limpia.","progress":"Progreso: %.2f %%" % get_room_clean_percent(&"room_03"),"completed":is_room_fully_clean(&"room_03"),"hint":""})
	objectives.append({
		"id": "room_02_clean",
		"title": "Limpia la Sala 2",
		"description": "La sala de romance está completamente limpia.",
		"progress": "Completado" if is_room_fully_clean(&"room_02") else "Progreso: %.2f %%" % room_two_percent,
		"completed": is_room_fully_clean(&"room_02"),
		"hint": "",
	})
	if lobby_unlocked:
		var lobby_percent: float = get_room_clean_percent(&"lobby") if int(room_trash_totals.get("lobby", 0)) > 0 else 0.0
		objectives.append({
			"id": "lobby_clean",
			"title": "Limpia el vestíbulo",
			"description": "Deja el centro del cine limpio para abrir el ala izquierda.",
			"progress": "Completado" if are_required_areas_clean([&"lobby"]) else "Progreso: %.2f %%" % lobby_percent,
			"completed": are_required_areas_clean([&"lobby"]),
			"hint": "",
		})
	if right_corridor_unlocked:
		var room_four_percent: float = get_room_clean_percent(&"room_04") if int(room_trash_totals.get("room_04", 0)) > 0 else 0.0
		objectives.append({
			"id": "room_04_clean",
			"title": "Limpia la Sala 4",
			"description": "Recoge la basura de la sala de miedo.",
			"progress": "Completado" if is_room_fully_clean(&"room_04") else "Progreso: %.2f %%" % room_four_percent,
			"completed": is_room_fully_clean(&"room_04"),
			"hint": "",
		})
	for index in STANDARD_MOVIE_ROOM_IDS.size():
		var room_id: StringName = STANDARD_MOVIE_ROOM_IDS[index]
		if is_room_activated(room_id):
			objectives.append({
				"id": "movie_watched_%s" % room_id,
				"title": "¿De qué será esta película?",
				"description": "Sala %d - Siéntate un rato y disfruta" % (index + 1),
				"progress": "Sala %d - %s" % [index + 1, "Completado" if is_movie_watched(room_id) else "Siéntate un rato y disfruta"],
				"completed": is_movie_watched(room_id),
				"hint": "",
			})
	return objectives


func _get_standard_movie_activation_count() -> int:
	var count := 0
	for room_id in STANDARD_MOVIE_ROOM_IDS:
		if is_room_activated(room_id):
			count += 1
	return count


func get_found_lost_item_count() -> int:
	return 0 if lost_item_state == "available" else 1


func get_total_lost_item_count() -> int:
	return ROOM_LOST_ITEM_TOTAL


func get_document_definitions(found_only: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in document_definitions:
		if not found_only or bool(definition.get("found", false)):
			result.append(definition.duplicate(true))
	return result


func get_document_definition(document_id: String) -> Dictionary:
	var definition := _document_definitions_by_id.get(document_id) as Dictionary
	return definition.duplicate(true) if definition != null else {}


func has_document_definition(document_id: String) -> bool:
	return _document_definitions_by_id.has(document_id)


func is_document_found(document_id: String) -> bool:
	return _found_document_ids.has(document_id)


func is_document_read(document_id: String) -> bool:
	return _read_document_ids.has(document_id)


func get_found_document_count() -> int:
	var count := 0
	for definition in document_definitions:
		if bool(definition.get("found", false)):
			count += 1
	return count


func get_total_document_count() -> int:
	return DocumentCatalog.EXPECTED_DOCUMENT_TOTAL


func collect_document(document_id: String, physical_document: Node = null) -> bool:
	if not has_document_definition(document_id):
		push_error("No se puede recoger el documento desconocido '%s'." % document_id)
		return false
	if is_document_found(document_id):
		return false
	_found_document_ids[document_id] = true
	_sync_document_definition_state(document_id)
	_save_progress()
	if physical_document != null and is_instance_valid(physical_document) and physical_document.has_method("collect"):
		physical_document.collect()
	document_pickup_audio.play()
	document_found.emit(document_id)
	discovery_found.emit(&"document", document_id, "Documento encontrado", "Pulsa Tab para verlo", &"documents")
	state_changed.emit()
	return true


func mark_document_read(document_id: String) -> bool:
	if not has_document_definition(document_id) or not is_document_found(document_id):
		return false
	var changed := not is_document_read(document_id) or last_selected_document_id != document_id
	_read_document_ids[document_id] = true
	last_selected_document_id = document_id
	_sync_document_definition_state(document_id)
	if changed:
		_save_progress()
		document_read.emit(document_id)
		state_changed.emit()
	return true


func _load_document_catalog() -> void:
	document_definitions = DocumentCatalog.load_definitions()
	_document_definitions_by_id.clear()
	for definition in document_definitions:
		var document_id := String(definition.get("id", ""))
		if _document_definitions_by_id.has(document_id):
			push_error("ID de documento duplicado '%s'; se conserva la primera definición." % document_id)
			continue
		_document_definitions_by_id[document_id] = definition


func _apply_document_progress() -> void:
	for document_id in _found_document_ids:
		if not has_document_definition(String(document_id)):
			push_warning("La partida contiene el documento encontrado '%s', pero su TXT ya no existe o fue renombrado." % document_id)
	for document_id in _read_document_ids:
		if not has_document_definition(String(document_id)):
			push_warning("La partida contiene el documento leído '%s', pero su TXT ya no existe o fue renombrado." % document_id)
	for definition in document_definitions:
		_sync_document_definition_state(String(definition.id))
	if not last_selected_document_id.is_empty() and not has_document_definition(last_selected_document_id):
		push_warning("El último documento seleccionado '%s' ya no existe o fue renombrado." % last_selected_document_id)
		last_selected_document_id = ""


func _sync_document_definition_state(document_id: String) -> void:
	var definition := _document_definitions_by_id.get(document_id) as Dictionary
	if definition == null:
		return
	definition["found"] = _found_document_ids.has(document_id)
	definition["read"] = _read_document_ids.has(document_id)


func get_collectible_definitions(found_only: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in collectible_definitions:
		if not found_only or bool(definition.get("found", false)):
			result.append(definition.duplicate(true))
	return result


func get_collectible_definition(collectible_id: String) -> Dictionary:
	var definition := _collectible_definitions_by_id.get(collectible_id) as Dictionary
	return definition.duplicate(true) if definition != null else {}


func has_collectible_definition(collectible_id: String) -> bool:
	return _collectible_definitions_by_id.has(collectible_id)


func is_collectible_found(collectible_id: String) -> bool:
	return _found_collectible_ids.has(collectible_id)


func is_collectible_viewed(collectible_id: String) -> bool:
	return _viewed_collectible_ids.has(collectible_id)


func get_found_collectible_count() -> int:
	var count := 0
	for definition in collectible_definitions:
		if bool(definition.get("found", false)):
			count += 1
	return count


func get_total_collectible_count() -> int:
	return CollectibleCatalog.TOTAL_SLOTS


func get_found_recording_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in RecordingCatalog.DEFINITIONS:
		if _found_recording_ids.has(String(definition.id)):
			result.append(definition.duplicate(true))
	return result


func is_recording_found(recording_id: String) -> bool:
	return _found_recording_ids.has(recording_id)


func is_recording_heard(recording_id: String) -> bool:
	return _heard_recording_ids.has(recording_id)


func discover_recording(recording_id: String) -> bool:
	if not RecordingCatalog.has_definition(recording_id) or is_recording_found(recording_id):
		return false
	_found_recording_ids[recording_id] = true
	_save_progress()
	recording_found.emit(recording_id)
	state_changed.emit()
	return true


func mark_recording_heard(recording_id: String) -> void:
	if not is_recording_found(recording_id) or is_recording_heard(recording_id):
		return
	_heard_recording_ids[recording_id] = true
	_save_progress()
	state_changed.emit()


func collect_collectible(
	collectible_id: String,
	physical_collectible: Node = null,
	discovery_title := "Figura encontrada",
	discovery_hint := "Pulsa Tab para verla"
) -> bool:
	if not has_collectible_definition(collectible_id):
		push_error("No se puede recoger la figura desconocida '%s'." % collectible_id)
		return false
	if is_collectible_found(collectible_id):
		return false
	_found_collectible_ids[collectible_id] = true
	_sync_collectible_definition_state(collectible_id)
	_save_progress()
	if physical_collectible != null and is_instance_valid(physical_collectible) and physical_collectible.has_method("collect"):
		physical_collectible.collect()
	collectible_found.emit(collectible_id)
	discovery_found.emit(&"collectible", collectible_id, discovery_title, discovery_hint, &"collectibles")
	state_changed.emit()
	return true


func mark_collectible_viewed(collectible_id: String) -> bool:
	if not has_collectible_definition(collectible_id) or not is_collectible_found(collectible_id):
		return false
	var changed := not is_collectible_viewed(collectible_id) or last_selected_collectible_id != collectible_id
	_viewed_collectible_ids[collectible_id] = true
	last_selected_collectible_id = collectible_id
	_sync_collectible_definition_state(collectible_id)
	if changed:
		_save_progress()
		collectible_viewed.emit(collectible_id)
		state_changed.emit()
	return true


func _load_collectible_catalog() -> void:
	collectible_definitions = CollectibleCatalog.get_definitions()
	_collectible_definitions_by_id.clear()
	var used_numbers: Dictionary = {}
	for definition in collectible_definitions:
		var collectible_id := String(definition.get("id", ""))
		var collectible_number := int(definition.get("number", 0))
		if collectible_id.is_empty() or collectible_number < 1 or collectible_number > CollectibleCatalog.TOTAL_SLOTS:
			push_error("Definición de figura inválida: %s" % definition)
			continue
		if _collectible_definitions_by_id.has(collectible_id):
			push_error("ID de figura duplicado '%s'; se conserva la primera definición." % collectible_id)
			continue
		if used_numbers.has(collectible_number):
			push_error("Número de figura duplicado '%d'; se conserva la primera definición." % collectible_number)
			continue
		_collectible_definitions_by_id[collectible_id] = definition
		used_numbers[collectible_number] = true


func _apply_collectible_progress() -> void:
	for collectible_id in _found_collectible_ids:
		if not has_collectible_definition(String(collectible_id)):
			push_warning("La partida contiene la figura encontrada '%s', pero su definición ya no existe o fue renombrada." % collectible_id)
	for collectible_id in _viewed_collectible_ids:
		if not has_collectible_definition(String(collectible_id)):
			push_warning("La partida contiene la figura vista '%s', pero su definición ya no existe o fue renombrada." % collectible_id)
	for definition in collectible_definitions:
		_sync_collectible_definition_state(String(definition.id))
	if not last_selected_collectible_id.is_empty() and not has_collectible_definition(last_selected_collectible_id):
		push_warning("La última figura seleccionada '%s' ya no existe o fue renombrada." % last_selected_collectible_id)
		last_selected_collectible_id = ""


func _sync_collectible_definition_state(collectible_id: String) -> void:
	var definition := _collectible_definitions_by_id.get(collectible_id) as Dictionary
	if definition == null:
		return
	definition["found"] = _found_collectible_ids.has(collectible_id)
	definition["viewed"] = _viewed_collectible_ids.has(collectible_id)


func collect_lost_item(item: Node) -> bool:
	if lost_item_state != "available" or item == null or item.definition == null: return false
	held_lost_items.append(String(item.definition.id))
	lost_item_state = "carried"
	item.collect()
	lost_item_collected.emit()
	_save_progress()
	state_changed.emit()
	return true


func destroy_lost_item(item: Node) -> bool:
	if lost_item_state != "available" or item == null or item.definition == null: return false
	coins -= int(item.definition.destruction_penalty)
	lost_item_state = "destroyed"
	item.collect()
	notification_requested.emit("Era un objeto perdido: -%d monedas." % int(item.definition.destruction_penalty))
	_save_progress()
	state_changed.emit()
	return true


func deposit_lost_items() -> bool:
	if lost_item_state != "carried" or held_lost_items.is_empty(): return false
	held_lost_items.clear()
	lost_item_state = "returned"
	coins += int(WATCH_DEFINITION.return_reward)
	_save_progress()
	state_changed.emit()
	return true


func get_upgrade_level(branch_id: StringName) -> int:
	return int(upgrade_levels.get(String(branch_id), 0))


func get_upgrade_state(branch_id: StringName) -> Dictionary:
	var state := UpgradeCatalog.get_branch(branch_id).duplicate(true)
	if state.is_empty():
		return state
	state["current_level"] = get_upgrade_level(branch_id)
	state["max_level"] = (state.get("costs", []) as Array).size()
	state["owned_tool_required"] = String(state.get("tool", ""))
	state["icon_path"] = "res://assets/ui/icons/upgrades/%s.svg" % String(state.get("icon", ""))
	return state


func has_upgrade(upgrade_id: StringName) -> bool:
	var id_text := String(upgrade_id)
	var parts := id_text.rsplit("_", true, 1)
	if parts.size() == 2 and parts[1].is_valid_int(): return get_upgrade_level(StringName(parts[0])) >= int(parts[1])
	return get_upgrade_level(upgrade_id) > 0


func can_purchase_upgrade(branch_id: StringName) -> bool:
	var branch := UpgradeCatalog.get_branch(branch_id)
	if branch.is_empty(): return false
	var tool_id := String(branch.get("tool", ""))
	if not tool_id.is_empty() and not owns_tool(StringName(tool_id)): return false
	var level := get_upgrade_level(branch_id)
	var costs: Array = branch.costs
	return level < costs.size() and coins >= int(costs[level])


func purchase_upgrade(branch_id: StringName) -> bool:
	var branch := UpgradeCatalog.get_branch(branch_id)
	if branch.is_empty(): return false
	var tool_id := String(branch.get("tool", ""))
	if not tool_id.is_empty() and not owns_tool(StringName(tool_id)):
		notification_requested.emit("Compra esta herramienta en la mesa del manager.")
		return false
	var level := get_upgrade_level(branch_id)
	var costs: Array = branch.costs
	if level >= costs.size():
		notification_requested.emit("Esta rama ya está al máximo.")
		return false
	var cost := int(costs[level])
	if coins < cost:
		notification_requested.emit("Necesitas %s monedas para esta mejora." % format_money(cost))
		return false
	coins -= cost
	upgrade_levels[String(branch_id)] = level + 1
	_apply_upgrades()
	notification_requested.emit("Mejora comprada: %s %s." % [branch.title, _roman(level + 1)])
	_save_progress()
	state_changed.emit()
	$UpgradePurchaseAudio.play()
	return true


func owns_tool(tool_id: StringName) -> bool:
	var key := _normalize_tool_id(tool_id)
	return UpgradeCatalog.TOOL_DEFINITIONS.has(key) and bool(purchased_tools.get(key, false))


func purchase_tool(tool_id: StringName) -> bool:
	var key := _normalize_tool_id(tool_id)
	if not UpgradeCatalog.TOOL_DEFINITIONS.has(key) or owns_tool(tool_id): return false
	var tool: Dictionary = UpgradeCatalog.TOOL_DEFINITIONS[key]
	var cost := int(tool.cost)
	if coins < cost:
		notification_requested.emit("Necesitas %s monedas para %s." % [format_money(cost), tool.title])
		return false
	coins -= cost
	purchased_tools[key] = true
	if key in ["vacuum", "broom"]:
		equipped_tool = key
		_vacuum_charge = vacuum_battery
		_vacuum_initialized = true
	notification_requested.emit("Herramienta comprada: %s." % tool.title)
	_save_progress()
	state_changed.emit()
	return true


func equip_tool(tool_id: StringName) -> bool:
	var key := _normalize_tool_id(tool_id)
	if key not in ["vacuum", "broom"] or not owns_tool(StringName(key)): return false
	stop_deposit()
	equipped_tool = key
	_vacuum_trigger_held = false
	_save_progress()
	state_changed.emit()
	return true


func cycle_hand_vacuum(direction: int = 1) -> bool:
	stop_deposit()
	var tools: Array[String] = [""]
	for tool_id in ["broom", "vacuum"]:
		if owns_tool(StringName(tool_id)):
			tools.append(tool_id)
	if tools.size() == 1:
		return false
	equipped_tool = tools[posmod(maxi(0, tools.find(equipped_tool)) + direction, tools.size())]
	_vacuum_trigger_held = false
	_save_progress()
	state_changed.emit()
	return true


func _normalize_tool_id(tool_id: StringName) -> String:
	return "vacuum" if tool_id == &"hand_vacuum" else String(tool_id)


func is_exit_unlocked() -> bool:
	# Unlocks use exact counts, independently of rounded HUD percentages.
	return total_trash > 0 and (total_trash-remaining_trash)*100 >= total_trash*95


func get_exit_requirement_text() -> String:
	return "Salida abierta" if is_exit_unlocked() else "Salida cerrada: falta limpieza 95 %"


func explain_exit_requirements() -> void:
	notification_requested.emit(get_exit_requirement_text())


func get_objective_text() -> String:
	if is_exit_unlocked(): return "Sala completada — atraviesa la puerta"
	if get_clean_percent() == 0: return "Limpia la sala · TAB abre el árbol de mejoras"
	if get_clean_percent() < 95: return "Objetivo: limpia al menos el 95 % · TAB mejoras"
	return "Objetivo completado — dirígete a la salida"


func _apply_upgrades() -> void:
	var previous_vacuum_capacity := vacuum_battery
	pickup_cooldown = _branch_value(&"quick_hands")
	bag_capacity = roundi(_branch_value(&"reinforced_bag"))
	manual_pickup_count = roundi(_branch_value(&"multi_pickup"))
	manual_reach = _branch_value(&"manual_reach")
	max_active_sacks = roundi(_branch_value(&"sealed_bags"))
	recycle_multiplier = roundi(_branch_value(&"recycle_value"))
	vacuum_reach = _branch_value(&"vacuum_reach")
	vacuum_battery = _branch_value(&"vacuum_battery")
	vacuum_recharge = _branch_value(&"vacuum_recharge")
	if not _vacuum_initialized:
		_vacuum_charge = vacuum_battery
		_vacuum_initialized = true
	elif vacuum_battery > previous_vacuum_capacity:
		_vacuum_charge = minf(vacuum_battery, _vacuum_charge + vacuum_battery - previous_vacuum_capacity)
	broom_interval = _branch_value(&"broom_speed")
	broom_width = _branch_value(&"broom_width")
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player:
		var sprint_level := get_upgrade_level(&"sprint")
		var sprint_branch := UpgradeCatalog.get_branch(&"sprint")
		player.configure_progression(
			sprint_level > 0,
			_branch_value(&"sprint"),
			UpgradeCatalog.get_secondary_value(sprint_branch, sprint_level),
			UpgradeCatalog.get_sprint_recharge_time(sprint_branch, sprint_level),
			manual_reach
		)


func set_vacuum_trigger_held(held: bool) -> void:
	_vacuum_trigger_held = held
	if not held and _vacuum_active:
		_vacuum_active = false
		vacuum_activity_changed.emit(false)
		_set_vacuum_audio_active(false)


func get_vacuum_state() -> Dictionary:
	return {
		"owned": owns_tool(&"vacuum"),
		"equipped": equipped_tool == "vacuum",
		"trigger_held": _vacuum_trigger_held,
		"active": _vacuum_active,
		"charge": _vacuum_charge,
		"maximum": vacuum_battery,
		"ratio": clampf(_vacuum_charge / maxf(vacuum_battery, 0.001), 0.0, 1.0),
	}


func _update_vacuum(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	var controls_available := (
		player != null
		and not player.is_game_intro_active()
		and not player.is_sitting()
		and not player._cinematic_locked
		and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless")
		and not get_tree().paused
	)
	var requested := (
		_vacuum_trigger_held
		and equipped_tool == "vacuum"
		and owns_tool(&"vacuum")
		and carried_sack.is_empty()
		and controls_available
	)
	var was_active := _vacuum_active
	_vacuum_active = requested and _vacuum_charge > 0.001
	if _vacuum_active:
		_vacuum_charge = maxf(0.0, _vacuum_charge - delta)
		_attract_with_vacuum(player, delta)
	elif not requested and owns_tool(&"vacuum"):
		_vacuum_charge = minf(vacuum_battery, _vacuum_charge + vacuum_recharge * delta)
	if was_active != _vacuum_active:
		vacuum_activity_changed.emit(_vacuum_active)
		_set_vacuum_audio_active(_vacuum_active)
	elif _vacuum_active and not vacuum_audio.playing and DisplayServer.get_name() != "headless":
		_set_vacuum_audio_active(true)


func _set_vacuum_audio_active(active: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if use_legacy_vacuum_audio:
		if active and not vacuum_audio.playing:
			vacuum_audio.play()
		elif not active and vacuum_audio.playing:
			vacuum_audio.stop()
		return
	if _vacuum_audio_fade != null and _vacuum_audio_fade.is_valid():
		_vacuum_audio_fade.kill()
	if active:
		vacuum_transition_audio.stop()
		vacuum_transition_audio.play()
		vacuum_audio.volume_db = VACUUM_LOOP_SILENT_DB
		vacuum_audio.play()
		_vacuum_audio_fade = create_tween()
		_vacuum_audio_fade.tween_property(vacuum_audio, "volume_db", VACUUM_LOOP_VOLUME_DB, 0.425).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		if vacuum_audio.playing:
			_vacuum_audio_fade = create_tween()
			_vacuum_audio_fade.tween_property(vacuum_audio, "volume_db", VACUUM_LOOP_SILENT_DB, 0.07)
			_vacuum_audio_fade.tween_callback(vacuum_audio.stop)
		vacuum_transition_audio.stop()
		vacuum_transition_audio.play() # El mismo start 01 recortado sirve de apagado, por elección del usuario.


func _attract_with_vacuum(player: PlayerController, delta: float) -> void:
	var camera := player.camera
	var forward := -camera.global_basis.z.normalized()
	var nozzle := camera.global_position + forward * 0.78 + Vector3.DOWN * 0.28
	# La aspiradora atrae hacia el jugador: la bolsa solo recibe el objeto cuando
	# este llega a su espacio de recogida, nunca al tocar la boquilla visual.
	var collection_point := camera.global_position + forward * 0.12 + Vector3.DOWN * 0.10
	var candidates: Array[Node3D] = []
	for candidate in get_tree().get_nodes_in_group("trash_item"):
		if not candidate is Node3D or not is_instance_valid(candidate):
			continue
		if candidate.has_method("is_being_collected") and candidate.is_being_collected():
			continue
		var offset: Vector3 = candidate.global_position - nozzle
		var distance := offset.length()
		if distance > vacuum_reach or distance <= 0.001:
			continue
		if offset.normalized().dot(forward) < VACUUM_CONE_DOT:
			continue
		# Los asientos tienen colisiones completas y pueden tapar un objeto que está
		# sobre o bajo ellos. Es basura accesible, así que no dejamos que esos asientos
		# corten la succión; para el resto se conserva la comprobación contra paredes.
		var seat_spawn := String(candidate.get_meta("spawn_zone", "")) in ["on_seat", "under_seat"]
		if not seat_spawn and not _has_vacuum_line_of_sight(player, nozzle, candidate):
			continue
		candidates.append(candidate)
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool: return nozzle.distance_squared_to(a.global_position) < nozzle.distance_squared_to(b.global_position))
	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var collection_distance := collection_point.distance_to(candidate.global_position)
		if collection_distance <= VACUUM_PLAYER_CAPTURE_DISTANCE and can_collect(candidate.definition):
			_begin_reserved_collection(candidate, player)
		elif candidate.has_method("apply_vacuum_pull"):
			candidate.apply_vacuum_pull(collection_point, VACUUM_PULL_ACCELERATION, delta)


func _has_vacuum_line_of_sight(player: PlayerController, origin: Vector3, item: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin, item.global_position + Vector3.UP * 0.04, 5)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	return collider == item or (collider != null and collider.get_parent() == item)


func try_use_active_ability(ability_index: int) -> bool:
	if ability_index < 0 or ability_index >= UpgradeCatalog.ACTIVE_ABILITIES.size():
		return false
	if get_tree().paused:
		return false
	var intro := get_tree().get_first_node_in_group("game_intro")
	if intro and intro.has_method("is_active") and intro.is_active():
		return false
	var upgrade_menu := get_tree().get_first_node_in_group("upgrade_menu")
	if upgrade_menu and upgrade_menu.has_method("is_open") and upgrade_menu.is_open():
		return false
	var definition: Dictionary = UpgradeCatalog.ACTIVE_ABILITIES[ability_index]
	var upgrade_id := StringName(definition.upgrade_id)
	if get_upgrade_level(upgrade_id) <= 0:
		return false
	match String(upgrade_id):
		"sealed_bags":
			return try_seal_full_bag()
		"all_seeing_eye":
			return _activate_all_seeing_eye()
	return false


func _activate_all_seeing_eye() -> bool:
	if get_ability_cooldown_remaining(&"all_seeing_eye") > 0.0:
		return false
	var level := get_upgrade_level(&"all_seeing_eye")
	var branch := UpgradeCatalog.get_branch(&"all_seeing_eye")
	if level <= 0 or branch.is_empty():
		return false
	_all_seeing_active_remaining = UpgradeCatalog.get_value(branch, level)
	_all_seeing_room_id = _get_player_room_id()
	ability_ready_at_unix["all_seeing_eye"] = (
		Time.get_unix_time_from_system()
		+ UpgradeCatalog.get_ability_cooldown(branch, level)
	)
	_set_all_seeing_reveal(true, _all_seeing_room_id)
	_save_progress()
	state_changed.emit()
	return true


func _set_all_seeing_reveal(revealed: bool, target_room_id: StringName = &"") -> void:
	get_dense_registry().reveal(target_room_id, revealed)
	for item in get_tree().get_nodes_in_group("trash_item"):
		if item.has_method("set_all_seeing_revealed"):
			var item_room_id: StringName = (
				StringName(item.get_room_id())
				if item.has_method("get_room_id")
				else StringName(item.get_meta("room_id", "room_01"))
			)
			item.set_all_seeing_revealed(revealed and item_room_id == target_room_id)


func _refresh_all_seeing_room() -> void:
	var current_room_id := _get_player_room_id()
	if current_room_id == _all_seeing_room_id:
		return
	_all_seeing_room_id = current_room_id
	_set_all_seeing_reveal(true, current_room_id)


func _on_player_room_changed(room_id: StringName) -> void:
	if _last_player_room_id == &"room_01" and room_id != &"room_01" and room_completed and not first_room_exit_seen:
		first_room_exit_seen = true
		_save_progress()
		state_changed.emit()
	_last_player_room_id = room_id
	if _all_seeing_active_remaining > 0.0:
		_refresh_all_seeing_room()


func _get_player_room_id() -> StringName:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_current_room_id"):
		return player.get_current_room_id()
	return &"room_01"


func get_ability_cooldown_remaining(ability_id: StringName) -> float:
	var ready_at := float(ability_ready_at_unix.get(String(ability_id), 0.0))
	return maxf(0.0, ready_at - Time.get_unix_time_from_system())


func get_active_ability_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ability_index in UpgradeCatalog.ACTIVE_ABILITIES.size():
		var definition: Dictionary = UpgradeCatalog.ACTIVE_ABILITIES[ability_index]
		var upgrade_id := StringName(definition.upgrade_id)
		if get_upgrade_level(upgrade_id) <= 0:
			continue
		var state := definition.duplicate(true)
		state["index"] = ability_index
		state["icon_path"] = "res://assets/models/source/general/upgrade_icons/%s" % (
			"upgrade_sealed_bags_gold.png"
			if upgrade_id == &"sealed_bags"
			else "upgrade_eye_all_trash.png"
		)
		if upgrade_id == &"sealed_bags":
			state["count"] = get_active_sack_count()
			state["maximum"] = max_active_sacks
		else:
			state["cooldown_remaining"] = get_ability_cooldown_remaining(upgrade_id)
			state["active_remaining"] = _all_seeing_active_remaining
		result.append(state)
	return result


func _branch_value(branch_id: StringName) -> float:
	var branch := UpgradeCatalog.get_branch(branch_id)
	return UpgradeCatalog.get_value(branch, get_upgrade_level(branch_id))


func _evaluate_room_completion() -> void:
	if room_completed or not is_exit_unlocked(): return
	room_completed = true
	notification_requested.emit("¡Sala completada! La puerta de salida está abierta.")
	_save_progress()
	state_changed.emit()


func _spawn_trash() -> void:
	_ensure_trash_layout_seed()
	var rng := RandomNumberGenerator.new()
	rng.seed = _trash_layout_seed
	var placements := _build_trash_placements(rng)
	var anchors: Array[Vector3] = []
	var large_anchors: Array[Vector3] = []
	for placement in placements:
		var position := trash_items.to_global(placement.position)
		anchors.append(position)
		if placement.zone != "on_seat": large_anchors.append(position)
	get_dense_registry().populate(&"room_01", anchors, large_anchors)


func get_dense_registry() -> Node3D:
	var existing := get_tree().get_first_node_in_group("dense_trash_registry") as Node3D
	if existing != null: return existing
	var registry := load("res://scripts/dense_trash_registry.gd").new() as Node3D
	registry.name = "DenseTrashRegistry"
	add_child(registry)
	return registry


func _ensure_trash_layout_seed() -> void:
	if _trash_layout_seed != 0:
		return
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()
	_trash_layout_seed = seed_rng.randi_range(1, 2147483646)


func _build_trash_definition_order(rng: RandomNumberGenerator) -> Array[Resource]:
	var definitions: Array[Resource] = []
	for index in ROOM_ONE_COIN_TRASH_COUNT:
		definitions.append(ONE_UNIT_DEFINITIONS[index % ONE_UNIT_DEFINITIONS.size()])
	for index in ROOM_TWO_COIN_TRASH_COUNT:
		definitions.append(TWO_UNIT_DEFINITIONS[index % TWO_UNIT_DEFINITIONS.size()])
	_shuffle_with_rng(definitions, rng)
	return definitions


func _build_trash_placements(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	var seats: Array = get_tree().get_nodes_in_group("phase_1_seat")
	seats.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name) < String(b.name))
	_shuffle_with_rng(seats, rng)

	for index in TRASH_ON_SEAT_COUNT:
		var seat := seats[index % seats.size()] as Node3D
		var world_position := seat.global_position + Vector3(
			rng.randf_range(-0.30, 0.30),
			rng.randf_range(1.34, 1.48),
			rng.randf_range(-0.16, 0.10)
		)
		placements.append({"position": trash_items.to_local(world_position), "zone": "on_seat"})

	for index in TRASH_UNDER_SEAT_COUNT:
		var seat := seats[(TRASH_ON_SEAT_COUNT + index) % seats.size()] as Node3D
		# Keep these pieces beneath the front lip, not trapped around the rear legs:
		# from the gap in front of the row they remain visible and targetable.
		var z := seat.global_position.z - rng.randf_range(0.42, 0.58)
		var x := seat.global_position.x + rng.randf_range(-0.28, 0.28)
		var world_position := Vector3(
			x,
			_get_trash_floor_height(Vector3(x, 0.0, z)) + rng.randf_range(0.16, 0.23),
			z
		)
		placements.append({"position": trash_items.to_local(world_position), "zone": "under_seat"})

	var between_rows: Array[Vector3] = []
	for row_index in SEAT_ROW_POSITIONS.size() - 1:
		var riser_z := (SEAT_ROW_POSITIONS[row_index] + SEAT_ROW_POSITIONS[row_index + 1]) * 0.5
		for column_x in SEAT_COLUMN_POSITIONS:
			between_rows.append(Vector3(column_x, 0.0, riser_z))
	_shuffle_with_rng(between_rows, rng)
	for index in TRASH_BETWEEN_ROWS_COUNT:
		var candidate := between_rows[index]
		# The midpoint between rows is also the vertical riser. Stay on either
		# tread with enough clearance for the longest flat prop, rather than
		# spawning directly across that edge where it can become half-hidden.
		var tread_side := -1.0 if rng.randi() % 2 == 0 else 1.0
		var z := candidate.z + tread_side * rng.randf_range(0.44, 0.60)
		var x := candidate.x + rng.randf_range(-0.32, 0.32)
		var position := Vector3(
			x,
			_get_trash_floor_height(Vector3(x, 0.0, z)) + rng.randf_range(0.16, 0.26),
			z
		)
		placements.append({"position": position, "zone": "between_rows"})

	var open_floor_anchors: Array[Vector3] = SPAWN_POSITIONS.duplicate()
	# The level rear landing is accessible from all three aisles. Keep these
	# behind the last stair, never in the empty space below its sloping hull.
	for rear_z in [12.90, 13.75]:
		for rear_x in [-10.05, -6.0, -2.0, 2.0, 6.0, 10.05]:
			open_floor_anchors.append(Vector3(rear_x, 0.0, rear_z))
	_shuffle_with_rng(open_floor_anchors, rng)
	for index in TRASH_OPEN_FLOOR_COUNT:
		var anchor := open_floor_anchors[index % open_floor_anchors.size()]
		var position := anchor + Vector3(
			rng.randf_range(-0.34, 0.34),
			0.0,
			rng.randf_range(-0.30, 0.30)
		)
		# The cinema speakers occupy the two front corners up to about z=-12.
		# Keep procedural jitter on the audience side of them so no item is
		# generated inside their large static colliders.
		if absf(position.x) > 6.55 and position.z < -10.75:
			position.z = -10.75 + rng.randf_range(0.0, 0.18)
		position.y = _get_trash_floor_height(position) + TRASH_DROP_HEIGHT + float(index / open_floor_anchors.size()) * 0.035
		placements.append({"position": position, "zone": "open_floor"})

	_shuffle_with_rng(placements, rng)
	return placements


func _make_trash_rotation(definition_id: String, occurrence: int, rng: RandomNumberGenerator) -> Vector3:
	var yaw := rng.randf_range(-PI, PI)
	if definition_id in ["ticket", "napkin", "straw", "popcorn"]:
		return Vector3(0.0, yaw, 0.0)
	var should_lie := (
		(definition_id == "bottle" and occurrence % 3 != 0)
		or (definition_id == "bucket" and occurrence % 4 == 0)
		or (definition_id == "cup" and occurrence % 4 == 0)
		or (definition_id == "can" and occurrence % 3 == 0)
	)
	if should_lie:
		var side := -1.0 if rng.randi() % 2 == 0 else 1.0
		var variation := deg_to_rad(rng.randf_range(-8.0, 8.0))
		return (
			Vector3(side * (PI * 0.5 + variation), yaw, rng.randf_range(-0.08, 0.08))
			if rng.randi() % 2 == 0
			else Vector3(rng.randf_range(-0.08, 0.08), yaw, side * (PI * 0.5 + variation))
		)
	return Vector3(rng.randf_range(-0.07, 0.07), yaw, rng.randf_range(-0.07, 0.07))


func _is_lying_rotation(item_rotation: Vector3) -> bool:
	return absf(item_rotation.x) > PI * 0.35 or absf(item_rotation.z) > PI * 0.35


func _shuffle_with_rng(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value


func _make_trash_non_blocking_for_player(item: PhysicsBody3D) -> void:
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if item and player:
		item.add_collision_exception_with(player)
		player.add_collision_exception_with(item)


func _update_trash_streaming() -> void:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player == null:
		return
	var focus := player.global_position
	var current_room: StringName = player.get_current_room_id()
	for node in get_tree().get_nodes_in_group("trash_item"):
		var item := node as RigidBody3D
		if item == null or item.is_queued_for_deletion() or item.is_being_collected():
			continue
		var distance_squared := item.global_position.distance_squared_to(focus)
		# Wake bodies before they enter the visible range, so they have time to
		# settle on the real floor before the player can interact with them.
		var should_simulate: bool = distance_squared <= TRASH_SIMULATE_DISTANCE_SQUARED and (item.room_id == current_room or distance_squared <= 14.0 * 14.0)
		if item.freeze == should_simulate:
			item.freeze = not should_simulate
		# The lobby already has its own 18 m visibility pass. Keep that pass
		# authoritative; other zones use a slightly longer shared draw range.
		if item.room_id == &"lobby":
			continue
		var should_show: bool = (distance_squared <= TRASH_VISIBLE_DISTANCE_SQUARED and (item.room_id == current_room or distance_squared <= 10.0 * 10.0)) or (_all_seeing_active_remaining > 0.0 and item.room_id == _all_seeing_room_id)
		if item.visible != should_show:
			item.visible = should_show


func _keep_trash_above_floor_batch() -> void:
	var child_count := trash_items.get_child_count()
	if child_count == 0:
		_trash_floor_guard_cursor = 0
		return
	var floor_height := Callable(self, "_get_trash_floor_height")
	var batch_size := mini(TRASH_FLOOR_GUARD_BATCH_SIZE, child_count)
	for _check_index in batch_size:
		_trash_floor_guard_cursor %= child_count
		var item := trash_items.get_child(_trash_floor_guard_cursor) as RigidBody3D
		_trash_floor_guard_cursor += 1
		if item == null or item.is_queued_for_deletion():
			continue
		if item.has_method("is_being_collected") and item.is_being_collected():
			continue
		var clearance := (
			float(item.get_min_floor_clearance(floor_height))
			if item.has_method("get_min_floor_clearance")
			else item.global_position.y - _get_trash_floor_height(item.global_position)
		)
		if clearance >= -TRASH_FLOOR_MIN_CLEARANCE:
			continue
		item.global_position.y += -clearance + TRASH_FLOOR_MIN_CLEARANCE
		item.linear_velocity = Vector3.ZERO
		item.angular_velocity = Vector3.ZERO
		item.sleeping = true


func _make_sack_non_blocking_for_player(sack: PhysicsBody3D) -> void:
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if sack and player:
		sack.add_collision_exception_with(player)
		player.add_collision_exception_with(sack)


func _get_trash_floor_height(sample) -> float:
	var x := 0.0
	var z := 0.0
	if sample is Vector3:
		x = sample.x
		z = sample.z
	else:
		z = float(sample)
	var ramp_height := 0.0
	if z >= 12.25:
		ramp_height = 0.0
	elif z >= TRASH_RAMP_REAR_Z:
		# The rear access steps descend to the level landing at z=12.25.
		ramp_height = lerpf(TRASH_RAMP_REAR_HEIGHT, 0.0, inverse_lerp(TRASH_RAMP_REAR_Z, 12.25, z))
	elif z > TRASH_RAMP_FRONT_Z:
		ramp_height = lerpf(0.0, TRASH_RAMP_REAR_HEIGHT, inverse_lerp(TRASH_RAMP_FRONT_Z, TRASH_RAMP_REAR_Z, z))
	if z >= 12.25:
		return 0.0
	if absf(x) < TRASH_SEATING_INNER_X or absf(x) > TRASH_SEATING_OUTER_X:
		return ramp_height
	return maxf(ramp_height, _get_visible_seat_tier_height(z))


func _get_visible_seat_tier_height(z: float) -> float:
	var tier_height := 0.0
	for row_index in range(1, SEAT_ROW_POSITIONS.size()):
		if z < SEAT_ROW_POSITIONS[row_index] - 1.0:
			break
		tier_height = float(row_index) * TRASH_SEAT_ROW_RISE
	return tier_height


func _spawn_lost_item_if_needed() -> void:
	if lost_item_state != "available": return
	var item := LOST_ITEM_SCENE.instantiate()
	item.name = "CheapWatch"
	item.definition = WATCH_DEFINITION
	item.position = Vector3(0.75, 0.16, -0.4)
	lost_items.add_child(item)


func _spawn_saved_sacks() -> void:
	for entry in _saved_sacks:
		if not entry is Dictionary: continue
		if bool(entry.get("delivered", false)): continue
		var sack := SEALED_BAG_SCENE.instantiate()
		sack.contained_units = int(entry.get("units", 0))
		sack.contained_base_value = int(entry.get("base_value", 0))
		sack.created_room_id = StringName(entry.get("created_room_id", "room_01"))
		sack.delivered = bool(entry.get("delivered", false))
		sealed_bags.add_child(sack)
		var p: Array = entry.get("position", [0.0, 0.4, 0.0])
		sack.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		call_deferred("_make_sack_non_blocking_for_player", sack)
	_saved_sacks.clear()


func _save_progress() -> void:
	_save_dirty = false
	_autosave_elapsed = 0.0
	var sacks: Array[Dictionary] = []
	for sack in sealed_bags.get_children():
		if sack.has_method("serialize") and not bool(sack.delivered): sacks.append(sack.serialize())
	var saved_wall_hits: Array = []
	for point in final_wall_hit_points:
		saved_wall_hits.append([point.x, point.y])
	var data := {
		"version": SAVE_VERSION,
		"coins": coins,
		"upgrade_levels": upgrade_levels,
		"purchased_tools": purchased_tools,
		"equipped_tool": equipped_tool,
		"room_completed": room_completed,
		"activated_rooms": _sorted_ids(activated_rooms),
		"movie_watched_rooms": _sorted_ids(movie_watched_rooms),
		"first_room_exit_seen": first_room_exit_seen,
		"arcade_discovered": arcade_discovered,
		"second_arcade_discovered": second_arcade_discovered,
		"lobby_unlocked": lobby_unlocked,
		"right_corridor_unlocked": right_corridor_unlocked,
		"hammer_taken": hammer_taken,
		"final_wall_damage": final_wall_damage,
		"final_wall_open": final_wall_open,
		"final_wall_hit_points": saved_wall_hits,
		"lost_item_state": lost_item_state,
		"held_lost_items": held_lost_items,
		"bag_units": bag_volume,
		"pending_base_value": _pending_base_value,
		"bag_contents": bag_contents,
		"legacy_bag_units": legacy_bag_units,
		"claimed_objective_rewards": claimed_objective_rewards,
		"moved_trash": moved_trash,
		"legacy_layout_pending": legacy_layout_pending,
		"legacy_layout_migrated": legacy_layout_migrated,
		"carried_sack": carried_sack,
		"sealed_sacks": sacks,
		"trash_layout_seed": _trash_layout_seed,
		"trash_layout_revision": Rules.TRASH_LAYOUT_REVISION,
		"documents_found": _sorted_ids(_found_document_ids),
		"documents_read": _sorted_ids(_read_document_ids),
		"last_selected_document_id": last_selected_document_id,
		"collectibles_found": _sorted_ids(_found_collectible_ids),
		"collectibles_viewed": _sorted_ids(_viewed_collectible_ids),
		"last_selected_collectible_id": last_selected_collectible_id,
		"recordings_found": _sorted_ids(_found_recording_ids),
		"recordings_heard": _sorted_ids(_heard_recording_ids),
		"ability_ready_at_unix": ability_ready_at_unix,
		"trash_bin_guidance_triggered": trash_bin_guidance_triggered,
		"trash_bin_guidance_completed": trash_bin_guidance_completed,
		"world_trash_collected": _sorted_ids(_collected_world_trash_ids),
	}
	var destination := _get_save_path()
	var file := FileAccess.open(destination + ".tmp", FileAccess.WRITE)
	if file == null:
		_save_dirty = true
		push_error("No se pudo guardar el progreso: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(destination+".tmp"), ProjectSettings.globalize_path(destination))
	if error != OK:
		_save_dirty = true
		push_error("No se pudo confirmar el guardado: %s" % error_string(error))


func _load_progress() -> void:
	loaded_save = false
	var save_path := _get_save_path()
	if not FileAccess.file_exists(save_path): return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null: return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return
	var version := int(parsed.get("version", 0))
	if version < 1 or version > SAVE_VERSION: return
	file.close()
	if version < 14:
		var backup_path := save_path + ".pre_incremental.bak"
		if not FileAccess.file_exists(backup_path):
			var backup_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(backup_path))
			if backup_error != OK:
				push_warning("No se pudo crear la copia previa a la migración: %s" % error_string(backup_error))
	legacy_layout_pending = version < 14 or bool(parsed.get("legacy_layout_pending", false))
	loaded_save = true
	coins = int(parsed.get("coins", 0))
	room_completed = bool(parsed.get("room_completed", false))
	lost_item_state = String(parsed.get("lost_item_state", "available"))
	for item_id in parsed.get("held_lost_items", []): held_lost_items.append(String(item_id))
	if version >= 2:
		upgrade_levels = parsed.get("upgrade_levels", {}).duplicate()
		purchased_tools = parsed.get("purchased_tools", {}).duplicate()
		equipped_tool = String(parsed.get("equipped_tool", ""))
		# Migrate saves from the retired grabber and from the period where Boti
		# could incorrectly occupy the hand-held equipment slot.
		purchased_tools.erase("grabber")
		upgrade_levels.erase("grabber_reach")
		upgrade_levels.erase("grabber_speed")
		upgrade_levels.erase("grabber_multi")
		if equipped_tool not in ["vacuum", "broom"]:
			equipped_tool = ""
		bag_volume = int(parsed.get("bag_units", 0))
		_pending_base_value = int(parsed.get("pending_base_value", 0))
		bag_contents = parsed.get("bag_contents", {}).duplicate()
		legacy_bag_units = int(parsed.get("legacy_bag_units", bag_volume if version < 14 else 0))
		claimed_objective_rewards = parsed.get("claimed_objective_rewards", {}).duplicate()
		moved_trash = parsed.get("moved_trash", {}).duplicate()
		if int(parsed.get("trash_layout_revision",0)) < Rules.TRASH_LAYOUT_REVISION:
			# Reposition only remaining trash from the old floating piles. Retired
			# IDs, bag contents, money and progression remain untouched.
			moved_trash.clear()
			_save_dirty = true
		legacy_layout_pending = version < 14 or bool(parsed.get("legacy_layout_pending", false))
		legacy_layout_migrated = parsed.get("legacy_layout_migrated", {}).duplicate()
		carried_sack = parsed.get("carried_sack", {}).duplicate()
		_saved_sacks = parsed.get("sealed_sacks", []).duplicate()
		_trash_layout_seed = int(parsed.get("trash_layout_seed", 0))
	if version >= 3:
		for document_id in parsed.get("documents_found", []):
			_found_document_ids[String(document_id)] = true
		for document_id in parsed.get("documents_read", []):
			_read_document_ids[String(document_id)] = true
		last_selected_document_id = String(parsed.get("last_selected_document_id", ""))
	if version >= 4:
		for collectible_id in parsed.get("collectibles_found", []):
			_found_collectible_ids[String(collectible_id)] = true
		for collectible_id in parsed.get("collectibles_viewed", []):
			_viewed_collectible_ids[String(collectible_id)] = true
		last_selected_collectible_id = String(parsed.get("last_selected_collectible_id", ""))
	if version >= 5:
		ability_ready_at_unix = parsed.get("ability_ready_at_unix", {}).duplicate()
	if version >= 6:
		trash_bin_guidance_triggered = bool(parsed.get("trash_bin_guidance_triggered", false))
		trash_bin_guidance_completed = bool(parsed.get("trash_bin_guidance_completed", false))
	if version >= 7:
		for world_item_id in parsed.get("world_trash_collected", []):
			_collected_world_trash_ids[String(world_item_id)] = true
	if version >= 8:
		for room_id in parsed.get("activated_rooms", []):
			if StringName(room_id) in CINEMA_ROOM_IDS:
				activated_rooms[String(room_id)] = true
	if version >= 9:
		first_room_exit_seen = bool(parsed.get("first_room_exit_seen", false))
		arcade_discovered = bool(parsed.get("arcade_discovered", false))
		second_arcade_discovered = bool(parsed.get("second_arcade_discovered", false))
		for room_id in parsed.get("movie_watched_rooms", []):
			if StringName(room_id) in CINEMA_ROOM_IDS:
				movie_watched_rooms[String(room_id)] = true
	if version >= 10:
		lobby_unlocked = bool(parsed.get("lobby_unlocked", false))
		right_corridor_unlocked = bool(parsed.get("right_corridor_unlocked", false))
	if version >= 11:
		for recording_id in parsed.get("recordings_found", []):
			if RecordingCatalog.has_definition(String(recording_id)):
				_found_recording_ids[String(recording_id)] = true
		for recording_id in parsed.get("recordings_heard", []):
			if _found_recording_ids.has(String(recording_id)):
				_heard_recording_ids[String(recording_id)] = true
	else:
		# Existing saves already passed the first intro, which previously had no
		# archive state. Expose 01 in the new archive without replaying it.
		_found_recording_ids["01"] = true
	if version >= 12:
		hammer_taken = bool(parsed.get("hammer_taken", false))
		final_wall_damage = clampi(int(parsed.get("final_wall_damage", 0)), 0, FINAL_WALL_HITS)
		final_wall_open = bool(parsed.get("final_wall_open", false))
		final_wall_hit_points.clear()
		if final_wall_open:
			hammer_taken = true
			final_wall_damage = FINAL_WALL_HITS
		if version >= 13:
			var saved_hits = parsed.get("final_wall_hit_points", [])
			if saved_hits is Array:
				for entry in saved_hits.slice(0, final_wall_damage):
					if entry is Array and entry.size() >= 2:
						final_wall_hit_points.append(Vector2(clampf(float(entry[0]), 0.15, 2.65), clampf(float(entry[1]), -2.75, 2.75)))
		# Version 12 stored only hit count; retain that progress with central craters.
		while final_wall_hit_points.size() < final_wall_damage:
			final_wall_hit_points.append(Vector2(1.2, 0.0))
	if version < 14:
		_legacy_reward_baseline = true
		var refund := 1600 if bool(purchased_tools.get("boti", false)) else 0
		for branch in UpgradeCatalog.LEGACY_BRANCHES:
			if String(branch.id).begins_with("boti_"):
				var paid_levels := clampi(int(upgrade_levels.get(branch.id, 0)), 0, branch.costs.size())
				for i in paid_levels:
					refund += int(branch.costs[i])
				upgrade_levels.erase(branch.id)
		if bool(purchased_tools.get("boti", false)):
			purchased_tools["broom"] = true
			refund -= 150
		purchased_tools.erase("boti")
		coins += refund
		_save_dirty = true


func _check_monetary_objectives() -> void:
	var completed := {"room_01_clean":room_completed, "documents_found":get_found_document_count() >= 12,
		"collectibles_found":get_total_collectible_count() > 0 and get_found_collectible_count() >= get_total_collectible_count()}
	for objective in get_cinema_objectives():
		completed[String(objective.id)] = bool(objective.completed)
	var paid := 0
	for objective_id in completed:
		if not bool(completed[objective_id]) or claimed_objective_rewards.has(objective_id):
			continue
		claimed_objective_rewards[objective_id] = true
		_save_dirty = true
		if not _legacy_reward_baseline:
			paid += int(Rules.OBJECTIVE_REWARDS.get(objective_id, 0))
	_legacy_reward_baseline = false
	if paid > 0:
		coins += paid
		coin_rewarded.emit(paid, _get_trash_bin_position())
		notification_requested.emit("Objetivo completado: +%s monedas" % format_money(paid))
		_save_progress()
		state_changed.emit()


func sweep_with_broom() -> bool:
	if equipped_tool != "broom" or not owns_tool(&"broom") or _broom_cooldown > 0.0:
		return false
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player == null or not player.is_cleaning_input_allowed():
		return false
	_broom_cooldown = broom_interval
	var forward := -player.global_basis.z
	var center := player.global_position + forward * 0.95
	var registry := get_tree().get_first_node_in_group("dense_trash_registry")
	if registry != null:
		registry.sweep(center, forward, broom_width, player)
	if DisplayServer.get_name() != "headless" and has_node("BroomSweepAudio"):
		$BroomSweepAudio.play()
	broom_swept.emit()
	return true


func _exit_tree() -> void:
	if _save_dirty and is_instance_valid(sealed_bags):
		_save_progress()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_node_ready():
		stop_deposit()
		if _save_dirty: _save_progress()


func _get_save_path() -> String:
	var test_override := OS.get_environment("CINEMA_CLEANER_TEST_SAVE_PATH")
	return test_override if not test_override.is_empty() else SAVE_PATH


func _sorted_ids(id_set: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for document_id in id_set:
		result.append(String(document_id))
	result.sort()
	return result


func _roman(level: int) -> String:
	return ["", "I", "II", "III", "IV", "V"][clampi(level, 0, 5)]


func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(stream.mix_rate * duration)
	var audio_data := PackedByteArray()
	audio_data.resize(sample_count)
	for sample_index in sample_count:
		var time := float(sample_index) / float(stream.mix_rate)
		var envelope := 1.0 - float(sample_index) / float(sample_count)
		var sample := 128.0 + sin(TAU * frequency * time) * 36.0 * envelope
		audio_data[sample_index] = clampi(roundi(sample), 0, 255)
	stream.data = audio_data
	return stream


func _make_reject_tone() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.11
	var sample_count := int(stream.mix_rate * duration)
	var audio_data := PackedByteArray()
	audio_data.resize(sample_count)
	for sample_index in sample_count:
		var progress := float(sample_index) / float(sample_count)
		var frequency := lerpf(165.0, 92.0, progress)
		var envelope := pow(1.0 - progress, 1.7)
		var sample := 128.0 + sin(TAU * frequency * duration * progress) * 27.0 * envelope
		audio_data[sample_index] = clampi(roundi(sample), 0, 255)
	stream.data = audio_data
	return stream


func _make_vacuum_wind() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(stream.mix_rate * 0.75)
	var audio_data := PackedByteArray()
	audio_data.resize(sample_count)
	var random := RandomNumberGenerator.new()
	random.seed = 0xC1E5
	var filtered_noise := 0.0
	for sample_index in sample_count:
		filtered_noise = lerpf(filtered_noise, random.randf_range(-1.0, 1.0), 0.18)
		var time := float(sample_index) / float(stream.mix_rate)
		var motor := sin(TAU * 84.0 * time) * 0.16 + sin(TAU * 168.0 * time) * 0.08
		var sample := 128.0 + (filtered_noise * 0.72 + motor) * 39.0
		audio_data[sample_index] = clampi(roundi(sample), 0, 255)
	stream.data = audio_data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
