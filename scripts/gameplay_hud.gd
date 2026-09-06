extends CanvasLayer

var _prompt_label: Label
var _bag_label: Label
var _coins_label: Label
var _clean_label: Label
var _lost_item_label: Label
var _objective_label: Label
var _notice_label: Label
var _manager: Node
var _notice_generation := 0


func _ready() -> void:
	add_to_group("gameplay_hud")
	_build_ui()
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	var player = get_tree().get_first_node_in_group("player")
	if _manager:
		_manager.state_changed.connect(_update_state)
		_manager.notification_requested.connect(_show_notification)
		_update_state()
	if player:
		player.interaction_prompt_changed.connect(_set_prompt)


func _build_ui() -> void:
	var root_control := Control.new()
	root_control.name = "HUDRoot"
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 26)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	crosshair.add_theme_color_override("font_outline_color", Color.BLACK)
	crosshair.add_theme_constant_override("outline_size", 4)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-20, -20)
	crosshair.size = Vector2(40, 40)
	root_control.add_child(crosshair)

	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 24)
	_prompt_label.add_theme_color_override("font_color", Color("ffe9a6"))
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 6)
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.position = Vector2(-400, -150)
	_prompt_label.size = Vector2(800, 50)
	root_control.add_child(_prompt_label)

	var stats := VBoxContainer.new()
	stats.name = "Stats"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.position = Vector2(24, 24)
	stats.add_theme_constant_override("separation", 4)
	root_control.add_child(stats)
	_bag_label = _make_stat_label()
	_coins_label = _make_stat_label()
	_clean_label = _make_stat_label()
	_lost_item_label = _make_stat_label()
	stats.add_child(_bag_label)
	stats.add_child(_coins_label)
	stats.add_child(_clean_label)
	stats.add_child(_lost_item_label)

	_objective_label = Label.new()
	_objective_label.name = "Objective"
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.add_theme_font_size_override("font_size", 21)
	_objective_label.add_theme_color_override("font_color", Color("d9ecff"))
	_objective_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_objective_label.add_theme_constant_override("outline_size", 5)
	_objective_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective_label.position = Vector2(-450, 24)
	_objective_label.size = Vector2(900, 38)
	root_control.add_child(_objective_label)

	_notice_label = Label.new()
	_notice_label.name = "Notice"
	_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_label.add_theme_font_size_override("font_size", 22)
	_notice_label.add_theme_color_override("font_color", Color("ffe59a"))
	_notice_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_notice_label.add_theme_constant_override("outline_size", 6)
	_notice_label.set_anchors_preset(Control.PRESET_CENTER)
	_notice_label.position = Vector2(-450, 95)
	_notice_label.size = Vector2(900, 90)
	root_control.add_child(_notice_label)


func _make_stat_label() -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	return label


func _set_prompt(prompt: String) -> void:
	_prompt_label.text = prompt


func _update_state() -> void:
	_bag_label.text = "Bolsa: %.1f / %.1f" % [_manager.bag_volume, _manager.bag_capacity]
	_coins_label.text = "Monedas: %d" % _manager.coins
	_clean_label.text = "Limpieza: %d %%" % _manager.get_clean_percent()
	_lost_item_label.text = (
		"Objeto perdido: en mano"
		if _manager.lost_item_state == "carried"
		else "Objeto perdido: resuelto"
		if _manager.lost_item_state in ["returned", "destroyed"]
		else "Objeto perdido: sin encontrar"
	)
	_objective_label.text = _manager.get_objective_text()


func _show_notification(message: String) -> void:
	_notice_generation += 1
	var generation := _notice_generation
	_notice_label.text = message
	await get_tree().create_timer(4.5).timeout
	if generation == _notice_generation:
		_notice_label.text = ""
