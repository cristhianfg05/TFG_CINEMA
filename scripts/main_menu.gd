extends Control

const SAVE_PATH := "user://cinema_cleaner_save.json"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("171824")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(470, 0)
	content.add_theme_constant_override("separation", 18)
	center.add_child(content)

	var title := Label.new()
	title.text = "CINEMA CLEANER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("ffe59a"))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Vertical slice provisional — FASE 3"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	content.add_child(subtitle)

	var new_game := Button.new()
	new_game.text = "Nueva partida"
	new_game.custom_minimum_size = Vector2(470, 58)
	new_game.pressed.connect(_start_new_game)
	content.add_child(new_game)

	var continue_game := Button.new()
	continue_game.text = "Continuar"
	continue_game.custom_minimum_size = Vector2(470, 58)
	continue_game.disabled = not FileAccess.file_exists(SAVE_PATH)
	continue_game.pressed.connect(_continue_game)
	content.add_child(continue_game)

	var hint := Label.new()
	hint.text = "Clic derecho recoger · E interactuar · Clic izquierdo tirar reloj · Esc pausa"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	content.add_child(hint)


func _start_new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _continue_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
