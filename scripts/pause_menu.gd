extends CanvasLayer

const PointerTheme := preload("res://scripts/pointer_theme.gd")

var _overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PointerTheme.apply_menu_cursors()
	_build_ui()
	_overlay.visible = false


func _input(event: InputEvent) -> void:
	if get_viewport().is_input_handled():
		return
	if _is_game_intro_active():
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		for group_name in ["arcade_minigame", "arcade_usher_minigame"]:
			var arcade := get_tree().get_first_node_in_group(group_name)
			if arcade and arcade.has_method("is_open") and arcade.is_open():
				return
		var upgrade_menu := get_tree().get_first_node_in_group("upgrade_menu")
		if upgrade_menu and upgrade_menu.is_open():
			return
		var tool_shop := get_tree().get_first_node_in_group("tool_shop_panel")
		if tool_shop and tool_shop.is_open():
			return
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if _is_game_intro_active():
		return
	var should_pause := not get_tree().paused
	if should_pause:
		var manager := get_tree().get_first_node_in_group("gameplay_manager")
		if manager and manager.has_method("set_vacuum_trigger_held"):
			manager.set_vacuum_trigger_held(false)
	get_tree().paused = should_pause
	_overlay.visible = should_pause
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if should_pause else Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _overlay != null and _overlay.visible


func _is_game_intro_active() -> bool:
	var intro = get_tree().get_first_node_in_group("game_intro")
	return bool(intro and intro.has_method("is_active") and intro.is_active())


func _build_ui() -> void:
	_overlay = Control.new()
	_overlay.name = "PauseOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.04, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var buttons := VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(360, 0)
	buttons.add_theme_constant_override("separation", 18)
	center.add_child(buttons)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	buttons.add_child(title)

	var resume_button := Button.new()
	resume_button.text = "Continuar"
	resume_button.custom_minimum_size = Vector2(360, 54)
	PointerTheme.set_button_cursor(resume_button)
	resume_button.pressed.connect(toggle_pause)
	buttons.add_child(resume_button)

	var menu_button := Button.new()
	menu_button.text = "Volver al menú"
	menu_button.custom_minimum_size = Vector2(360, 54)
	PointerTheme.set_button_cursor(menu_button)
	menu_button.pressed.connect(_return_to_menu)
	buttons.add_child(menu_button)


func _return_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
