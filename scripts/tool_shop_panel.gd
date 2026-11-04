class_name ToolShopPanel
extends CanvasLayer

const UpgradeCatalog := preload("res://resources/upgrades/upgrade_catalog.gd")
const PointerTheme := preload("res://scripts/pointer_theme.gd")
const HUD_FONT := preload("res://assets/fonts/PalaceHUD-Bold.ttf")
const INSPECTABLE_TOOLS: Array[StringName] = [&"hand_vacuum", &"broom"]
const CHARCOAL := Color("17191d")
const BURGUNDY := Color("42141d")
const BURGUNDY_LIGHT := Color("71303a")
const CREAM := Color("f3dfb0")
const GOLD := Color("e4ae4f")
const MUTED := Color("9d8d7e")

var _overlay: Control
var _cards: VBoxContainer
var _preview_container: SubViewportContainer
var _preview_viewport: SubViewport
var _preview_root: Node3D
var _name_label: Label
var _description_label: Label
var _price_label: Label
var _state_label: Label
var _buy_button: Button
var _cancel_button: Button
var _manager: Node
var _current_tool_id: StringName = &""
var _source_display: Node
var _purchase_completed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PointerTheme.apply_menu_cursors()
	add_to_group("tool_shop_panel")
	_build_ui()
	_overlay.visible = false
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	if _manager:
		_manager.state_changed.connect(_refresh)


func _process(delta: float) -> void:
	if is_open() and _preview_root:
		_preview_root.rotation.y += delta * 0.18


func _input(event: InputEvent) -> void:
	if not is_open() or get_viewport().is_input_handled():
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		close_shop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("upgrade_menu") and not event.is_echo():
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _overlay != null and _overlay.visible


func open_shop() -> void:
	for tool_id in INSPECTABLE_TOOLS:
		if _manager == null or not _manager.owns_tool(tool_id):
			open_tool(tool_id)
			return
	open_tool(&"vacuum")


func open_tool(tool_id: StringName, source_display: Node = null) -> void:
	var intro := get_tree().get_first_node_in_group("game_intro")
	var normalized_id: StringName = &"vacuum" if tool_id == &"hand_vacuum" else tool_id
	if _manager == null or get_tree().paused or normalized_id not in [&"vacuum", &"broom"]:
		return
	if intro and intro.has_method("is_active") and intro.is_active():
		return
	if _manager.has_method("set_vacuum_trigger_held"):
		_manager.set_vacuum_trigger_held(false)
	_current_tool_id = normalized_id
	_source_display = source_display
	_purchase_completed = false
	_rebuild_preview()
	_refresh()
	_overlay.visible = true
	_cancel_button.disabled = false
	PointerTheme.set_button_cursor(_cancel_button)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_set_hud_coins_above(true)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_overlay.modulate.a = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.20)


func close_shop() -> void:
	if not is_open():
		return
	_overlay.visible = false
	_cancel_button.disabled = true
	PointerTheme.set_button_cursor(_cancel_button)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_set_hud_coins_above(false)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _purchase_completed and is_instance_valid(_source_display) and _source_display.has_method("remove_after_purchase"):
		_source_display.remove_after_purchase()
	_source_display = null


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "ToolInspectionOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.012, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 760)
	panel.add_theme_stylebox_override("panel", _style(CHARCOAL, BURGUNDY_LIGHT, 14, 4, 28))
	center.add_child(panel)
	_cards = VBoxContainer.new()
	_cards.name = "InspectionContent"
	_cards.add_theme_constant_override("separation", 14)
	panel.add_child(_cards)
	var title := _label(22, GOLD)
	title.text = "MESA DEL MANAGER · INSPECCIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards.add_child(title)
	_preview_container = SubViewportContainer.new()
	_preview_container.custom_minimum_size = Vector2(760, 380)
	_preview_container.stretch = true
	_cards.add_child(_preview_container)
	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(760, 380)
	_preview_viewport.transparent_bg = true
	_preview_viewport.own_world_3d = true
	_preview_viewport.handle_input_locally = false
	_preview_container.add_child(_preview_viewport)
	_build_preview_world()
	_name_label = _label(34, CREAM)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards.add_child(_name_label)
	_description_label = _label(20, CREAM)
	_description_label.custom_minimum_size.y = 70
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cards.add_child(_description_label)
	_price_label = _label(26, GOLD)
	_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards.add_child(_price_label)
	_state_label = _label(18, MUTED)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards.add_child(_state_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	_cards.add_child(actions)
	_buy_button = Button.new()
	_buy_button.text = "COMPRAR"
	_buy_button.custom_minimum_size = Vector2(270, 58)
	_buy_button.disabled = true
	_buy_button.add_theme_font_override("font", HUD_FONT)
	_buy_button.add_theme_font_size_override("font_size", 22)
	_buy_button.pressed.connect(_purchase_current)
	actions.add_child(_buy_button)
	_cancel_button = Button.new()
	_cancel_button.text = "CANCELAR"
	_cancel_button.custom_minimum_size = Vector2(270, 58)
	_cancel_button.add_theme_font_override("font", HUD_FONT)
	_cancel_button.add_theme_font_size_override("font_size", 22)
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(close_shop)
	PointerTheme.set_button_cursor(_cancel_button)
	actions.add_child(_cancel_button)
	var hint := _label(16, MUTED)
	hint.text = "ESC — cancelar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cards.add_child(hint)


func _build_preview_world() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.65, 2.45)
	camera.fov = 34.0
	_preview_viewport.add_child(camera)
	camera.look_at(Vector3(0.0, 0.38, 0.0))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -28, 0)
	key.light_color = Color("ffd4a0")
	key.light_energy = 1.8
	_preview_viewport.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.3, 1.4, 1.5)
	fill.light_color = Color("d7a33e")
	fill.light_energy = 1.4
	fill.omni_range = 5.0
	_preview_viewport.add_child(fill)


func _rebuild_preview() -> void:
	if _preview_root:
		_preview_root.queue_free()
	var data: Dictionary = UpgradeCatalog.TOOL_DEFINITIONS.get(String(_current_tool_id), {})
	var packed := load(String(data.get("model", ""))) as PackedScene
	if packed == null:
		push_error("Missing indicated tool model for %s" % _current_tool_id)
		return
	_preview_root = Node3D.new()
	_preview_root.name = "VisualOnlyToolPreview"
	_preview_viewport.add_child(_preview_root)
	var model := packed.instantiate() as Node3D
	_preview_root.add_child(model)
	if _current_tool_id == &"vacuum":
		model.scale = Vector3.ONE * 1.75
		model.position = Vector3(0.0, 0.13, 0.0)
	else:
		model.scale = Vector3.ONE * 1.18
		model.position = Vector3(0.0, -0.02, 0.0)
	_remove_preview_gameplay_nodes(model)


func _remove_preview_gameplay_nodes(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject3D or child is NavigationRegion3D or child is NavigationAgent3D:
			child.queue_free()
		else:
			_remove_preview_gameplay_nodes(child)


func _refresh() -> void:
	if _manager == null or _current_tool_id.is_empty():
		return
	var data: Dictionary = UpgradeCatalog.TOOL_DEFINITIONS[String(_current_tool_id)]
	var owned: bool = _manager.owns_tool(_current_tool_id)
	var affordable: bool = _manager.coins >= int(data.cost)
	_name_label.text = String(data.title)
	_description_label.text = String(data.description)
	_price_label.text = "%s MONEDAS" % _manager.format_money(int(data.cost))
	_state_label.text = "COMPRADA" if owned else "" if affordable else "Monedas insuficientes"
	_buy_button.text = "COMPRADA" if owned else "COMPRAR"
	_buy_button.disabled = owned or not affordable
	PointerTheme.set_button_cursor(_buy_button)


func _purchase_current() -> void:
	if _manager and not _current_tool_id.is_empty() and _manager.purchase_tool(_current_tool_id):
		_purchase_completed = true
		_refresh()


func _set_hud_coins_above(enabled: bool) -> void:
	var hud := get_tree().get_first_node_in_group("gameplay_hud")
	if hud and hud.has_method("set_coin_overlay_above_menu"):
		hud.set_coin_overlay_above_menu(enabled)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", HUD_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style(fill: Color, border: Color, radius: int, width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style
