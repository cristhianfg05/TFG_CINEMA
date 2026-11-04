class_name UpgradeMenu
extends CanvasLayer

signal document_closed(document_id: String)

const UpgradeCatalog := preload("res://resources/upgrades/upgrade_catalog.gd")
const HUD_FONT := preload("res://assets/fonts/PalaceHUD-Bold.ttf")
const COIN_ICON := preload("res://assets/gptphoto_models/IconoMoneda.png")
const DOCUMENT_ICON := preload("res://assets/ui/icons/document.svg")
const CASSETTE_ICON := preload("res://assets/ui/icons/cassette.svg")
const RecordingCatalog := preload("res://resources/recordings/recording_catalog.gd")
const POPCORN_STAMP_ICON := preload("res://assets/ui/icons/popcorn_stamp.svg")
const PointerTheme := preload("res://scripts/pointer_theme.gd")
const CollectiblesViewClass := preload("res://scripts/collectibles_view.gd")
const DISCOVERY_NOTIFICATION_DURATION := 8.0
const ICON_ROOT := "res://assets/ui/icons/upgrades/"
const UPGRADE_ICON_ROOT := "res://assets/models/source/general/upgrade_icons/"
const UPGRADE_ICON_FILES := {
	"sprint": "upgrade_sprint_gold.png",
	"quick_hands": "upgrade_agile_hands_gold.png",
	"reinforced_bag": "upgrade_reinforced_bag_gold.png",
	"multi_pickup": "upgrade_multiple_pickup_gold.png",
	"manual_reach": "upgrade_manual_reach_gold.png",
	"sealed_bags": "upgrade_sealed_bags_gold.png",
	"recycle_value": "upgrade_recycling_value_gold.png",
	"all_seeing_eye": "upgrade_eye_all_trash.png",
	"vacuum_reach": "upgrade_vacuum_reach_gold.png",
	"vacuum_battery": "upgrade_vacuum_battery_gold.png",
	"vacuum_recharge": "upgrade_vacuum_recharge_gold.png",
}
const BURGUNDY := Color("42141d")
const BURGUNDY_LIGHT := Color("71303a")
const CHARCOAL := Color("17191d")
const CHARCOAL_LIGHT := Color("292c31")
const BLUE := Color("36536d")
const CREAM := Color("f3dfb0")
const GOLD := Color("e4ae4f")
const GOLD_BRIGHT := Color("f3c64e")
const MUTED := Color("8f8985")

var _overlay: Control
var _menu_shell: Control
var _frame: PanelContainer
var _section_bar: HBoxContainer
var _abilities_view: VBoxContainer
var _objectives_view: VBoxContainer
var _objectives_list: VBoxContainer
var _collectibles_view: CollectiblesView
var _documents_view: VBoxContainer
var _recordings_view: VBoxContainer
var _tab_bar: HBoxContainer
var _tree_scroll: ScrollContainer
var _tree_scroll_hint: Label
var _tree: VBoxContainer
var _tree_cache_root: Control
var _detail_title: Label
var _detail_current: Label
var _detail_next: Label
var _detail_description: Label
var _detail_cost: Label
var _buy_button: Button
var _documents_header: Label
var _documents_list: VBoxContainer
var _document_title: Label
var _document_subtitle: Label
var _document_body: Label
var _document_scroll: ScrollContainer
var _recordings_list: VBoxContainer
var _recording_title: Label
var _recording_narrator: Label
var _recording_body: Label
var _recording_scroll: ScrollContainer
var _notification_panel: PanelContainer
var _notification_title: Label
var _notification_hint: Label
var _manager: Node
var _section: StringName = &"abilities"
var _category: StringName = &"collection"
var _selected_branch: StringName = &"quick_hands"
var _selected_level := 1
var _state_refresh_queued := false
var _category_trees: Dictionary = {}
var _category_built_branch_counts: Dictionary = {}
var _category_render_signatures: Dictionary = {}
var _branch_widgets: Dictionary = {}
var _document_rows: Dictionary = {}
var _selected_document_id := ""
var _recording_rows: Dictionary = {}
var _selected_recording_id := ""
var _pending_discovery_type: StringName = &""
var _pending_discovery_item_id := ""
var _pending_discovery_section: StringName = &""
var _notification_active := false
var _notification_generation := 0
var _notification_tween: Tween
var _paused_by_archive := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("upgrade_menu")
	_build_ui()
	_overlay.visible = false
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	if _manager:
		_manager.state_changed.connect(_queue_visible_state_refresh)
		_manager.discovery_found.connect(_show_discovery_notification)
		_collectibles_view.setup(_manager)
	_refresh()
	call_deferred("_prewarm_collection_tree")
	PointerTheme.apply_menu_cursors()


func _input(event: InputEvent) -> void:
	if get_viewport().is_input_handled():
		return
	if _is_game_intro_active():
		return
	if is_open() and event.is_action_pressed("pause") and not event.is_echo():
		close_menu()
		get_viewport().set_input_as_handled()
		return
	if _is_tab_toggle(event):
		if _is_hammer_cinematic_active():
			get_viewport().set_input_as_handled()
			return
		if is_open():
			close_menu()
		elif not get_tree().paused:
			var hud := get_tree().get_first_node_in_group("gameplay_hud")
			if hud != null and hud.has_method("consume_new_objective_tab") and hud.consume_new_objective_tab():
				open_menu(&"objectives")
			elif _notification_active and not _pending_discovery_item_id.is_empty() and not _pending_discovery_section.is_empty():
				var target_section := _pending_discovery_section
				var target_item := _pending_discovery_item_id
				_hide_discovery_notification()
				open_menu(target_section, target_item)
			else:
				open_menu()
		get_viewport().set_input_as_handled()


func _is_tab_toggle(event: InputEvent) -> bool:
	if event.is_action_pressed("upgrade_menu") and not event.is_echo():
		return true
	var key_event := event as InputEventKey
	return (
		key_event != null
		and key_event.pressed
		and not key_event.echo
		and (key_event.keycode == KEY_TAB or key_event.physical_keycode == KEY_TAB)
	)


func _is_hammer_cinematic_active() -> bool:
	var hammer := get_tree().get_first_node_in_group("hammer_controller")
	return hammer != null and hammer.has_method("is_cinematic_active") and hammer.is_cinematic_active()


func is_open() -> bool:
	return _overlay != null and _overlay.visible


func toggle_menu() -> void:
	if is_open():
		close_menu()
	elif not get_tree().paused:
		open_menu()


func open_menu(target_section: StringName = &"", target_item_id: String = "") -> void:
	if _manager == null or _is_game_intro_active() or _is_hammer_cinematic_active():
		return
	if _manager.has_method("set_vacuum_trigger_held"):
		_manager.set_vacuum_trigger_held(false)
	if target_section == &"documents" and _manager.get_found_document_count() <= 0:
		target_section = &"abilities"
	if target_section == &"collectibles" and _manager.get_found_collectible_count() <= 0:
		target_section = &"abilities"
	if not target_section.is_empty():
		_section = target_section
	if _section == &"documents" and not target_item_id.is_empty():
		_selected_document_id = target_item_id
	_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_hud_coins_above_menu(true)
	_apply_section_pause()
	_refresh(target_item_id)
	_menu_shell.position.y = 105.0
	_menu_shell.modulate.a = 0.12
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_menu_shell, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_menu_shell, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func close_menu() -> void:
	if is_open():
		_emit_selected_document_closed()
	_overlay.visible = false
	_collectibles_view.set_active(false)
	if _paused_by_archive:
		get_tree().paused = false
		_paused_by_archive = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_hud_coins_above_menu(false)


func _set_hud_coins_above_menu(enabled: bool) -> void:
	var hud = get_tree().get_first_node_in_group("gameplay_hud")
	if hud and hud.has_method("set_coin_overlay_above_menu"):
		hud.set_coin_overlay_above_menu(enabled)


func _is_game_intro_active() -> bool:
	var intro = get_tree().get_first_node_in_group("game_intro")
	return bool(intro and intro.has_method("is_active") and intro.is_active())


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "UpgradeOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.015, 0.018, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(shade)

	_menu_shell = Control.new()
	_menu_shell.name = "MenuShell"
	_menu_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_shell.mouse_filter = Control.MOUSE_FILTER_PASS
	var palace_theme := Theme.new()
	palace_theme.default_font = HUD_FONT
	_menu_shell.theme = palace_theme
	_overlay.add_child(_menu_shell)

	var menu_title := Label.new()
	menu_title.name = "MenuTitle"
	menu_title.text = "MENÚ"
	menu_title.position = Vector2(280, 99)
	menu_title.size = Vector2(210, 62)
	menu_title.add_theme_font_size_override("font_size", 48)
	menu_title.add_theme_color_override("font_color", CREAM)
	menu_title.add_theme_color_override("font_outline_color", Color("1c1012"))
	menu_title.add_theme_constant_override("outline_size", 5)
	_menu_shell.add_child(menu_title)

	_build_primary_sections()
	_build_menu_frame()
	_build_tab_footer()
	_build_discovery_notification()


func _build_primary_sections() -> void:
	_section_bar = HBoxContainer.new()
	_section_bar.name = "PrimarySections"
	_section_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	# Keep the first tab clear of the MENÚ title at x=280..490.
	_section_bar.position = Vector2(-460, 100)
	_section_bar.size = Vector2(1140, 60)
	_section_bar.add_theme_constant_override("separation", 7)
	_menu_shell.add_child(_section_bar)
	var abilities_button := _make_primary_section("HABILIDADES", true)
	abilities_button.name = "AbilitiesSection"
	abilities_button.pressed.connect(_select_primary_section.bind(&"abilities"))
	_section_bar.add_child(abilities_button)
	var objectives_button := _make_primary_section("OBJETIVOS", false)
	objectives_button.name = "ObjectivesSection"
	objectives_button.disabled = false
	objectives_button.pressed.connect(_select_primary_section.bind(&"objectives"))
	_section_bar.add_child(objectives_button)
	var collectibles_button := _make_primary_section("?", false)
	collectibles_button.name = "CollectiblesSection"
	collectibles_button.pressed.connect(_select_primary_section.bind(&"collectibles"))
	_section_bar.add_child(collectibles_button)
	var documents_button := _make_primary_section("?", false)
	documents_button.name = "DocumentsSection"
	documents_button.pressed.connect(_select_primary_section.bind(&"documents"))
	_section_bar.add_child(documents_button)
	var recordings_button := _make_primary_section("GRABACIONES", false)
	recordings_button.name = "RecordingsSection"
	recordings_button.pressed.connect(_select_primary_section.bind(&"recordings"))
	_section_bar.add_child(recordings_button)


func _make_primary_section(title: String, selected: bool) -> Button:
	var button := Button.new()
	button.text = title
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 60
	button.disabled = not selected
	PointerTheme.set_button_cursor(button)
	button.add_theme_font_override("font", HUD_FONT)
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", CHARCOAL if selected else MUTED)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _style(CREAM, GOLD, 7, 3))
	button.add_theme_stylebox_override("hover", _style(GOLD_BRIGHT, CREAM, 7, 3))
	button.add_theme_stylebox_override("disabled", _style(Color("261f21"), Color("514347"), 7, 2))
	return button


func _refresh_primary_sections() -> void:
	if _section_bar == null or _section_bar.get_child_count() < 5:
		return
	_configure_primary_section(_section_bar.get_child(0) as Button, "HABILIDADES", &"abilities", true, null)
	_configure_primary_section(_section_bar.get_child(1) as Button, "OBJETIVOS", &"objectives", true, POPCORN_STAMP_ICON)
	var collectibles_available: bool = _manager != null and _manager.get_found_collectible_count() > 0
	_configure_primary_section(
		_section_bar.get_child(2) as Button,
		"COLECCIONABLES" if collectibles_available else "?",
		&"collectibles",
		collectibles_available,
		null
	)
	var documents_available: bool = _manager != null and _manager.get_found_document_count() > 0
	_configure_primary_section(
		_section_bar.get_child(3) as Button,
		"DOCUMENTOS" if documents_available else "?",
		&"documents",
		documents_available,
		DOCUMENT_ICON if documents_available else null
	)
	_configure_primary_section(_section_bar.get_child(4) as Button, "GRABACIONES", &"recordings", true, CASSETTE_ICON)


func _configure_primary_section(
	button: Button,
	title: String,
	section_id: StringName,
	available: bool,
	icon: Texture2D
) -> void:
	var selected := available and _section == section_id
	button.text = title
	button.disabled = not available
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 31)
	button.add_theme_color_override("font_color", CHARCOAL if selected else CREAM)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _style(CREAM if selected else BURGUNDY, GOLD if selected else BURGUNDY_LIGHT, 7, 3 if selected else 2))
	button.add_theme_stylebox_override("hover", _style(GOLD_BRIGHT, CREAM, 7, 3))
	button.add_theme_stylebox_override("pressed", _style(GOLD, CREAM, 7, 3))
	button.add_theme_stylebox_override("focus", _style(CREAM if selected else BURGUNDY_LIGHT, GOLD_BRIGHT, 7, 3))
	button.add_theme_stylebox_override("disabled", _style(Color("261f21"), Color("514347"), 7, 2))
	PointerTheme.set_button_cursor(button)


func _build_menu_frame() -> void:
	_frame = PanelContainer.new()
	_frame.name = "UpgradeFrame"
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.offset_left = 280
	_frame.offset_top = 170
	_frame.offset_right = -280
	_frame.offset_bottom = -300
	_frame.add_theme_stylebox_override("panel", _style(Color(0.055, 0.045, 0.046, 0.97), Color("87672f"), 11, 2, 18))
	_menu_shell.add_child(_frame)

	_abilities_view = VBoxContainer.new()
	_abilities_view.name = "AbilitiesView"
	_abilities_view.add_theme_constant_override("separation", 12)
	_frame.add_child(_abilities_view)

	_tab_bar = HBoxContainer.new()
	_tab_bar.name = "AbilityTabs"
	_tab_bar.custom_minimum_size.y = 52
	_tab_bar.add_theme_constant_override("separation", 7)
	_abilities_view.add_child(_tab_bar)

	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _line_style(Color("7e622f"), 1))
	_abilities_view.add_child(separator)

	var content := HBoxContainer.new()
	content.name = "AbilityContent"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	_abilities_view.add_child(content)
	var tree_column := VBoxContainer.new()
	tree_column.name = "TreeColumn"
	tree_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_column.add_theme_constant_override("separation", 5)
	content.add_child(tree_column)

	_tree_scroll = ScrollContainer.new()
	_tree_scroll.name = "TreeScroll"
	_tree_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tree_column.add_child(_tree_scroll)
	var vertical_scroll := _tree_scroll.get_v_scroll_bar()
	vertical_scroll.custom_minimum_size.x = 18
	vertical_scroll.add_theme_stylebox_override("scroll", _style(Color("241e20"), Color("5c4934"), 7, 2, 0))
	vertical_scroll.add_theme_stylebox_override("grabber", _style(GOLD, Color("f4d17a"), 7, 2, 0))
	vertical_scroll.add_theme_stylebox_override("grabber_highlight", _style(GOLD_BRIGHT, CREAM, 7, 2, 0))
	vertical_scroll.add_theme_stylebox_override("grabber_pressed", _style(Color("cf9436"), CREAM, 7, 2, 0))
	_tree_cache_root = MarginContainer.new()
	_tree_cache_root.name = "TreeCache"
	_tree_cache_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree_cache_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree_cache_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tree_scroll.add_child(_tree_cache_root)
	_tree_scroll_hint = Label.new()
	_tree_scroll_hint.name = "ScrollHint"
	_tree_scroll_hint.text = "↓  DESLIZA PARA VER MÁS  ↓"
	_tree_scroll_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tree_scroll_hint.add_theme_font_size_override("font_size", 18)
	_tree_scroll_hint.add_theme_color_override("font_color", GOLD_BRIGHT)
	tree_column.add_child(_tree_scroll_hint)

	content.add_child(_build_detail_panel())
	_collectibles_view = CollectiblesViewClass.new() as CollectiblesView
	_frame.add_child(_collectibles_view)
	_build_objectives_view()
	_build_documents_view()
	_build_recordings_view()


func _build_detail_panel() -> PanelContainer:
	var detail_panel := PanelContainer.new()
	detail_panel.name = "UpgradeDetail"
	detail_panel.custom_minimum_size.x = 430
	detail_panel.add_theme_stylebox_override("panel", _style(Color("211d20"), Color("755c32"), 9, 2, 18))
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 12)
	detail_panel.add_child(detail)
	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 31)
	_detail_title.add_theme_color_override("font_color", CREAM)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_title)
	var thin_line := ColorRect.new()
	thin_line.custom_minimum_size.y = 1
	thin_line.color = Color("a67c36")
	detail.add_child(thin_line)
	_detail_current = _detail_label(23, CREAM)
	detail.add_child(_detail_current)
	_detail_next = _detail_label(23, GOLD_BRIGHT)
	detail.add_child(_detail_next)
	_detail_description = _detail_label(20, Color("d3c6b5"))
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_description)
	var thick_line := ColorRect.new()
	thick_line.custom_minimum_size.y = 3
	thick_line.color = Color("a67c36")
	detail.add_child(thick_line)
	var cost_row := HBoxContainer.new()
	cost_row.name = "UpgradeCost"
	cost_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	cost_row.custom_minimum_size.y = 52
	cost_row.add_theme_constant_override("separation", 12)
	detail.add_child(cost_row)
	var cost_title := _detail_label(32, CREAM)
	cost_title.text = "COSTE:"
	cost_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cost_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_row.add_child(cost_title)
	var coin_icon := TextureRect.new()
	coin_icon.name = "CoinIcon"
	coin_icon.custom_minimum_size = Vector2(50, 50)
	coin_icon.texture = COIN_ICON
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_row.add_child(coin_icon)
	_detail_cost = _detail_label(38, GOLD_BRIGHT)
	_detail_cost.name = "CostValue"
	_detail_cost.custom_minimum_size.x = 100
	_detail_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_row.add_child(_detail_cost)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)
	_buy_button = Button.new()
	_buy_button.name = "BuyUpgrade"
	_buy_button.text = "COMPRAR"
	_buy_button.custom_minimum_size.y = 64
	_buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_buy_button.add_theme_font_size_override("font_size", 27)
	_buy_button.add_theme_color_override("font_color", Color("21140f"))
	_buy_button.add_theme_color_override("font_disabled_color", Color("78706a"))
	_buy_button.add_theme_stylebox_override("normal", _style(GOLD, Color("f6d783"), 7, 2, 10))
	_buy_button.add_theme_stylebox_override("hover", _style(GOLD_BRIGHT, CREAM, 7, 3, 10))
	_buy_button.add_theme_stylebox_override("pressed", _style(Color("c58f37"), CREAM, 7, 2, 10))
	_buy_button.add_theme_stylebox_override("disabled", _style(Color("393438"), Color("514b4e"), 7, 2, 10))
	_buy_button.pressed.connect(_purchase_selected)
	detail.add_child(_buy_button)
	return detail_panel


func _build_objectives_view() -> void:
	_objectives_view = VBoxContainer.new()
	_objectives_view.name = "ObjectivesView"
	_objectives_view.visible = false
	_objectives_view.add_theme_constant_override("separation", 14)
	_frame.add_child(_objectives_view)
	var header := Label.new()
	header.text = "OBJETIVOS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", CREAM)
	_objectives_view.add_child(header)
	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _line_style(Color("7e622f"), 2))
	_objectives_view.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.name = "ObjectivesScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_objectives_view.add_child(scroll)
	_objectives_list = VBoxContainer.new()
	_objectives_list.name = "ObjectiveRows"
	_objectives_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objectives_list.add_theme_constant_override("separation", 12)
	scroll.add_child(_objectives_list)


func _refresh_objectives() -> void:
	if _manager == null or _objectives_list == null:
		return
	_clear_children(_objectives_list)
	var clean_percent: float = _manager.get_clean_percent()
	_objectives_list.add_child(_make_objective_row(
		"LIMPIAR LA SALA 1",
		"Completado" if _manager.room_completed else ("Progreso: %.2f %%" % clean_percent).replace(".", ","),
		bool(_manager.room_completed), "Recompensa: 0,50 monedas"
	))
	for objective in _manager.get_cinema_objectives():
		_objectives_list.add_child(_make_objective_row(
			String(objective.title), String(objective.progress).replace(".", ","),
			bool(objective.completed), String(objective.hint) + "  Recompensa: %s monedas" % _manager.format_money(int(_manager.Rules.OBJECTIVE_REWARDS.get(objective.id,0)))
		))
	var document_count := int(_manager.get_found_document_count())
	if document_count > 0:
		_objectives_list.add_child(_make_objective_row(
			"DESCUBRE LA VERDAD",
			"%d / 12" % document_count,
			document_count >= 12
		))
	var collectible_count := int(_manager.get_found_collectible_count())
	if collectible_count > 0:
		_objectives_list.add_child(_make_objective_row(
			"¡COLECCIÓNALOS TODOS!",
			"%d / %d" % [collectible_count, _manager.get_total_collectible_count()],
			collectible_count >= _manager.get_total_collectible_count()
		))


func _make_objective_row(title_text: String, progress_text: String, completed: bool, hint_text: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 138 if not hint_text.is_empty() else 116
	panel.add_theme_stylebox_override("panel", _style(Color("201b1e"), GOLD if completed else Color("5b4632"), 9, 3 if completed else 2, 14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var stamp_space := CenterContainer.new()
	stamp_space.custom_minimum_size = Vector2(86, 86)
	row.add_child(stamp_space)
	if completed:
		var stamp := TextureRect.new()
		stamp.custom_minimum_size = Vector2(78, 78)
		stamp.texture = POPCORN_STAMP_ICON
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stamp_space.add_child(stamp)
	else:
		var unchecked := Label.new()
		unchecked.text = "○"
		unchecked.add_theme_font_size_override("font_size", 62)
		unchecked.add_theme_color_override("font_color", Color("786b62"))
		stamp_space.add_child(unchecked)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_stack)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", CREAM)
	text_stack.add_child(title)
	var progress := Label.new()
	progress.text = progress_text
	progress.add_theme_font_size_override("font_size", 23)
	progress.add_theme_color_override("font_color", GOLD_BRIGHT if completed else Color("c9bcae"))
	text_stack.add_child(progress)
	if not hint_text.is_empty():
		var hint := Label.new()
		hint.text = hint_text
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", 18)
		hint.add_theme_color_override("font_color", MUTED)
		text_stack.add_child(hint)
	return panel


func _build_documents_view() -> void:
	_documents_view = VBoxContainer.new()
	_documents_view.name = "DocumentsView"
	_documents_view.visible = false
	_documents_view.add_theme_constant_override("separation", 12)
	_frame.add_child(_documents_view)

	_documents_header = Label.new()
	_documents_header.name = "DocumentsHeader"
	_documents_header.add_theme_font_size_override("font_size", 31)
	_documents_header.add_theme_color_override("font_color", CREAM)
	_documents_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_documents_view.add_child(_documents_header)

	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _line_style(Color("7e622f"), 1))
	_documents_view.add_child(separator)

	var content := HBoxContainer.new()
	content.name = "DocumentsContent"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	_documents_view.add_child(content)

	var list_panel := PanelContainer.new()
	list_panel.name = "DocumentListPanel"
	list_panel.custom_minimum_size.x = 390
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_stretch_ratio = 0.40
	list_panel.add_theme_stylebox_override("panel", _style(Color("201b1e"), Color("614a32"), 8, 2, 12))
	content.add_child(list_panel)
	var list_scroll := ScrollContainer.new()
	list_scroll.name = "DocumentListScroll"
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)
	_documents_list = VBoxContainer.new()
	_documents_list.name = "DocumentRows"
	_documents_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_documents_list.add_theme_constant_override("separation", 8)
	list_scroll.add_child(_documents_list)

	var paper := PanelContainer.new()
	paper.name = "DocumentPaper"
	paper.custom_minimum_size.x = 590
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.size_flags_stretch_ratio = 0.60
	paper.add_theme_stylebox_override("panel", _style(Color("eadcb8"), Color("8c6c43"), 5, 3, 28))
	content.add_child(paper)
	var paper_content := VBoxContainer.new()
	paper_content.name = "PaperContent"
	paper_content.add_theme_constant_override("separation", 8)
	paper.add_child(paper_content)
	_document_title = Label.new()
	_document_title.name = "DocumentTitle"
	_document_title.add_theme_font_size_override("font_size", 32)
	_document_title.add_theme_color_override("font_color", Color("251d1a"))
	_document_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper_content.add_child(_document_title)
	_document_subtitle = Label.new()
	_document_subtitle.name = "DocumentSubtitle"
	_document_subtitle.add_theme_font_size_override("font_size", 19)
	_document_subtitle.add_theme_color_override("font_color", Color("66564a"))
	_document_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper_content.add_child(_document_subtitle)
	var paper_line := HSeparator.new()
	paper_line.add_theme_stylebox_override("separator", _line_style(Color("9f825a"), 1))
	paper_content.add_child(paper_line)
	_document_scroll = ScrollContainer.new()
	_document_scroll.name = "DocumentBodyScroll"
	_document_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_document_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_document_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper_content.add_child(_document_scroll)
	_document_body = Label.new()
	_document_body.name = "DocumentBody"
	_document_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_document_body.add_theme_font_size_override("font_size", 21)
	_document_body.add_theme_color_override("font_color", Color("2c2521"))
	_document_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_document_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_document_scroll.add_child(_document_body)


func _build_recordings_view() -> void:
	_recordings_view = VBoxContainer.new()
	_recordings_view.name = "RecordingsView"
	_recordings_view.visible = false
	_recordings_view.add_theme_constant_override("separation", 12)
	_frame.add_child(_recordings_view)
	var header := Label.new()
	header.name = "RecordingsHeader"
	header.text = "GRABACIONES"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 31)
	header.add_theme_color_override("font_color", CREAM)
	_recordings_view.add_child(header)
	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _line_style(Color("7e622f"), 1))
	_recordings_view.add_child(separator)
	var content := HBoxContainer.new()
	content.name = "RecordingsContent"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	_recordings_view.add_child(content)
	var list_panel := PanelContainer.new()
	list_panel.name = "RecordingListPanel"
	list_panel.custom_minimum_size.x = 390
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.size_flags_stretch_ratio = 0.40
	list_panel.add_theme_stylebox_override("panel", _style(Color("201b1e"), Color("614a32"), 8, 2, 12))
	content.add_child(list_panel)
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(list_scroll)
	_recordings_list = VBoxContainer.new()
	_recordings_list.name = "RecordingRows"
	_recordings_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recordings_list.add_theme_constant_override("separation", 8)
	list_scroll.add_child(_recordings_list)
	var transcript := PanelContainer.new()
	transcript.name = "RecordingTranscript"
	transcript.custom_minimum_size.x = 590
	transcript.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transcript.size_flags_vertical = Control.SIZE_EXPAND_FILL
	transcript.size_flags_stretch_ratio = 0.60
	transcript.add_theme_stylebox_override("panel", _style(Color("211d20"), Color("8c6c43"), 5, 3, 28))
	content.add_child(transcript)
	var transcript_content := VBoxContainer.new()
	transcript_content.add_theme_constant_override("separation", 10)
	transcript.add_child(transcript_content)
	_recording_title = Label.new()
	_recording_title.name = "RecordingTitle"
	_recording_title.add_theme_font_size_override("font_size", 32)
	_recording_title.add_theme_color_override("font_color", CREAM)
	transcript_content.add_child(_recording_title)
	_recording_narrator = Label.new()
	_recording_narrator.name = "RecordingNarrator"
	_recording_narrator.add_theme_font_size_override("font_size", 21)
	_recording_narrator.add_theme_color_override("font_color", GOLD_BRIGHT)
	transcript_content.add_child(_recording_narrator)
	var transcript_line := HSeparator.new()
	transcript_line.add_theme_stylebox_override("separator", _line_style(Color("9f825a"), 1))
	transcript_content.add_child(transcript_line)
	_recording_scroll = ScrollContainer.new()
	_recording_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recording_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recording_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	transcript_content.add_child(_recording_scroll)
	_recording_body = Label.new()
	_recording_body.name = "RecordingBody"
	_recording_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recording_body.add_theme_font_size_override("font_size", 22)
	_recording_body.add_theme_color_override("font_color", CREAM)
	_recording_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recording_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_recording_scroll.add_child(_recording_body)


func _build_discovery_notification() -> void:
	var notification_root := Control.new()
	notification_root.name = "DiscoveryNotificationRoot"
	notification_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notification_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notification_root)
	_notification_panel = PanelContainer.new()
	_notification_panel.name = "DiscoveryNotification"
	_notification_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notification_panel.position = Vector2(-270, -125)
	_notification_panel.size = Vector2(540, 108)
	_notification_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.add_theme_stylebox_override("panel", _style(Color("42141dec"), GOLD, 9, 2, 14))
	notification_root.add_child(_notification_panel)
	var text_stack := VBoxContainer.new()
	text_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.add_child(text_stack)
	_notification_title = Label.new()
	_notification_title.name = "DiscoveryTitle"
	_notification_title.text = "Documento encontrado"
	_notification_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_title.add_theme_font_override("font", HUD_FONT)
	_notification_title.add_theme_font_size_override("font_size", 28)
	_notification_title.add_theme_color_override("font_color", CREAM)
	_notification_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_child(_notification_title)
	_notification_hint = Label.new()
	_notification_hint.name = "DiscoveryHint"
	_notification_hint.text = "Pulsa Tab para verlo"
	_notification_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_hint.add_theme_font_override("font", HUD_FONT)
	_notification_hint.add_theme_font_size_override("font_size", 21)
	_notification_hint.add_theme_color_override("font_color", GOLD_BRIGHT)
	_notification_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_child(_notification_hint)
	_notification_panel.visible = false


func _show_discovery_notification(
	discovery_type: StringName,
	item_id: String,
	notification_title: String,
	notification_hint: String,
	target_section: StringName
) -> void:
	_pending_discovery_type = discovery_type
	_pending_discovery_item_id = item_id
	_pending_discovery_section = target_section
	_notification_title.text = notification_title
	_notification_hint.text = notification_hint
	_notification_generation += 1
	var generation := _notification_generation
	_notification_active = true
	if _notification_tween and _notification_tween.is_valid():
		_notification_tween.kill()
	_notification_panel.visible = true
	_notification_panel.modulate.a = 0.0
	_notification_panel.position.y = -105.0
	_notification_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_notification_tween.set_parallel(true)
	_notification_tween.tween_property(_notification_panel, "position:y", 24.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_notification_tween.tween_property(_notification_panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(DISCOVERY_NOTIFICATION_DURATION, true).timeout
	if generation != _notification_generation or not _notification_active:
		return
	_notification_active = false
	_notification_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_notification_tween.set_parallel(true)
	_notification_tween.tween_property(_notification_panel, "position:y", -90.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_notification_tween.tween_property(_notification_panel, "modulate:a", 0.0, 0.16)
	_notification_tween.finished.connect(_finish_discovery_notification_hide.bind(generation), CONNECT_ONE_SHOT)


func _finish_discovery_notification_hide(generation: int) -> void:
	if generation == _notification_generation:
		_notification_panel.visible = false


func _hide_discovery_notification() -> void:
	_notification_generation += 1
	_notification_active = false
	if _notification_tween and _notification_tween.is_valid():
		_notification_tween.kill()
	_notification_panel.visible = false


func _select_primary_section(section_id: StringName) -> void:
	if section_id == &"documents" and (_manager == null or _manager.get_found_document_count() <= 0):
		return
	if section_id == &"collectibles" and (_manager == null or _manager.get_found_collectible_count() <= 0):
		return
	if section_id not in [&"abilities", &"objectives", &"collectibles", &"documents", &"recordings"]:
		return
	if _section == &"documents" and section_id != &"documents":
		_emit_selected_document_closed()
	_section = section_id
	_apply_section_pause()
	_refresh()


func _apply_section_pause() -> void:
	if not is_open():
		return
	var archive_section_open := _section in [&"documents", &"collectibles", &"recordings"]
	if archive_section_open and not _paused_by_archive:
		get_tree().paused = true
		_paused_by_archive = true
	elif not archive_section_open and _paused_by_archive:
		get_tree().paused = false
		_paused_by_archive = false


func _refresh_documents(target_document_id: String = "") -> void:
	if _manager == null:
		return
	var found_documents: Array[Dictionary] = _manager.get_document_definitions(true)
	_documents_header.text = "DOCUMENTOS ENCONTRADOS %d / %d" % [found_documents.size(), _manager.get_total_document_count()]
	var found_ids: Array[String] = []
	for definition in found_documents:
		found_ids.append(String(definition.id))
	var existing_ids: Array[String] = []
	for document_id in _document_rows:
		existing_ids.append(String(document_id))
	found_ids.sort()
	existing_ids.sort()
	if not found_documents.is_empty() and found_ids == existing_ids:
		var retained := target_document_id if not target_document_id.is_empty() else _selected_document_id
		if retained.is_empty() or not _manager.is_document_found(retained):
			retained = _choose_default_document(found_documents)
		_selected_document_id = retained
		_display_document(_selected_document_id)
		_refresh_document_row_states()
		var retained_row := _document_rows.get(_selected_document_id) as Button
		if retained_row and retained_row.is_inside_tree():
			retained_row.grab_focus()
		return
	_document_rows.clear()
	_clear_children(_documents_list)
	if found_documents.is_empty():
		_document_title.text = ""
		_document_subtitle.text = ""
		_document_body.text = ""
		return

	var requested := target_document_id if not target_document_id.is_empty() else _selected_document_id
	if requested.is_empty():
		requested = String(_manager.last_selected_document_id)
	if requested.is_empty() or not _manager.is_document_found(requested):
		requested = _choose_default_document(found_documents)
	_selected_document_id = requested
	for definition in found_documents:
		var row := _make_document_row(definition)
		_documents_list.add_child(row)
		_document_rows[String(definition.id)] = row
	_display_document(_selected_document_id)
	var selected_row := _document_rows.get(_selected_document_id) as Button
	if selected_row and selected_row.is_inside_tree():
		selected_row.grab_focus()


func _choose_default_document(found_documents: Array[Dictionary]) -> String:
	for definition in found_documents:
		if not bool(definition.get("read", false)):
			return String(definition.id)
	return String(found_documents[0].id)


func _make_document_row(definition: Dictionary) -> Button:
	var document_id := String(definition.id)
	var selected := document_id == _selected_document_id
	var row := Button.new()
	row.name = "Document_%s" % document_id.to_pascal_case()
	row.custom_minimum_size.y = 72
	row.focus_mode = Control.FOCUS_ALL
	row.pressed.connect(_select_document.bind(document_id))
	row.focus_entered.connect(_select_document.bind(document_id))
	row.add_theme_stylebox_override("normal", _style(BURGUNDY_LIGHT if selected else CHARCOAL_LIGHT, GOLD if selected else Color("514347"), 6, 3 if selected else 1, 8))
	row.add_theme_stylebox_override("hover", _style(Color("60303a"), GOLD, 6, 2, 8))
	row.add_theme_stylebox_override("pressed", _style(BURGUNDY, GOLD_BRIGHT, 6, 3, 8))
	row.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD_BRIGHT, 6, 3, 8))
	PointerTheme.set_button_cursor(row)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(margin)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 11)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(42, 42)
	icon.texture = DOCUMENT_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var title := Label.new()
	title.text = String(definition.title)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", CREAM)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	var unread := PanelContainer.new()
	unread.name = "Unread"
	unread.custom_minimum_size = Vector2(15, 15)
	unread.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	unread.add_theme_stylebox_override("panel", _style(GOLD_BRIGHT, Color("ffdf86"), 20, 1, 0))
	unread.visible = not bool(definition.get("read", false))
	unread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(unread)
	return row


func _select_document(document_id: String) -> void:
	if _section != &"documents" or document_id == _selected_document_id and _manager.is_document_read(document_id):
		return
	if document_id != _selected_document_id:
		_emit_selected_document_closed()
	_selected_document_id = document_id
	_display_document(document_id)
	_refresh_document_row_states()


func _emit_selected_document_closed() -> void:
	if _section == &"documents" and not _selected_document_id.is_empty() and _manager != null and _manager.is_document_read(_selected_document_id):
		document_closed.emit(_selected_document_id)


func _refresh_recordings(target_recording_id: String = "") -> void:
	if _manager == null:
		return
	var found_recordings: Array[Dictionary] = _manager.get_found_recording_definitions()
	var found_ids: Array[String] = []
	for definition in found_recordings:
		found_ids.append(String(definition.id))
	var existing_ids: Array[String] = []
	for recording_id in _recording_rows:
		existing_ids.append(String(recording_id))
	if found_ids != existing_ids:
		_recording_rows.clear()
		_clear_children(_recordings_list)
		for definition in found_recordings:
			var row := _make_recording_row(String(definition.id))
			_recordings_list.add_child(row)
			_recording_rows[String(definition.id)] = row
	if found_recordings.is_empty():
		_selected_recording_id = ""
		_recording_title.text = "AÚN NO HAY GRABACIONES"
		_recording_narrator.text = ""
		_recording_body.text = "Las cintas que encuentres aparecerán aquí."
		return
	var selected := target_recording_id if not target_recording_id.is_empty() else _selected_recording_id
	if not _manager.is_recording_found(selected):
		selected = String(found_recordings[0].id)
	_select_recording(selected)


func _make_recording_row(recording_id: String) -> Button:
	var row := Button.new()
	row.name = "Recording_%s" % recording_id
	row.text = "Grabación %s" % recording_id
	row.icon = CASSETTE_ICON
	row.expand_icon = true
	row.custom_minimum_size.y = 72
	row.focus_mode = Control.FOCUS_ALL
	row.add_theme_font_size_override("font_size", 22)
	row.add_theme_color_override("font_color", CREAM)
	row.add_theme_constant_override("icon_max_width", 42)
	row.add_theme_stylebox_override("normal", _style(CHARCOAL_LIGHT, Color("514347"), 6, 1, 8))
	row.add_theme_stylebox_override("hover", _style(Color("60303a"), GOLD, 6, 2, 8))
	row.add_theme_stylebox_override("pressed", _style(BURGUNDY, GOLD_BRIGHT, 6, 3, 8))
	row.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD_BRIGHT, 6, 3, 8))
	row.pressed.connect(_select_recording.bind(recording_id))
	row.focus_entered.connect(_select_recording.bind(recording_id))
	PointerTheme.set_button_cursor(row)
	return row


func _select_recording(recording_id: String) -> void:
	if _section != &"recordings" or _manager == null or not _manager.is_recording_found(recording_id):
		return
	var definition := RecordingCatalog.get_definition(recording_id)
	if definition.is_empty():
		return
	_selected_recording_id = recording_id
	_recording_title.text = "GRABACIÓN %s" % recording_id
	_recording_narrator.text = "%s:" % RecordingCatalog.narrator_for(recording_id, _manager.is_recording_heard("13"))
	_recording_body.text = "\n\n".join(PackedStringArray(definition.lines))
	_recording_scroll.scroll_vertical = 0
	for row_id in _recording_rows:
		var row := _recording_rows[row_id] as Button
		var selected := String(row_id) == recording_id
		row.add_theme_stylebox_override("normal", _style(BURGUNDY_LIGHT if selected else CHARCOAL_LIGHT, GOLD if selected else Color("514347"), 6, 3 if selected else 1, 8))


func _display_document(document_id: String) -> void:
	var definition: Dictionary = _manager.get_document_definition(document_id) if _manager else {}
	if definition.is_empty() or not bool(definition.get("found", false)):
		return
	_document_title.text = String(definition.title)
	_document_subtitle.text = String(definition.subtitle)
	# Label se usa deliberadamente en lugar de RichTextLabel: el contenido TXT
	# se muestra literalmente y nunca interpreta BBCode accidental.
	_document_body.text = String(definition.body)
	_document_scroll.scroll_vertical = 0
	_document_scroll.call_deferred("set_v_scroll", 0)
	_manager.mark_document_read(document_id)
	_refresh_document_row_states()


func _refresh_document_row_states() -> void:
	for document_id in _document_rows:
		var row := _document_rows[document_id] as Button
		var selected := String(document_id) == _selected_document_id
		row.add_theme_stylebox_override("normal", _style(BURGUNDY_LIGHT if selected else CHARCOAL_LIGHT, GOLD if selected else Color("514347"), 6, 3 if selected else 1, 8))
		var unread := row.find_child("Unread", true, false) as Control
		if unread:
			unread.visible = not _manager.is_document_read(String(document_id))


func _build_tab_footer() -> void:
	var footer := HBoxContainer.new()
	footer.name = "TabHint"
	footer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(280, -102)
	footer.size = Vector2(410, 48)
	footer.add_theme_constant_override("separation", 12)
	_menu_shell.add_child(footer)
	_add_footer_shortcut(footer, "TAB", "CERRAR")
	_add_footer_shortcut(footer, "ESC", "SALIR")


func _add_footer_shortcut(footer: HBoxContainer, shortcut: String, action: String) -> void:
	var key := PanelContainer.new()
	key.name = "%sKey" % shortcut
	key.custom_minimum_size = Vector2(62, 42)
	key.add_theme_stylebox_override("panel", _style(Color("241a1d"), GOLD, 6, 2, 6))
	footer.add_child(key)
	var key_text := Label.new()
	key_text.text = shortcut
	key_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_text.add_theme_font_size_override("font_size", 21)
	key_text.add_theme_color_override("font_color", CREAM)
	key.add_child(key_text)
	var close_text := Label.new()
	close_text.name = "%sLabel" % shortcut
	close_text.text = action
	close_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_text.add_theme_font_size_override("font_size", 21)
	close_text.add_theme_color_override("font_color", CREAM)
	footer.add_child(close_text)


func _refresh(target_item_id: String = "") -> void:
	_state_refresh_queued = false
	if _tree_scroll == null:
		return
	_refresh_primary_sections()
	_abilities_view.visible = _section == &"abilities"
	_objectives_view.visible = _section == &"objectives"
	_collectibles_view.visible = _section == &"collectibles"
	_documents_view.visible = _section == &"documents"
	_recordings_view.visible = _section == &"recordings"
	_collectibles_view.set_active(_section == &"collectibles" and is_open())
	if _section == &"objectives":
		_refresh_objectives()
		return
	if _section == &"collectibles":
		_collectibles_view.refresh(target_item_id)
		return
	if _section == &"documents":
		_refresh_documents(target_item_id)
		return
	if _section == &"recordings":
		_refresh_recordings(target_item_id)
		return
	if _category in [&"vacuum", &"broom"] and _is_category_locked(_category):
		_category = &"collection"
		_select_default_branch()
	_rebuild_tabs()
	_rebuild_tree()
	_update_detail()


func _queue_visible_state_refresh() -> void:
	if not is_open() or _state_refresh_queued:
		return
	_state_refresh_queued = true
	call_deferred("_flush_visible_state_refresh")


func _flush_visible_state_refresh() -> void:
	if not _state_refresh_queued:
		return
	_state_refresh_queued = false
	if is_open():
		_refresh()


func _rebuild_tabs() -> void:
	for category_index in UpgradeCatalog.CATEGORIES.size():
		var category: StringName = UpgradeCatalog.CATEGORIES[category_index]
		var locked := _is_category_locked(category)
		var selected := category == _category
		var button: Button
		if category_index < _tab_bar.get_child_count():
			button = _tab_bar.get_child(category_index) as Button
		else:
			button = Button.new()
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size.y = 50
			button.add_theme_font_override("font", HUD_FONT)
			button.pressed.connect(_select_category.bind(category))
			_tab_bar.add_child(button)
		var visual_signature := "%s|%s" % [locked, selected]
		if String(button.get_meta("visual_signature", "")) == visual_signature:
			continue
		button.set_meta("visual_signature", visual_signature)
		button.text = "?" if locked else String(UpgradeCatalog.CATEGORY_TITLES[String(category)])
		button.disabled = locked
		PointerTheme.set_button_cursor(button)
		button.add_theme_font_size_override("font_size", 34 if locked else 25)
		button.add_theme_color_override("font_color", CHARCOAL if selected else CREAM)
		button.add_theme_color_override("font_disabled_color", MUTED)
		button.add_theme_stylebox_override("normal", _style(GOLD if selected else BURGUNDY, GOLD_BRIGHT if selected else BURGUNDY_LIGHT, 5, 2, 8))
		button.add_theme_stylebox_override("hover", _style(BURGUNDY_LIGHT, GOLD, 5, 2, 8))
		button.add_theme_stylebox_override("disabled", _style(Color("27272a"), Color("4c4b50"), 5, 2, 8))


func _rebuild_tree() -> void:
	_category_selection_is_valid()
	if _tree_scroll_hint:
		_tree_scroll_hint.visible = _category == &"collection"
	var requested_tree := _ensure_category_tree(_category)
	if requested_tree == null:
		return
	if _tree != requested_tree:
		if _tree != null:
			_tree.visible = false
		requested_tree.visible = true
		_tree = requested_tree
	_refresh_tree_state(_category)


func _ensure_category_tree(category: StringName) -> VBoxContainer:
	var category_key := String(category)
	var category_tree := _category_trees.get(category_key) as VBoxContainer
	if category_tree == null:
		category_tree = VBoxContainer.new()
		category_tree.name = "Tree_%s" % category_key.to_pascal_case()
		category_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_tree.add_theme_constant_override("separation", 10)
		category_tree.visible = false
		_category_trees[category_key] = category_tree
		_category_built_branch_counts[category_key] = 0
		_tree_cache_root.add_child(category_tree)
	var branches := UpgradeCatalog.get_category_branches(category)
	var built_count := int(_category_built_branch_counts.get(category_key, 0))
	var added_branches := false
	var build_signature := _get_category_state_signature(category)
	while built_count < branches.size():
		category_tree.add_child(_make_branch_row(branches[built_count]))
		built_count += 1
		added_branches = true
		_category_built_branch_counts[category_key] = built_count
	if added_branches and build_signature == _get_category_state_signature(category):
		_category_render_signatures[category_key] = build_signature
	return category_tree


func _prewarm_collection_tree() -> void:
	var category := &"collection"
	var category_key := String(category)
	var category_tree := _category_trees.get(category_key) as VBoxContainer
	if category_tree == null:
		category_tree = VBoxContainer.new()
		category_tree.name = "Tree_Collection"
		category_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_tree.add_theme_constant_override("separation", 10)
		category_tree.visible = false
		_category_trees[category_key] = category_tree
		_category_built_branch_counts[category_key] = 0
		_tree_cache_root.add_child(category_tree)
	var branches := UpgradeCatalog.get_category_branches(category)
	var build_signature := _get_category_state_signature(category)
	while int(_category_built_branch_counts.get(category_key, 0)) < branches.size():
		var branch_index := int(_category_built_branch_counts.get(category_key, 0))
		category_tree.add_child(_make_branch_row(branches[branch_index]))
		_category_built_branch_counts[category_key] = branch_index + 1
		await get_tree().process_frame
	if build_signature == _get_category_state_signature(category):
		_category_render_signatures[category_key] = build_signature


func _refresh_tree_state(category: StringName) -> void:
	var category_key := String(category)
	var state_signature := _get_category_state_signature(category)
	var state_changed := String(_category_render_signatures.get(category_key, "")) != state_signature
	for catalog_branch in UpgradeCatalog.get_category_branches(category):
		var branch_id := StringName(catalog_branch.id)
		if not _branch_widgets.has(branch_id):
			continue
		var branch: Dictionary = _manager.get_upgrade_state(branch_id) if _manager else catalog_branch
		var widgets: Dictionary = _branch_widgets[branch_id]
		var current := int(branch.get("current_level", 0))
		var costs: Array = branch.costs
		var connectors: Array = widgets.connectors
		for connector_index in connectors.size():
			(connectors[connector_index] as ColorRect).color = BLUE if current >= connector_index + 1 else Color("514b4d")
		var levels: Array = widgets.levels
		for level_index in levels.size():
			var level_button := (levels[level_index] as Dictionary).button as Button
			var should_be_selected := branch_id == _selected_branch and _selected_level == level_index + 1
			var selection_changed := bool(level_button.get_meta("upgrade_selected", false)) != should_be_selected
			if state_changed or selection_changed:
				_configure_level_widget(levels[level_index], branch, level_index, current, int(costs[level_index]))
	_category_render_signatures[category_key] = state_signature


func _get_category_state_signature(category: StringName) -> String:
	var signature_parts: Array[String] = [str(int(_manager.coins)) if _manager else "0"]
	for branch in UpgradeCatalog.get_category_branches(category):
		var branch_id := StringName(branch.id)
		signature_parts.append("%s:%d" % [branch.id, _manager.get_upgrade_level(branch_id) if _manager else 0])
	return "|".join(signature_parts)


func _category_selection_is_valid() -> void:
	if UpgradeCatalog.get_branch(_selected_branch).get("category", "") != String(_category):
		_select_default_branch()


func _make_branch_row(branch: Dictionary) -> Control:
	if _manager:
		branch = _manager.get_upgrade_state(StringName(branch.id))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("201b1e"), Color("4f3c31"), 7, 1, 12))
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 130
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(78, 78)
	icon.texture = _load_icon(String(branch.id), String(branch.icon))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = CREAM
	row.add_child(icon)
	var info := Button.new()
	info.flat = true
	info.custom_minimum_size.x = 300
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	info.pressed.connect(_select_branch.bind(StringName(branch.id)))
	row.add_child(info)
	var info_stack := VBoxContainer.new()
	info_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(info_stack)
	var title := Label.new()
	title.text = String(branch.title)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CREAM)
	info_stack.add_child(title)
	var description := Label.new()
	description.text = String(branch.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 20)
	description.add_theme_color_override("font_color", Color("c8bbb0"))
	info_stack.add_child(description)

	var current: int = int(branch.get("current_level", 0))
	var costs: Array = branch.costs
	var levels_row := HBoxContainer.new()
	levels_row.name = "Levels"
	levels_row.alignment = BoxContainer.ALIGNMENT_CENTER
	levels_row.add_theme_constant_override("separation", 0)
	row.add_child(levels_row)
	var connectors: Array = []
	var level_widgets: Array = []
	for level_index in costs.size():
		if level_index > 0:
			var connector := _make_level_connector(BLUE if current >= level_index else Color("514b4d"))
			levels_row.add_child(connector)
			connectors.append(connector.get_child(0) as ColorRect)
		var level_node := _make_level_node(branch, level_index, current, int(costs[level_index]))
		levels_row.add_child(level_node)
		level_widgets.append({
			"button": level_node.get_node("Button") as Button,
			"price": level_node.get_node("Price") as Label,
		})
	_branch_widgets[StringName(branch.id)] = {
		"connectors": connectors,
		"levels": level_widgets,
	}
	return panel


func _make_level_connector(color: Color) -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(20, 3)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(20, 3)
	line.color = color
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(line)
	return center


func _make_level_node(branch: Dictionary, level_index: int, current: int, cost: int) -> Control:
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = 74
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	var button := Button.new()
	button.name = "Button"
	button.custom_minimum_size = Vector2(74, 74)
	button.add_theme_font_size_override("font_size", 27)
	button.pressed.connect(_select_level.bind(StringName(branch.id), level_index + 1))
	stack.add_child(button)
	var price := Label.new()
	price.name = "Price"
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 16)
	stack.add_child(price)
	_configure_level_widget({"button": button, "price": price}, branch, level_index, current, cost)
	return stack


func _configure_level_widget(widget: Dictionary, branch: Dictionary, level_index: int, current: int, cost: int) -> void:
	var level := level_index + 1
	var owned: bool = current >= level
	var is_next: bool = current + 1 == level
	var affordable: bool = is_next and _manager != null and int(_manager.coins) >= cost
	var selected: bool = StringName(branch.id) == _selected_branch and _selected_level == level
	var locked: bool = not owned and not is_next
	var button := widget.button as Button
	var price := widget.price as Label
	button.set_meta("upgrade_selected", selected)
	button.text = _roman(level)
	button.disabled = locked
	PointerTheme.set_button_cursor(button)
	var fill := BLUE if owned else GOLD if affordable else BURGUNDY if is_next else CHARCOAL_LIGHT
	var border := GOLD_BRIGHT if selected else Color("89acc8") if owned else Color("7f5f2e") if is_next else Color("4d4c50")
	var text_color := Color.WHITE if owned else CHARCOAL if affordable else CREAM if is_next else MUTED
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_stylebox_override("normal", _style(fill, border, 5, 4 if selected else 2, 4))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.10), GOLD_BRIGHT, 5, 4, 4))
	button.add_theme_stylebox_override("disabled", _style(CHARCOAL_LIGHT, border, 5, 2, 4))
	price.text = "✓" if owned else _manager.format_money(cost) if is_next else "—"
	price.add_theme_color_override("font_color", Color("8fb4d3") if owned else GOLD if is_next else Color("686568"))


func _update_detail() -> void:
	var branch: Dictionary = _manager.get_upgrade_state(_selected_branch) if _manager else UpgradeCatalog.get_branch(_selected_branch)
	if branch.is_empty():
		_detail_title.text = "SELECCIONA UNA MEJORA"
		_detail_current.text = ""
		_detail_next.text = ""
		_detail_description.text = ""
		_detail_cost.text = "—"
		_buy_button.disabled = true
		PointerTheme.set_button_cursor(_buy_button)
		return
	var current: int = _manager.get_upgrade_level(_selected_branch) if _manager else 0
	var costs: Array = branch.costs
	var next_level := mini(current + 1, costs.size())
	var shown_level := clampi(_selected_level, 1, costs.size())
	_detail_title.text = "%s %s" % [String(branch.title).to_upper(), _roman(shown_level)]
	_detail_current.text = "NIVEL ACTUAL: %s" % (_roman(current) if current > 0 else "BASE")
	if current >= costs.size():
		_detail_next.text = "SIGUIENTE NIVEL: COMPLETADO"
		_detail_description.text = "%s\nValor final: %s" % [branch.description, _format_value(branch, UpgradeCatalog.get_value(branch, current))]
		_detail_cost.text = "—"
		_buy_button.text = "COMPLETADO"
		_buy_button.disabled = true
		PointerTheme.set_button_cursor(_buy_button)
		return
	_detail_next.text = "SIGUIENTE NIVEL: %s" % _roman(next_level)
	var current_value := UpgradeCatalog.get_value(branch, current)
	var next_value := UpgradeCatalog.get_value(branch, next_level)
	_detail_description.text = "%s\n\n%s  →  %s" % [branch.description, _format_value(branch, current_value), _format_value(branch, next_value)]
	if String(branch.id) == "sprint":
		_detail_description.text += "\nDuración: %s s" % _format_number(UpgradeCatalog.get_secondary_value(branch, next_level))
		_detail_description.text += "\nRecarga completa: %s s" % _format_number(UpgradeCatalog.get_sprint_recharge_time(branch, next_level))
	if branch.has("cooldowns"):
		_detail_description.text += "\nDuración: %s s" % _format_number(next_value)
		_detail_description.text += "\nCooldown: %s" % _format_duration(UpgradeCatalog.get_ability_cooldown(branch, next_level))
	_detail_cost.text = _manager.format_money(int(costs[current]))
	_buy_button.text = "COMPRAR"
	_buy_button.disabled = _manager == null or not _manager.can_purchase_upgrade(_selected_branch)
	PointerTheme.set_button_cursor(_buy_button)


func _select_category(category: StringName) -> void:
	_category = category
	_select_default_branch()
	_refresh()


func _select_default_branch() -> void:
	var branches := UpgradeCatalog.get_category_branches(_category)
	if not branches.is_empty():
		_selected_branch = StringName(branches[0].id)
		_selected_level = _next_level_for(_selected_branch)


func _select_branch(branch_id: StringName) -> void:
	_selected_branch = branch_id
	_selected_level = _next_level_for(branch_id)
	_refresh_tree_state(_category)
	_update_detail()


func _select_level(branch_id: StringName, level: int) -> void:
	_selected_branch = branch_id
	_selected_level = level
	_refresh_tree_state(_category)
	_update_detail()


func _next_level_for(branch_id: StringName) -> int:
	var branch := UpgradeCatalog.get_branch(branch_id)
	var max_level: int = (branch.get("costs", []) as Array).size()
	var current: int = _manager.get_upgrade_level(branch_id) if _manager else 0
	return clampi(current + 1, 1, max_level)


func _purchase_selected() -> void:
	if _manager and _manager.purchase_upgrade(_selected_branch):
		_selected_level = _next_level_for(_selected_branch)
		_refresh()


func _is_category_locked(category: StringName) -> bool:
	return category in [&"vacuum", &"broom"] and (_manager == null or not _manager.owns_tool(category))


func _detail_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _format_value(branch: Dictionary, value: float) -> String:
	var unit := String(branch.get("unit", ""))
	if unit == "×":
		return "×%s" % _format_number(value)
	return "%s %s" % [_format_number(value), unit]


func _format_number(value: float) -> String:
	var result := str(int(value)) if is_equal_approx(value, roundf(value)) else ("%.2f" % value).trim_suffix("0")
	return result.replace(".", ",")


func _format_duration(seconds: float) -> String:
	if seconds >= 60.0 and is_equal_approx(fmod(seconds, 60.0), 0.0):
		var minutes := roundi(seconds / 60.0)
		return "%d min" % minutes
	return "%s s" % _format_number(seconds)


func _load_icon(branch_id: String, fallback_icon_name: String = "") -> Texture2D:
	if UPGRADE_ICON_FILES.has(branch_id):
		return load(UPGRADE_ICON_ROOT + String(UPGRADE_ICON_FILES[branch_id])) as Texture2D
	var fallback := fallback_icon_name if not fallback_icon_name.is_empty() else branch_id
	return load(ICON_ROOT + fallback + ".svg") as Texture2D


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _style(fill: Color, border: Color, radius: int, width: int, margin: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _line_style(color: Color, thickness: int) -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = color
	style.thickness = thickness
	return style


func _roman(level: int) -> String:
	return ["", "I", "II", "III", "IV", "V"][clampi(level, 0, 5)]
