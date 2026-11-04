extends CanvasLayer

const HUD_FONT := preload("res://assets/fonts/PalaceHUD-Bold.ttf")
const COIN_ICON := preload("res://assets/gptphoto_models/IconoMoneda.png")
const RETICLE_DEFAULT := preload("res://assets/models/source/general/pointers/reticle_default.png")
const RETICLE_BAG_FULL := preload("res://assets/models/source/general/pointers/reticle_bag_full.png")
const SEALED_BAGS_ABILITY_ICON := preload("res://assets/models/source/general/upgrade_icons/upgrade_sealed_bags_gold.png")
const ALL_SEEING_EYE_ABILITY_ICON := preload("res://assets/models/source/general/upgrade_icons/upgrade_eye_all_trash.png")
const JOURNAL_ICON := preload("res://assets/models/source/general/upgrade_icons/icon_objectives.png")
const OBJECTIVE_STAMP := preload("res://assets/ui/icons/popcorn_stamp.svg")
@export var objective_complete_sound: AudioStream
@export var objective_new_sound: AudioStream
const VACUUM_MODEL := preload("res://assets/models/source/tools/aspiradora.glb")
const GENERAL_ICON_DIR := "res://assets/models/source/general"
const GENERAL_ICONS := {
	"trash": preload("res://assets/models/source/general/bolsa_icono.png"),
	"lost": preload("res://assets/models/source/general/objetosPerdidos_icono.png"),
	"hand": preload("res://assets/models/source/general/mano_icono.png"),
	"broom": preload("res://assets/pipeline/ui/icons/broom_inventory.png"),
	"vacuum": preload("res://assets/models/source/general/aspiradora_icono.png"),
}
const FALLBACK_ICON_PATHS := {
	"trash": "res://assets/ui/icons/upgrades/reinforced_bag.svg",
	"lost": "res://assets/ui/icons/upgrades/manual_reach.svg",
	"hand": "res://assets/ui/icons/upgrades/quick_hands.svg",
	"vacuum": "res://assets/ui/icons/upgrades/vacuum.svg",
	"broom": "res://assets/ui/icons/upgrades/broom.svg",
}
const CREAM := Color("f7e6bd")
const GOLD := Color("f3bd4c")
const GREEN := Color("69cc86")
const WINE := Color("6f2730")
const DARK := Color(0.055, 0.045, 0.043, 0.92)
const SPRINT_EMPTY := Color("50131d")
const HUD_LAYOUT_TWEEN_DURATION := 0.34
const TOOLS_NORMAL_POSITION := Vector2(-330, -250)
const TOOLS_RECORDING_POSITION := Vector2(-330, -342)
const BATTERY_NORMAL_POSITION := Vector2(-156, -72)
const BATTERY_RECORDING_POSITION := Vector2(-156, -164)
const SPRINT_NORMAL_POSITION := Vector2(-220, -64)
const SPRINT_RECORDING_POSITION := Vector2(-220, -184)
const PROMPT_NORMAL_POSITION := Vector2(-420, -360)
const PROMPT_RECORDING_POSITION := Vector2(-420, -420)
# First-person vacuum presentation. The GLB's long axis is local +X, so the
# correction maps it to camera-forward (-Z) before the pose is applied.
const VACUUM_VIEW_CAMERA_FOV := 42.0
const VACUUM_VIEWMODEL_SCALE := 2.05
const VACUUM_VIEWMODEL_AXIS_CORRECTION := Vector3(0.0, -90.0, 0.0)
const VACUUM_VIEWMODEL_IDLE_POSITION := Vector3(0.82, -0.92, -2.28)
const VACUUM_VIEWMODEL_IDLE_ROTATION := Vector3(18.0, 24.0, -7.0)
const VACUUM_VIEWMODEL_USE_POSITION := Vector3(0.74, -0.82, -2.24)
const VACUUM_VIEWMODEL_USE_ROTATION := Vector3(12.0, 27.0, -7.0)
const VACUUM_VIEWMODEL_POSE_SPEED := 10.0
const VACUUM_WALK_SWAY := Vector2(0.028, 0.022)
const VACUUM_SPRINT_SWAY := Vector2(0.045, 0.038)
const VACUUM_FOLLOW_PHASE_MULTIPLIER := 0.55
const VACUUM_FOLLOW_SMOOTHING := 4.1
const VACUUM_ACTIVE_WOBBLE_POSITION := Vector2(0.009, 0.006)
const VACUUM_ACTIVE_WOBBLE_ROTATION := Vector2(0.45, 0.65)

var _prompt_label: Label
var _crosshair: TextureRect
var _bag_label: Label
var _trash_counter_icon: Control
var _trash_icon_fill_mask: Control
var _trash_capacity_label: Label
var _lost_counter_icon: TextureRect
var _coins_label: Label
var _clean_label: Label
var _clean_bar: ProgressBar
var _room_title: Label
var _lost_item_label: Label
var _notice_label: Label
var _tool_slots: Control
var _vacuum_battery_gauge: Control
var _vacuum_battery_bar: ProgressBar
var _vacuum_view_container: SubViewportContainer
var _vacuum_viewport: SubViewport
var _vacuum_view_root: Node3D
var _vacuum_nozzle_anchor: Node3D
var _vacuum_wind_root: Node3D
var _vacuum_wind_streaks: Array[MeshInstance3D] = []
var _vacuum_use_pose_blend := 0.0
var _vacuum_motion_offset := Vector3.ZERO
var _coin_panel: PanelContainer
var _coin_icon: TextureRect
var _coin_flight_layer: Control
var _coin_canvas: CanvasLayer
var _carried_sack_view: TextureRect
var _ability_stack: VBoxContainer
var _ability_cards: Dictionary = {}
var _ability_signature := ""
var _journal_shortcut: Control
var _manager: Node
var _player: Node
var _sprint_bar: ProgressBar
var _recording_layout_active := false
var _recording_layout_tween: Tween
var _sprint_hide_delay := 0.0
var _notice_generation := 0
var _displayed_coins := 0
var _coin_animation_active := false
var _coin_reward_queue: Array[Dictionary] = []
var _unsettled_reward_coins := 0
var _deposit_pending_coins := 0
var _deposit_idle_time := 0.0
var _deposit_reward_popup: Control
var _general_icon_cache: Dictionary = {}
var _pending_trash_icon_pulses := 0
var _trash_icon_pulse_running := false
var _pending_lost_icon_pulses := 0
var _lost_icon_pulse_running := false
var _tool_slots_signature := ""
var _crosshair_reject_tween: Tween
var _hud_root_control: Control
var _objective_panel: PanelContainer
var _objective_caption: Label
var _objective_title: Label
var _objective_description: Label
var _objective_tab_hint: Label
var _objective_slot: PanelContainer
var _objective_stamp: TextureRect
var _objective_sound: AudioStreamPlayer
var _objective_new_sound: AudioStreamPlayer
var _objective_states: Dictionary = {}
var _objective_states_initialized := false
var _objective_queue: Array[Dictionary] = []
var _collectible_completed_objective_silences: Dictionary = {}
var _objective_toast_active := false
var _objective_toast_kind: StringName = &""
var _objective_tween: Tween


func _ready() -> void:
	add_to_group("gameplay_hud")
	_build_ui()
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	_player = get_tree().get_first_node_in_group("player")
	if _manager:
		_manager.state_changed.connect(_update_state)
		_manager.notification_requested.connect(_show_notification)
		_manager.coin_rewarded.connect(_queue_coin_reward)
		_manager.trash_deposited.connect(_queue_deposit_reward)
		_manager.trash_collected.connect(_queue_trash_icon_pulse)
		_manager.lost_item_collected.connect(_queue_lost_icon_pulse)
		_manager.pickup_rejected.connect(_play_pickup_rejected_feedback)
		_manager.collectible_found.connect(_play_collectible_reward_sound)
		_displayed_coins = _manager.coins
		_update_state()
		# Authored rooms register their saved trash counts with deferred calls.
		# Snapshot objectives only after those calls, or Continue replays wins.
		call_deferred("_initialize_objective_states")
	if _player:
		_player.interaction_prompt_changed.connect(_set_prompt)
		if _player.has_signal("room_changed"):
			_player.room_changed.connect(_on_room_changed)


func _process(delta: float) -> void:
	_update_deposit_reward(delta)
	_update_sprint_bar(delta)
	_update_active_ability_hud()
	_update_vacuum_hud(delta)
	if not _objective_toast_active and not _objective_queue.is_empty():
		_show_next_objective_toast()


func _build_ui() -> void:
	_hud_root_control = Control.new()
	_hud_root_control.name = "HUDRoot"
	_hud_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hud_root_control)

	_build_room_progress(_hud_root_control)
	_build_bag_status(_hud_root_control)
	_build_tool_status(_hud_root_control)
	_build_vacuum_view(_hud_root_control)
	var broom_view := load("res://scripts/broom_viewmodel.gd").new() as Control
	_hud_root_control.add_child(broom_view)
	_hud_root_control.move_child(broom_view, 0)
	_build_carried_sack_view(_hud_root_control)
	_build_sprint_status(_hud_root_control)
	_build_crosshair_and_messages(_hud_root_control)
	_build_objective_toast(_hud_root_control)

	_coin_canvas = CanvasLayer.new()
	_coin_canvas.name = "CoinCanvas"
	_coin_canvas.layer = 11
	add_child(_coin_canvas)
	var coin_root := Control.new()
	coin_root.name = "CoinRoot"
	coin_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coin_canvas.add_child(coin_root)
	_build_coin_counter(coin_root)
	_build_journal_shortcut(coin_root)
	_build_active_ability_status(coin_root)
	_coin_flight_layer = Control.new()
	_coin_flight_layer.name = "CoinFlights"
	_coin_flight_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coin_root.add_child(_coin_flight_layer)
	_set_mouse_passthrough(_hud_root_control)
	_set_mouse_passthrough(coin_root)


func set_gameplay_hud_visible(should_show: bool) -> void:
	if _hud_root_control:
		_hud_root_control.visible = should_show
	if _coin_canvas:
		_coin_canvas.visible = should_show


func is_gameplay_hud_visible() -> bool:
	return _hud_root_control != null and _hud_root_control.visible


func set_recording_layout_active(active: bool, animate: bool = true) -> void:
	if _recording_layout_active == active:
		return
	_recording_layout_active = active
	if _recording_layout_tween != null and _recording_layout_tween.is_valid():
		_recording_layout_tween.kill()
	var tools_target := TOOLS_RECORDING_POSITION if active else TOOLS_NORMAL_POSITION
	var battery_target := BATTERY_RECORDING_POSITION if active else BATTERY_NORMAL_POSITION
	var sprint_target := SPRINT_RECORDING_POSITION if active else SPRINT_NORMAL_POSITION
	var prompt_target := PROMPT_RECORDING_POSITION if active else PROMPT_NORMAL_POSITION
	if not animate:
		_set_bottom_anchored_top(_tool_slots, tools_target.y)
		_set_bottom_anchored_top(_vacuum_battery_gauge, battery_target.y)
		_set_bottom_anchored_top(_sprint_bar, sprint_target.y)
		_set_bottom_anchored_top(_prompt_label, prompt_target.y)
		return
	_recording_layout_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_bottom_anchored_top(_tool_slots, tools_target.y)
	_tween_bottom_anchored_top(_vacuum_battery_gauge, battery_target.y)
	_tween_bottom_anchored_top(_sprint_bar, sprint_target.y)
	_tween_bottom_anchored_top(_prompt_label, prompt_target.y)


func _set_bottom_anchored_top(control: Control, top_offset: float) -> void:
	var height := control.size.y
	control.offset_top = top_offset
	control.offset_bottom = top_offset + height


func _tween_bottom_anchored_top(control: Control, top_offset: float) -> void:
	var height := control.size.y
	_recording_layout_tween.tween_property(control, "offset_top", top_offset, HUD_LAYOUT_TWEEN_DURATION)
	_recording_layout_tween.tween_property(control, "offset_bottom", top_offset + height, HUD_LAYOUT_TWEEN_DURATION)


func set_coin_overlay_above_menu(enabled: bool) -> void:
	if _coin_canvas:
		_coin_canvas.layer = 31 if enabled else 11


func _build_room_progress(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "RoomProgress"
	panel.position = Vector2(18, 16)
	panel.size = Vector2(395, 84)
	panel.add_theme_stylebox_override("panel", _panel_style(DARK, Color("5b3933"), 13, 3))
	root.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "ContentMargins"
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.name = "ContentStack"
	stack.add_theme_constant_override("separation", 0)
	margin.add_child(stack)
	_room_title = _make_label(22, CREAM)
	_room_title.text = "SALA 1 — TUTORIAL"
	stack.add_child(_room_title)
	var progress_row := HBoxContainer.new()
	progress_row.name = "ProgressRow"
	progress_row.add_theme_constant_override("separation", 8)
	stack.add_child(progress_row)
	_clean_bar = ProgressBar.new()
	_clean_bar.name = "CleanProgress"
	_clean_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clean_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clean_bar.custom_minimum_size = Vector2(270, 20)
	_clean_bar.show_percentage = false
	_clean_bar.add_theme_stylebox_override("background", _panel_style(Color("302a2e"), Color.TRANSPARENT, 6, 0))
	_clean_bar.add_theme_stylebox_override("fill", _panel_style(GREEN, Color.TRANSPARENT, 6, 0))
	progress_row.add_child(_clean_bar)
	_clean_label = _make_label(30, GREEN)
	_clean_label.custom_minimum_size.x = 82
	_clean_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clean_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clean_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_row.add_child(_clean_label)


func _build_coin_counter(root: Control) -> void:
	_coin_panel = PanelContainer.new()
	_coin_panel.name = "CoinCounterCard"
	_coin_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coin_panel.position = Vector2(-250, 62)
	_coin_panel.size = Vector2(230, 84)
	_coin_panel.add_theme_stylebox_override("panel", _panel_style(DARK, Color("5b3933"), 12, 3))
	root.add_child(_coin_panel)
	var margin := MarginContainer.new()
	margin.name = "ContentMargins"
	_set_margins(margin, 12, 8)
	_coin_panel.add_child(margin)
	var coin_row := HBoxContainer.new()
	coin_row.name = "CoinRow"
	coin_row.add_theme_constant_override("separation", 10)
	margin.add_child(coin_row)
	_coin_icon = TextureRect.new()
	_coin_icon.name = "CoinIcon"
	_coin_icon.custom_minimum_size = Vector2(54, 54)
	_coin_icon.texture = COIN_ICON
	_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(_coin_icon)
	_coins_label = _make_label(43, CREAM)
	_coins_label.name = "Coins"
	_coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_row.add_child(_coins_label)
	_deposit_reward_popup=_make_coin_reward_popup(0)
	_deposit_reward_popup.name="DepositRewardPending"
	_deposit_reward_popup.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_deposit_reward_popup.position=Vector2(-174,2)
	root.add_child(_deposit_reward_popup)
	_deposit_reward_popup.hide()


func _build_active_ability_status(root: Control) -> void:
	_ability_stack = VBoxContainer.new()
	_ability_stack.name = "ActiveAbilities"
	_ability_stack.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_ability_stack.position = Vector2(-250, 246)
	_ability_stack.size = Vector2(230, 190)
	_ability_stack.add_theme_constant_override("separation", 8)
	root.add_child(_ability_stack)


func _rebuild_active_ability_cards(states: Array[Dictionary]) -> void:
	_clear_children(_ability_stack)
	_ability_cards.clear()
	for state in states:
		var ability_id := String(state.upgrade_id)
		var card := PanelContainer.new()
		card.name = "Ability_%s" % ability_id.to_pascal_case()
		card.custom_minimum_size = Vector2(230, 82)
		card.add_theme_stylebox_override("panel", _panel_style(DARK, Color("5b3933"), 11, 3))
		_ability_stack.add_child(card)
		var content := Control.new()
		content.custom_minimum_size = Vector2(230, 82)
		card.add_child(content)

		var key_panel := PanelContainer.new()
		key_panel.name = "KeyBadge"
		key_panel.position = Vector2(8, 19)
		key_panel.size = Vector2(40, 44)
		key_panel.add_theme_stylebox_override("panel", _panel_style(Color("211b1e"), GOLD, 7, 2))
		content.add_child(key_panel)
		var key_label := _make_label(27, CREAM, 4)
		key_label.text = String(state.key)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_panel.add_child(key_label)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.position = Vector2(54, 9)
		icon.size = Vector2(64, 64)
		icon.texture = (
			SEALED_BAGS_ABILITY_ICON
			if ability_id == "sealed_bags"
			else ALL_SEEING_EYE_ABILITY_ICON
		)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(icon)

		var status := _make_label(24, CREAM, 4)
		status.name = "Status"
		status.position = Vector2(120, 12)
		status.size = Vector2(100, 58)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		content.add_child(status)
		_ability_cards[ability_id] = {"card": card, "status": status}
	_set_mouse_passthrough(_ability_stack)


func _update_active_ability_hud() -> void:
	if _manager == null or _ability_stack == null or not _manager.has_method("get_active_ability_states"):
		return
	var states: Array[Dictionary] = _manager.get_active_ability_states()
	var ids: Array[String] = []
	for state in states:
		ids.append(String(state.upgrade_id))
	var signature := "|".join(ids)
	if signature != _ability_signature:
		_ability_signature = signature
		_rebuild_active_ability_cards(states)
	for state in states:
		var ability_id := String(state.upgrade_id)
		if not _ability_cards.has(ability_id):
			continue
		var widgets: Dictionary = _ability_cards[ability_id]
		var status := widgets.status as Label
		var card := widgets.card as PanelContainer
		var active := false
		if ability_id == "sealed_bags":
			status.text = "%d / %d" % [int(state.count), int(state.maximum)]
		else:
			var cooldown := float(state.get("cooldown_remaining", 0.0))
			active = float(state.get("active_remaining", 0.0)) > 0.0
			status.text = _format_hud_cooldown(cooldown) if cooldown > 0.0 else "LISTO"
		card.add_theme_stylebox_override("panel", _panel_style(DARK, GOLD if active else Color("5b3933"), 11, 4 if active else 3))


func _format_hud_cooldown(seconds: float) -> String:
	var rounded := maxi(1, ceili(seconds))
	if rounded >= 60:
		return "%dm %02ds" % [rounded / 60, rounded % 60]
	return "%ds" % rounded


func _build_journal_shortcut(root: Control) -> void:
	_journal_shortcut = Control.new()
	_journal_shortcut.name = "JournalShortcut"
	_journal_shortcut.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_journal_shortcut.position = Vector2(-250, 154)
	_journal_shortcut.size = Vector2(230, 82)
	root.add_child(_journal_shortcut)
	var content := Control.new()
	content.name = "Content"
	content.custom_minimum_size = Vector2(230, 82)
	_journal_shortcut.add_child(content)
	var icon := TextureRect.new()
	icon.name = "JournalIcon"
	icon.position = Vector2(74, 0)
	icon.size = Vector2(82, 82)
	icon.texture = JOURNAL_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)
	var tab_badge := PanelContainer.new()
	tab_badge.name = "TabBadge"
	tab_badge.position = Vector2(137, 51)
	tab_badge.size = Vector2(76, 29)
	tab_badge.add_theme_stylebox_override("panel", _panel_style(Color("211b1e"), GOLD, 6, 2))
	content.add_child(tab_badge)
	var tab_label := _make_label(17, CREAM, 3)
	tab_label.text = "TAB"
	tab_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tab_badge.add_child(tab_label)
	_set_mouse_passthrough(_journal_shortcut)


func _build_bag_status(root: Control) -> void:
	var counters := VBoxContainer.new()
	counters.name = "InventoryCounters"
	counters.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Keep the bottom edge in place while making both cards taller and more compact.
	counters.position = Vector2(28, -246)
	counters.size = Vector2(250, 188)
	counters.add_theme_constant_override("separation", 8)
	root.add_child(counters)
	var trash_card := _make_trash_counter()
	counters.add_child(trash_card)
	_bag_label = trash_card.get_node("ContentMargins/CounterRow/Value") as Label
	_trash_counter_icon = trash_card.get_node("ContentMargins/CounterRow/Icon") as Control
	var lost_card := _make_inventory_counter("LostItemCounter", _get_general_icon("lost"))
	counters.add_child(lost_card)
	_lost_item_label = lost_card.get_node("ContentMargins/CounterRow/Value") as Label
	_lost_counter_icon = lost_card.get_node("ContentMargins/CounterRow/Icon") as TextureRect


func _make_trash_counter() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "TrashCounter"
	card.custom_minimum_size = Vector2(250, 90)
	card.add_theme_stylebox_override("panel", _panel_style(DARK, Color("5b3933"), 11, 3))
	var margin := MarginContainer.new()
	margin.name = "ContentMargins"
	_set_margins(margin, 11, 7)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.name = "CounterRow"
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_trash_counter_icon = Control.new()
	_trash_counter_icon.name = "Icon"
	_trash_counter_icon.custom_minimum_size = Vector2(70, 70)
	row.add_child(_trash_counter_icon)
	var empty_icon := TextureRect.new()
	empty_icon.name = "EmptyIcon"
	empty_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_icon.texture = _get_general_icon("trash")
	empty_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	empty_icon.modulate = Color(0.72, 0.66, 0.60, 0.36)
	_trash_counter_icon.add_child(empty_icon)
	_trash_icon_fill_mask = Control.new()
	_trash_icon_fill_mask.name = "FillMask"
	_trash_icon_fill_mask.clip_contents = true
	_trash_icon_fill_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trash_counter_icon.add_child(_trash_icon_fill_mask)
	var filled_icon := TextureRect.new()
	filled_icon.name = "FilledIcon"
	filled_icon.texture = _get_general_icon("trash")
	filled_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	filled_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	filled_icon.modulate = GOLD
	_trash_icon_fill_mask.add_child(filled_icon)
	_trash_capacity_label = _make_label(21, CREAM, 5)
	_trash_capacity_label.name = "Maximum"
	_trash_capacity_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_trash_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trash_capacity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_trash_counter_icon.add_child(_trash_capacity_label)

	var value := _make_label(34, CREAM)
	value.name = "Value"
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	return card


func _make_inventory_counter(counter_name: String, icon_texture: Texture2D) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = counter_name
	card.custom_minimum_size = Vector2(250, 90)
	card.add_theme_stylebox_override("panel", _panel_style(DARK, Color("5b3933"), 11, 3))
	var margin := MarginContainer.new()
	margin.name = "ContentMargins"
	_set_margins(margin, 11, 7)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.name = "CounterRow"
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(58, 58)
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var value := _make_label(30, CREAM)
	value.name = "Value"
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	return card


func _build_tool_status(root: Control) -> void:
	_tool_slots = Control.new()
	_tool_slots.name = "ToolSlots"
	_tool_slots.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Selected diamond at the upper right, two smaller previews descending left.
	# The recording animation still raises the cluster with the rest of the HUD.
	_tool_slots.position = TOOLS_NORMAL_POSITION
	_tool_slots.size = Vector2(312, 232)
	_tool_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_tool_slots)

	_vacuum_battery_gauge = HBoxContainer.new()
	_vacuum_battery_gauge.name = "VacuumBattery"
	_vacuum_battery_gauge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# The lower-right gap is kept clear of the two smaller diamonds.
	_vacuum_battery_gauge.position = BATTERY_NORMAL_POSITION
	_vacuum_battery_gauge.size = Vector2(138, 22)
	_vacuum_battery_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vacuum_battery_gauge.visible = false
	(_vacuum_battery_gauge as HBoxContainer).add_theme_constant_override("separation", 5)
	root.add_child(_vacuum_battery_gauge)
	var lightning_holder := Control.new()
	lightning_holder.name = "Lightning"
	lightning_holder.custom_minimum_size = Vector2(20, 22)
	_vacuum_battery_gauge.add_child(lightning_holder)
	var lightning := Polygon2D.new()
	lightning.name = "Bolt"
	lightning.polygon = PackedVector2Array([
		Vector2(12, 1), Vector2(3, 13), Vector2(9, 13),
		Vector2(6, 21), Vector2(18, 9), Vector2(12, 9),
	])
	lightning.color = GOLD
	lightning_holder.add_child(lightning)
	_vacuum_battery_bar = ProgressBar.new()
	_vacuum_battery_bar.name = "Charge"
	_vacuum_battery_bar.custom_minimum_size = Vector2(113, 13)
	_vacuum_battery_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_vacuum_battery_bar.min_value = 0.0
	_vacuum_battery_bar.max_value = 100.0
	_vacuum_battery_bar.value = 100.0
	_vacuum_battery_bar.show_percentage = false
	_vacuum_battery_bar.add_theme_stylebox_override("background", _panel_style(SPRINT_EMPTY, Color("291016"), 5, 2))
	_vacuum_battery_bar.add_theme_stylebox_override("fill", _panel_style(GOLD, Color("ffe098"), 5, 1))
	_vacuum_battery_gauge.add_child(_vacuum_battery_bar)


func _build_vacuum_view(root: Control) -> void:
	_vacuum_view_container = SubViewportContainer.new()
	_vacuum_view_container.name = "VacuumFirstPersonView"
	# Pantalla completa y transparente: ya no recorta la herramienta por un
	# rectángulo HUD, mientras que todos los controles siguen sobre ella.
	_vacuum_view_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vacuum_view_container.stretch = false
	_vacuum_view_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vacuum_view_container.visible = false
	root.add_child(_vacuum_view_container)
	# El modelo es puramente decorativo: siempre queda detrás de la batería,
	# selector, punto de mira y resto del HUD aunque crezca fuera de su encuadre.
	root.move_child(_vacuum_view_container, 0)

	_vacuum_viewport = SubViewport.new()
	_vacuum_viewport.name = "Viewport"
	_vacuum_viewport.size = Vector2i(1920, 1080)
	_vacuum_viewport.transparent_bg = true
	_vacuum_viewport.own_world_3d = true
	_vacuum_viewport.handle_input_locally = false
	_vacuum_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vacuum_view_container.add_child(_vacuum_viewport)
	get_viewport().size_changed.connect(_sync_vacuum_viewport_size)
	call_deferred("_sync_vacuum_viewport_size")

	var camera := Camera3D.new()
	camera.name = "ViewCamera"
	camera.fov = VACUUM_VIEW_CAMERA_FOV
	_vacuum_viewport.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key.light_color = Color("ffd49a")
	key.light_energy = 2.0
	_vacuum_viewport.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.2, 1.3, 1.5)
	fill.light_color = GOLD
	fill.light_energy = 1.1
	fill.omni_range = 4.0
	_vacuum_viewport.add_child(fill)

	_vacuum_view_root = Node3D.new()
	_vacuum_view_root.name = "VacuumPosePivot"
	_vacuum_view_root.position = VACUUM_VIEWMODEL_IDLE_POSITION
	_vacuum_view_root.rotation_degrees = VACUUM_VIEWMODEL_IDLE_ROTATION
	camera.add_child(_vacuum_view_root)
	var axis_correction := Node3D.new()
	axis_correction.name = "AxisCorrection"
	axis_correction.rotation_degrees = VACUUM_VIEWMODEL_AXIS_CORRECTION
	_vacuum_view_root.add_child(axis_correction)
	var model := VACUUM_MODEL.instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * VACUUM_VIEWMODEL_SCALE
	axis_correction.add_child(model)
	_vacuum_nozzle_anchor = Node3D.new()
	_vacuum_nozzle_anchor.name = "NozzleWindTarget"
	# Extremo local -X del GLB: la boca visible, no el cuerpo del motor.
	_vacuum_nozzle_anchor.position = Vector3(-0.385, 0.14, 0.0)
	model.add_child(_vacuum_nozzle_anchor)

	_vacuum_wind_root = Node3D.new()
	_vacuum_wind_root.name = "InwardWind"
	_vacuum_viewport.add_child(_vacuum_wind_root)
	var streak_mesh := _make_vacuum_wisp_mesh()
	var streak_material := StandardMaterial3D.new()
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	streak_material.vertex_color_use_as_albedo = true
	for streak_index in 24:
		var streak := MeshInstance3D.new()
		streak.name = "Wind_%02d" % streak_index
		streak.mesh = streak_mesh
		streak.material_override = streak_material
		streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_vacuum_wind_root.add_child(streak)
		_vacuum_wind_streaks.append(streak)
	_vacuum_wind_root.visible = false


func _make_vacuum_wisp_mesh() -> ArrayMesh:
	# Una cinta curvada y afilada evita el aspecto de barras rectangulares.
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	const SEGMENTS := 7
	for segment in SEGMENTS + 1:
		var progress := float(segment) / float(SEGMENTS)
		var envelope := pow(sin(progress * PI), 0.8)
		var half_width := 0.0075 * envelope
		var x := (progress - 0.5) * 0.32
		var curve := sin(progress * PI) * 0.019 + sin(progress * TAU) * 0.006
		var color := Color(0.70, 0.75, 0.80, 0.40 * envelope)
		vertices.append(Vector3(x, curve - half_width, 0.0))
		vertices.append(Vector3(x, curve + half_width, 0.0))
		colors.append(color)
		colors.append(color)
		if segment < SEGMENTS:
			var base := segment * 2
			indices.append_array(PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _sync_vacuum_viewport_size() -> void:
	if _vacuum_viewport == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_vacuum_viewport.size = Vector2i(maxi(1, roundi(viewport_size.x)), maxi(1, roundi(viewport_size.y)))


func _update_vacuum_hud(delta: float) -> void:
	if _manager == null or not _manager.has_method("get_vacuum_state"):
		return
	var state: Dictionary = _manager.get_vacuum_state()
	var equipped := bool(state.get("equipped", false))
	var active := bool(state.get("active", false))
	var view_allowed: bool = equipped and _hud_root_control.visible and not (_player != null and _player.is_sitting()) and not (_manager.hammer_taken and not _manager.final_wall_open)
	_vacuum_view_container.visible = view_allowed
	_vacuum_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if view_allowed else SubViewport.UPDATE_DISABLED
	_vacuum_battery_gauge.visible = view_allowed
	_vacuum_battery_bar.value = float(state.get("ratio", 0.0)) * 100.0
	_vacuum_battery_bar.add_theme_stylebox_override("fill", _panel_style(Color("ffe078") if active else GOLD, Color("ffe9af"), 6, 1))
	_vacuum_wind_root.visible = active and view_allowed
	if not equipped:
		_vacuum_use_pose_blend = 0.0
		_vacuum_motion_offset = Vector3.ZERO
		return
	var time := Time.get_ticks_msec() * 0.001
	_vacuum_use_pose_blend = move_toward(
		_vacuum_use_pose_blend,
		1.0 if active else 0.0,
		delta * VACUUM_VIEWMODEL_POSE_SPEED
	)
	var motion_state: Dictionary = _player.get_view_motion_state() if _player != null and _player.has_method("get_view_motion_state") else {}
	var is_moving := bool(motion_state.get("moving", false))
	var is_sprinting := bool(motion_state.get("sprinting", false))
	var motion_phase := float(motion_state.get("phase", time * 1.6))
	var sway := VACUUM_SPRINT_SWAY if is_sprinting else VACUUM_WALK_SWAY
	var tool_phase := motion_phase * VACUUM_FOLLOW_PHASE_MULTIPLIER
	var target_motion := Vector3(
		sin(tool_phase) * sway.x if is_moving else 0.0,
		absf(cos(tool_phase * 1.55)) * sway.y if is_moving else 0.0,
		0.0
	)
	_vacuum_motion_offset = _vacuum_motion_offset.lerp(
		target_motion,
		clampf(delta * VACUUM_FOLLOW_SMOOTHING, 0.0, 1.0)
	)
	var wobble := _vacuum_use_pose_blend
	var wobble_x := sin(time * 7.5) * VACUUM_ACTIVE_WOBBLE_POSITION.x * wobble
	var wobble_y := sin(time * 11.0 + 0.8) * VACUUM_ACTIVE_WOBBLE_POSITION.y * wobble
	_vacuum_view_root.position = VACUUM_VIEWMODEL_IDLE_POSITION.lerp(VACUUM_VIEWMODEL_USE_POSITION, _vacuum_use_pose_blend)
	_vacuum_view_root.position += _vacuum_motion_offset + Vector3(wobble_x, wobble_y, 0.0)
	_vacuum_view_root.rotation_degrees = VACUUM_VIEWMODEL_IDLE_ROTATION.lerp(VACUUM_VIEWMODEL_USE_ROTATION, _vacuum_use_pose_blend)
	_vacuum_view_root.rotation_degrees.z += _vacuum_motion_offset.x * 30.0 + sin(time * 7.5) * VACUUM_ACTIVE_WOBBLE_ROTATION.y * wobble
	_vacuum_view_root.rotation_degrees.x += _vacuum_motion_offset.y * 16.0 + sin(time * 11.0 + 0.8) * VACUUM_ACTIVE_WOBBLE_ROTATION.x * wobble
	if active:
		var nozzle := _vacuum_nozzle_anchor.global_position
		for streak_index in _vacuum_wind_streaks.size():
			var streak := _vacuum_wind_streaks[streak_index]
			var speed := 1.55 + 0.35 * sin(float(streak_index) * 1.93)
			var progress := fmod(time * speed + float(streak_index) * 0.618034, 1.0)
			var start_angle := TAU * float(streak_index) / float(_vacuum_wind_streaks.size())
			var start := nozzle + Vector3(-0.70 + cos(start_angle) * 0.26, 0.30 + sin(start_angle) * 0.21, 0.60)
			var flow := (nozzle - start).normalized()
			var cross_flow := Vector3(-flow.y, flow.x, 0.0)
			var turbulence := sin(time * 3.0 + float(streak_index) * 1.17) * sin(progress * PI) * 0.038
			streak.position = start.lerp(nozzle, progress) + Vector3(0.0, sin(progress * PI) * 0.055, 0.0) + cross_flow * turbulence
			streak.rotation.z = atan2(flow.y, flow.x)
			streak.scale = Vector3.ONE * lerpf(1.0, 0.13, progress)
			streak.transparency = 1.0 - 0.85 * pow(sin(progress * PI), 0.5)


func _build_carried_sack_view(root: Control) -> void:
	_carried_sack_view = TextureRect.new()
	_carried_sack_view.name = "CarriedSackView"
	_carried_sack_view.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_carried_sack_view.position = Vector2(28, -362)
	_carried_sack_view.size = Vector2(128, 108)
	_carried_sack_view.texture = _get_general_icon("trash")
	_carried_sack_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_carried_sack_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_carried_sack_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carried_sack_view.visible = false
	root.add_child(_carried_sack_view)


func _build_sprint_status(root: Control) -> void:
	_sprint_bar = ProgressBar.new()
	_sprint_bar.name = "SprintStamina"
	_sprint_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sprint_bar.position = SPRINT_NORMAL_POSITION
	_sprint_bar.size = Vector2(440, 18)
	_sprint_bar.min_value = 0.0
	_sprint_bar.max_value = 100.0
	_sprint_bar.value = 100.0
	_sprint_bar.show_percentage = false
	_sprint_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprint_bar.add_theme_stylebox_override("background", _panel_style(SPRINT_EMPTY, Color("291016"), 6, 2))
	_sprint_bar.add_theme_stylebox_override("fill", _panel_style(GOLD, Color("ffe098"), 6, 1))
	_sprint_bar.visible = false
	root.add_child(_sprint_bar)


func _update_sprint_bar(delta: float) -> void:
	if _sprint_bar == null or _player == null or not _player.has_method("get_sprint_state"):
		return
	var state: Dictionary = _player.get_sprint_state()
	var duration := float(state.get("duration", 0.0))
	if not bool(state.get("unlocked", false)) or duration <= 0.0:
		_sprint_bar.visible = false
		_sprint_hide_delay = 0.0
		return
	var remaining := clampf(float(state.get("remaining", 0.0)), 0.0, duration)
	_sprint_bar.value = remaining / duration * 100.0
	var is_active := bool(state.get("is_sprinting", false))
	var is_recharging := remaining < duration - 0.005
	if is_active or is_recharging:
		_sprint_bar.visible = true
		_sprint_hide_delay = 0.85
	elif _sprint_bar.visible:
		_sprint_hide_delay = maxf(0.0, _sprint_hide_delay - delta)
		if is_zero_approx(_sprint_hide_delay):
			_sprint_bar.visible = false


func _build_crosshair_and_messages(root: Control) -> void:
	_crosshair = TextureRect.new()
	_crosshair.name = "Crosshair"
	_crosshair.texture = RETICLE_DEFAULT
	_crosshair.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crosshair.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(_crosshair)
	_reset_crosshair_layout()

	_prompt_label = _make_label(23, Color("ffe9a6"), 6)
	_prompt_label.name = "Prompt"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position = PROMPT_NORMAL_POSITION
	_prompt_label.size = Vector2(840, 52)
	root.add_child(_prompt_label)

	_notice_label = _make_label(22, Color("ffe59a"), 6)
	_notice_label.name = "Notice"
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_label.set_anchors_preset(Control.PRESET_CENTER)
	_notice_label.position = Vector2(-450, 95)
	_notice_label.size = Vector2(900, 90)
	root.add_child(_notice_label)


func _set_prompt(prompt: String) -> void:
	_prompt_label.text = prompt


func _play_pickup_rejected_feedback() -> void:
	if _crosshair == null:
		return
	if _crosshair_reject_tween and _crosshair_reject_tween.is_valid():
		_crosshair_reject_tween.kill()
	_reset_crosshair_layout()
	var rest_position := _crosshair.position
	_crosshair.modulate = Color("ffd0c5")
	_crosshair_reject_tween = create_tween()
	_crosshair_reject_tween.tween_property(_crosshair, "position", rest_position + Vector2(-3.0, 0.5), 0.035)
	_crosshair_reject_tween.tween_property(_crosshair, "position", rest_position + Vector2(2.5, -0.5), 0.045)
	_crosshair_reject_tween.tween_property(_crosshair, "position", rest_position + Vector2(-1.2, 0.0), 0.035)
	_crosshair_reject_tween.tween_property(_crosshair, "position", rest_position, 0.045)
	_crosshair_reject_tween.parallel().tween_property(_crosshair, "modulate", Color.WHITE, 0.08)
	_crosshair_reject_tween.tween_callback(_reset_crosshair_layout)


func _reset_crosshair_layout() -> void:
	if _crosshair == null:
		return
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -64.0
	_crosshair.offset_top = -64.0
	_crosshair.offset_right = 64.0
	_crosshair.offset_bottom = 64.0


func _update_state() -> void:
	if _manager == null:
		return
	_bag_label.text = str(_manager.bag_volume)
	_trash_capacity_label.text = str(_manager.bag_capacity)
	_update_trash_fill(float(_manager.bag_volume) / float(maxi(1, _manager.bag_capacity)))
	_crosshair.texture = RETICLE_BAG_FULL if _manager.bag_volume >= _manager.bag_capacity else RETICLE_DEFAULT
	_sync_displayed_coins()
	var current_room_id: StringName = _player.get_current_room_id() if _player and _player.has_method("get_current_room_id") else &"room_01"
	var clean_percent: float = _manager.get_clean_percent(current_room_id)
	_room_title.text = {
		&"room_01": "SALA 1 — TUTORIAL",
		&"left_corridor": "PASILLO — ALA DERECHA",
		&"manager_office": "DESPACHO DEL MANAGER",
		&"lobby": "VESTÍBULO",
		&"right_corridor": "PASILLO — ALA IZQUIERDA",
		&"room_03": "SALA 3 — ACCIÓN",
		&"room_04": "SALA 4 — MIEDO",
	}.get(current_room_id, "CINEMA PALACE")
	_clean_bar.value = clean_percent
	_clean_label.text = ("%.2f %%" % clean_percent).replace(".", ",")
	var found_lost_items: int = int(_manager.get_found_lost_item_count()) if _manager.has_method("get_found_lost_item_count") else _manager.held_lost_items.size()
	var total_lost_items: int = int(_manager.get_total_lost_item_count()) if _manager.has_method("get_total_lost_item_count") else 1
	_lost_item_label.text = "%d / %d" % [found_lost_items, total_lost_items]
	_carried_sack_view.visible = _manager.max_active_sacks > 0 and _manager.has_carried_sack()
	_update_active_ability_hud()
	_rebuild_tool_slots()
	_check_objective_completion()


func _collect_objective_states() -> Dictionary:
	var states := {}
	if _manager == null:
		return states
	states["room_01_clean"] = {"completed": bool(_manager.room_completed), "title": "Limpia la Sala 1", "description": "La primera sala ya está lista para otra sesión."}
	for objective in _manager.get_cinema_objectives():
		var key := String(objective.get("id", objective.get("title", "")))
		states[key] = {"completed": bool(objective.get("completed", false)), "title": String(objective.get("title", "")), "description": String(objective.get("description", objective.get("progress", "")))}
	states["documents_found"] = {"completed": _manager.get_found_document_count() >= 12, "title": "Descubre la verdad", "description": "Has encontrado todos los documentos."}
	states["collectibles_found"] = {"completed": _manager.get_found_collectible_count() >= _manager.get_total_collectible_count(), "title": "¡Colecciónalos todos!", "description": "Has reunido todas las figuras."}
	for key in states:
		var reward := int(_manager.Rules.OBJECTIVE_REWARDS.get(key,0))
		if reward>0: states[key].description += "  +%s monedas" % _manager.format_money(reward)
	return states


func _initialize_objective_states() -> void:
	_objective_states = _collect_objective_states()
	_objective_states_initialized = true


func _play_collectible_reward_sound(_collectible_id: String) -> void:
	# Physical figures and arcade poster prizes share this signal. Reuse the
	# approved objective piano without replaying it in a completion toast that
	# this same prize may trigger (for example, an arcade Difficult objective).
	var current_states := _collect_objective_states()
	for key in current_states:
		if _objective_states.has(key) and not bool(_objective_states[key].completed) and bool(current_states[key].completed):
			_collectible_completed_objective_silences[key] = true
	if _objective_sound != null and _objective_sound.stream != null:
		_objective_sound.play()


func _check_objective_completion() -> void:
	if not _objective_states_initialized:
		return
	var next_states := _collect_objective_states()
	for key in next_states:
		var current: Dictionary = next_states[key]
		if not _objective_states.has(key):
			var revealed := current.duplicate()
			revealed["kind"] = &"new"
			_objective_queue.append(revealed)
		elif not bool(_objective_states[key].completed) and bool(current.completed):
			var finished := current.duplicate()
			finished["kind"] = &"completed"
			finished["mute_sound"] = _collectible_completed_objective_silences.has(key)
			_collectible_completed_objective_silences.erase(key)
			_objective_queue.append(finished)
	_objective_states = next_states
	if not _objective_toast_active and not _objective_queue.is_empty():
		_show_next_objective_toast()


func _build_objective_toast(root: Control) -> void:
	_objective_panel = PanelContainer.new()
	_objective_panel.name = "ObjectiveToast"
	_objective_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective_panel.offset_left = -285.0
	_objective_panel.offset_right = 285.0
	_objective_panel.offset_top = 108.0
	_objective_panel.offset_bottom = 222.0
	_objective_panel.add_theme_stylebox_override("panel", _panel_style(DARK, GOLD, 11, 3))
	_objective_panel.visible = false
	root.add_child(_objective_panel)
	var margin := MarginContainer.new()
	_set_margins(margin, 14, 11)
	_objective_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	_objective_slot = PanelContainer.new()
	_objective_slot.name = "StampSlot"
	_objective_slot.custom_minimum_size = Vector2(86, 86)
	_objective_slot.add_theme_stylebox_override("panel", _panel_style(Color("271d1c"), Color("866e47"), 7, 2))
	row.add_child(_objective_slot)
	var stamp_overlay := Control.new()
	stamp_overlay.name = "StampOverlay"
	stamp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_slot.add_child(stamp_overlay)
	var empty_stamp := _make_label(51, Color("81766c"))
	empty_stamp.text = "○"
	empty_stamp.position = Vector2(23, 4)
	stamp_overlay.add_child(empty_stamp)
	_objective_stamp = TextureRect.new()
	_objective_stamp.name = "FallingStamp"
	_objective_stamp.texture = OBJECTIVE_STAMP
	_objective_stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_objective_stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_objective_stamp.size = Vector2(76, 76)
	_objective_stamp.position = Vector2(5, -160)
	_objective_stamp.modulate.a = 0.0
	stamp_overlay.add_child(_objective_stamp)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_column)
	_objective_caption = _make_label(17, GOLD)
	_objective_caption.text = "OBJETIVO COMPLETADO"
	text_column.add_child(_objective_caption)
	_objective_title = _make_label(27, CREAM)
	text_column.add_child(_objective_title)
	_objective_description = _make_label(18, CREAM)
	_objective_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(_objective_description)
	_objective_tab_hint = _make_label(16, GOLD)
	_objective_tab_hint.text = "TAB  ·  VER OBJETIVOS"
	_objective_tab_hint.visible = false
	text_column.add_child(_objective_tab_hint)
	_objective_sound = AudioStreamPlayer.new()
	_objective_sound.name = "ObjectiveCompleteSound"
	_objective_sound.process_mode = Node.PROCESS_MODE_ALWAYS # Arcade rewards arrive while the world is paused.
	_objective_sound.bus = &"UI"
	_objective_sound.stream = objective_complete_sound
	add_child(_objective_sound)
	_objective_new_sound = AudioStreamPlayer.new()
	_objective_new_sound.name = "ObjectiveNewSound"
	_objective_new_sound.bus = &"UI"
	_objective_new_sound.stream = objective_new_sound
	add_child(_objective_new_sound)


func _show_next_objective_toast() -> void:
	if _objective_queue.is_empty():
		_objective_toast_active = false
		return
	# Container layout cannot measure wrapped text while the intro hides HUDRoot.
	if _hud_root_control == null or not _hud_root_control.is_visible_in_tree():
		return
	var menu := get_tree().get_first_node_in_group("upgrade_menu")
	if menu != null and menu.has_method("is_open") and menu.is_open():
		return
	_objective_toast_active = true
	var objective: Dictionary = _objective_queue.pop_front()
	_objective_toast_kind = objective.get("kind", &"completed")
	var completed := _objective_toast_kind == &"completed"
	_objective_caption.text = "OBJETIVO COMPLETADO" if completed else "NUEVO OBJETIVO"
	_objective_title.text = String(objective.title)
	_objective_description.text = String(objective.description)
	_objective_slot.visible = completed
	_objective_tab_hint.visible = not completed
	_objective_stamp.position.y = -160.0
	_objective_stamp.modulate.a = 0.0
	_objective_panel.modulate.a = 0.0
	_objective_panel.position.y = 92.0
	_objective_panel.visible = true
	_objective_tween = create_tween()
	_objective_tween.tween_property(_objective_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_objective_tween.parallel().tween_property(_objective_panel, "position:y", 108.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if completed:
		_objective_tween.tween_property(_objective_stamp, "modulate:a", 1.0, 0.2)
		_objective_tween.tween_property(_objective_stamp, "position:y", 5.0, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if completed and not bool(objective.get("mute_sound", false)) and _objective_sound.stream != null:
		_objective_sound.play()
	elif not completed and _objective_new_sound.stream != null:
		_objective_new_sound.play()
	_objective_tween.tween_interval(4.0 if not completed else 3.2)
	_objective_tween.tween_property(_objective_panel, "modulate:a", 0.0, 0.35)
	_objective_tween.tween_callback(func() -> void:
		_objective_panel.visible = false
		_objective_toast_active = false
		_show_next_objective_toast()
	)


func consume_new_objective_tab() -> bool:
	if not _objective_toast_active or _objective_toast_kind != &"new":
		return false
	if _objective_tween != null and _objective_tween.is_valid():
		_objective_tween.kill()
	_objective_panel.visible = false
	_objective_toast_active = false
	_objective_toast_kind = &""
	return true


func _on_room_changed(_room_id: StringName) -> void:
	_update_state()


func _update_trash_fill(fill_ratio: float) -> void:
	if _trash_icon_fill_mask == null:
		return
	const ICON_SIZE := 70.0
	var ratio := clampf(fill_ratio, 0.0, 1.0)
	var hidden_height := ICON_SIZE * (1.0 - ratio)
	_trash_icon_fill_mask.position = Vector2(0.0, hidden_height)
	_trash_icon_fill_mask.size = Vector2(ICON_SIZE, ICON_SIZE - hidden_height)
	var filled_icon := _trash_icon_fill_mask.get_node("FilledIcon") as TextureRect
	filled_icon.position = Vector2(0.0, -hidden_height)
	filled_icon.size = Vector2(ICON_SIZE, ICON_SIZE)


func _rebuild_tool_slots() -> void:
	var equipped := String(_manager.equipped_tool)
	var signature := "%s|%s|%s" % [
		equipped,
		_manager.owns_tool(&"vacuum"),
		_manager.owns_tool(&"broom"),
	]
	if signature == _tool_slots_signature:
		return
	_tool_slots_signature = signature
	_clear_children(_tool_slots)
	var tools: Array[Dictionary] = [{"id":"","title":"MANO","icon":"hand"}]
	if _manager.owns_tool(&"broom"):
		tools.append({"id":"broom","title":"ESCOBA","icon":"broom"})
	if _manager.owns_tool(&"vacuum"):
		tools.append({"id":"vacuum","title":"ASPIRADORA","icon":"vacuum"})
	var selected_index := 0
	for index in tools.size():
		if tools[index].id==equipped: selected_index=index
	var centers := [Vector2(232,65),Vector2(175,120),Vector2(130,164)]
	var diameters := [124.0,88.0,76.0]
	var shift := Vector2(0,(3-tools.size())*48.0)
	for order in tools.size():
		# Forward cycling selects order 1: the preview in the middle diamond.
		var tool: Dictionary = tools[(selected_index+order)%tools.size()]
		var diameter: float = diameters[order]
		var card := _make_tool_card(String(tool.title),String(tool.icon),order==0,diameter)
		_tool_slots.add_child(card)
		card.position=Vector2(centers[order])+shift-Vector2.ONE*diameter*.5
		card.pivot_offset=Vector2.ONE*diameter*.5
		card.scale=Vector2.ONE*.92
		card.modulate.a=0.0
		var appear := card.create_tween().set_parallel(true)
		appear.tween_property(card,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		appear.tween_property(card,"modulate:a",1.0,.14)
	if tools.size()>1:
		var hint := _make_label(16,CREAM,3)
		hint.name="ToolCycleHint"
		hint.text="[Q] CAMBIAR"
		hint.position=Vector2(160,205)
		hint.size=Vector2(140,26)
		hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		_tool_slots.add_child(hint)
	_set_mouse_passthrough(_tool_slots)


func _tool_diamond_points(diameter: float, inset: float=0.0) -> PackedVector2Array:
	var half := diameter*.5
	return PackedVector2Array([Vector2(half,inset),Vector2(diameter-inset,half),Vector2(half,diameter-inset),Vector2(inset,half)])

func _make_tool_card(title_text: String, icon_name: String, selected: bool, diameter: float) -> Control:
	var card := Control.new()
	card.name = "Tool_%s" % title_text.to_pascal_case()
	card.size=Vector2.ONE*diameter
	card.tooltip_text=title_text
	card.set_meta("tool_id",icon_name)
	card.set_meta("selected",selected)
	var shadow := Polygon2D.new()
	shadow.name="Shadow"
	shadow.polygon=_tool_diamond_points(diameter)
	shadow.position=Vector2(0,4)
	shadow.color=Color(0,0,0,.35)
	shadow.antialiased=true
	card.add_child(shadow)
	var border := Polygon2D.new()
	border.name="PointedFrame"
	border.polygon=_tool_diamond_points(diameter)
	border.color=GOLD if selected else Color("6b4740")
	border.antialiased=true
	card.add_child(border)
	var fill := Polygon2D.new()
	fill.name="Inset"
	fill.polygon=_tool_diamond_points(diameter,4.0 if selected else 2.0)
	fill.color=Color(.12,.075,.065,.96) if selected else DARK
	fill.antialiased=true
	card.add_child(fill)
	var icon := TextureRect.new()
	icon.name = "Icon"
	var icon_size := Vector2.ONE*diameter*(.58 if icon_name=="hand" else .53)
	icon.position = (card.size-icon_size)*.5
	icon.size = icon_size
	icon.texture = _get_general_icon(icon_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if selected else Color(.78,.73,.65,.85)
	card.add_child(icon)
	return card


func _queue_coin_reward(amount: int, source_world_position: Vector3) -> void:
	if amount <= 0:
		return
	if DisplayServer.get_name() == "headless":
		_sync_displayed_coins()
		return
	_enqueue_coin_animation(amount,source_world_position,false)

func _sync_displayed_coins() -> void:
	_displayed_coins=maxi(0,int(_manager.coins)-_deposit_pending_coins-_unsettled_reward_coins)
	_coins_label.text=_manager.format_money(_displayed_coins)

func _queue_deposit_reward(_definition_id: String, _units: int, earned: int) -> void:
	_deposit_pending_coins+=earned
	_deposit_idle_time=0.0
	(_deposit_reward_popup.get_node("Gain") as Label).text="+ " + _manager.format_money(_deposit_pending_coins)
	_deposit_reward_popup.show()
	_sync_displayed_coins()

func _update_deposit_reward(delta: float) -> void:
	if _manager==null or _deposit_pending_coins<=0: return
	if _manager.is_depositing():
		_deposit_idle_time=0.0
		return
	_deposit_idle_time+=delta
	if _deposit_idle_time<1.0: return
	var amount := _deposit_pending_coins
	_deposit_pending_coins=0
	_deposit_reward_popup.hide()
	_enqueue_coin_animation(amount,Vector3.ZERO,true)

func _enqueue_coin_animation(amount: int, source: Vector3, from_deposit: bool) -> void:
	_unsettled_reward_coins+=amount
	_coin_reward_queue.append({"amount":amount,"source":source,"deposit":from_deposit})
	_sync_displayed_coins()
	if not _coin_animation_active:
		_play_coin_reward_queue()


func _play_coin_reward_queue() -> void:
	_coin_animation_active = true
	while not _coin_reward_queue.is_empty():
		var reward: Dictionary = _coin_reward_queue.pop_front()
		await _animate_coin_reward(int(reward.amount), reward.source as Vector3,bool(reward.deposit))
		_unsettled_reward_coins-=int(reward.amount)
		_sync_displayed_coins()
		_manager.play_coin_reward_feedback()
		_pulse_coin_counter()
	_coin_animation_active = false
	_sync_displayed_coins()


func _make_coin_reward_popup(amount: int) -> Control:
	var popup := Control.new()
	popup.name = "CoinReward_%d" % amount
	popup.size = Vector2(150, 58)
	popup.pivot_offset = popup.size * 0.5
	var gain := _make_label(31, GOLD, 5)
	gain.name="Gain"
	gain.text = "+ " + (_manager.format_money(amount) if _manager != null else "0,00")
	gain.position = Vector2(0, 0)
	gain.size = Vector2(94, 52)
	gain.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	popup.add_child(gain)
	var icon := TextureRect.new()
	icon.position = Vector2(98, 3)
	icon.size = Vector2(48, 48)
	icon.texture = COIN_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	popup.add_child(icon)
	_set_mouse_passthrough(popup)
	return popup

func _animate_coin_reward(amount: int, _source_world_position: Vector3, from_deposit: bool=false) -> void:
	var start := _deposit_reward_popup.global_position if from_deposit else _coin_panel.get_global_rect().position + Vector2(-182, 38)
	var popup := _make_coin_reward_popup(amount)
	popup.position=start
	_coin_flight_layer.add_child(popup)
	var target := _coin_panel.get_global_rect().get_center() - popup.size * 0.5
	var tween := create_tween()
	if not from_deposit: tween.tween_interval(0.68)
	tween.tween_property(popup, "position", target, 0.46).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	popup.queue_free()


func _pulse_coin_counter() -> void:
	_coin_icon.pivot_offset = _coin_icon.size * 0.5
	_coin_icon.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(_coin_icon, "scale", Vector2(1.12, 0.84), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_coin_icon, "scale", Vector2(0.96, 1.12), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_coin_icon, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _queue_trash_icon_pulse() -> void:
	# Multi-pickup can finish several collection animations together. Queue each
	# small pulse so tweens never compete for the same icon scale.
	_pending_trash_icon_pulses = mini(_pending_trash_icon_pulses + 1, 8)
	if not _trash_icon_pulse_running:
		_play_trash_icon_pulses()


func _play_trash_icon_pulses() -> void:
	_trash_icon_pulse_running = true
	while _pending_trash_icon_pulses > 0:
		_pending_trash_icon_pulses -= 1
		_trash_counter_icon.pivot_offset = _trash_counter_icon.size * 0.5
		_trash_counter_icon.scale = Vector2.ONE
		var tween := create_tween()
		tween.tween_property(_trash_counter_icon, "scale", Vector2(1.065, 0.88), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_trash_counter_icon, "scale", Vector2(0.985, 1.06), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_trash_counter_icon, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
	_trash_counter_icon.scale = Vector2.ONE
	_trash_icon_pulse_running = false


func _queue_lost_icon_pulse() -> void:
	_pending_lost_icon_pulses = mini(_pending_lost_icon_pulses + 1, 8)
	if not _lost_icon_pulse_running:
		_play_lost_icon_pulses()


func _play_lost_icon_pulses() -> void:
	_lost_icon_pulse_running = true
	while _pending_lost_icon_pulses > 0:
		_pending_lost_icon_pulses -= 1
		_lost_counter_icon.pivot_offset = _lost_counter_icon.size * 0.5
		_lost_counter_icon.scale = Vector2.ONE
		var tween := create_tween()
		tween.tween_property(_lost_counter_icon, "scale", Vector2(1.065, 0.88), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_lost_counter_icon, "scale", Vector2(0.985, 1.06), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_lost_counter_icon, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
	_lost_counter_icon.scale = Vector2.ONE
	_lost_icon_pulse_running = false


func _show_notification(message: String) -> void:
	_notice_generation += 1
	var generation := _notice_generation
	_notice_label.text = message
	await get_tree().create_timer(4.5).timeout
	if generation == _notice_generation:
		_notice_label.text = ""


func _make_label(font_size: int, color: Color, outline_size: int = 3) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("160f11"))
	label.add_theme_constant_override("outline_size", outline_size)
	return label


func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _set_margins(margin: MarginContainer, horizontal: int, vertical: int) -> void:
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)


func _get_general_icon(kind: String) -> Texture2D:
	if _general_icon_cache.has(kind):
		return _general_icon_cache[kind] as Texture2D
	if GENERAL_ICONS.has(kind):
		var direct_icon := GENERAL_ICONS[kind] as Texture2D
		_general_icon_cache[kind] = direct_icon
		return direct_icon
	var keywords: Dictionary = {
		"trash": ["bolsa", "basura", "trash"],
		"lost": ["perdid", "lost", "objeto"],
		"hand": ["mano", "hand"],
		"vacuum": ["aspir", "vacuum"],
	}
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(GENERAL_ICON_DIR)):
		for file_name in DirAccess.get_files_at(GENERAL_ICON_DIR):
			if file_name.get_extension().to_lower() != "png":
				continue
			var normalized := file_name.to_lower()
			for keyword in keywords.get(kind, []):
				if String(keyword) in normalized:
					var imported := load("%s/%s" % [GENERAL_ICON_DIR, file_name]) as Texture2D
					if imported:
						_general_icon_cache[kind] = imported
						return imported
	var fallback_path := String(FALLBACK_ICON_PATHS.get(kind, FALLBACK_ICON_PATHS.hand))
	var fallback := load(fallback_path) as Texture2D
	_general_icon_cache[kind] = fallback
	return fallback


func _set_mouse_passthrough(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_passthrough(child)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
