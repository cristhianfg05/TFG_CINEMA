extends CanvasLayer

var _overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_overlay.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	_overlay.visible = should_pause
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if should_pause else Input.MOUSE_MODE_CAPTURED


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
	resume_button.pressed.connect(toggle_pause)
	buttons.add_child(resume_button)

	var menu_button := Button.new()
	menu_button.text = "Volver al menú"
	menu_button.custom_minimum_size = Vector2(360, 54)
	menu_button.pressed.connect(_return_to_menu)
	buttons.add_child(menu_button)


func _return_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
