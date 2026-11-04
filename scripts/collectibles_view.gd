class_name CollectiblesView
extends VBoxContainer

const CollectibleCatalog := preload("res://resources/collectibles/collectible_catalog.gd")
const POSTER_UI_SHADER := preload("res://shaders/cinema_collectible_poster.gdshader")
const PointerTheme := preload("res://scripts/pointer_theme.gd")
const BURGUNDY := Color("42141d")
const BURGUNDY_LIGHT := Color("71303a")
const CHARCOAL := Color("17191d")
const CHARCOAL_LIGHT := Color("292c31")
const CREAM := Color("f3dfb0")
const GOLD := Color("e4ae4f")
const GOLD_BRIGHT := Color("f3c64e")
const MUTED := Color("8f8985")

var _manager: Node
var _header: Label
var _grid: GridContainer
var _large_preview_host: Control
var _detail_title: Label
var _detail_description: Label
var _detail_synopsis: Label
var _empty_message: Label
var _cards: Dictionary = {}
var _small_viewports: Array[SubViewport] = []
var _large_viewport: SubViewport
var _large_model_pivot: Node3D
var _selected_id := ""
var _built_found_signature := ""
var _active := false
var _dragging := false


func _ready() -> void:
	name = "CollectiblesView"
	visible = false
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_build_interface()


func setup(manager: Node) -> void:
	_manager = manager
	refresh()


func refresh(target_collectible_id: String = "") -> void:
	if _manager == null or _grid == null:
		return
	var found_definitions: Array[Dictionary] = _manager.get_collectible_definitions(true)
	_header.text = "COLECCIONABLES ENCONTRADOS %d / %d" % [found_definitions.size(), _manager.get_total_collectible_count()]
	var found_ids: Array[String] = []
	for definition in found_definitions:
		found_ids.append(String(definition.id))
	found_ids.sort()
	var found_signature := "|".join(found_ids)
	if found_signature != _built_found_signature or _grid.get_child_count() != CollectibleCatalog.TOTAL_SLOTS:
		_rebuild_grid()
		_built_found_signature = found_signature

	var requested := target_collectible_id
	if requested.is_empty() or not _manager.is_collectible_found(requested):
		requested = _selected_id
	if requested.is_empty() or not _manager.is_collectible_found(requested):
		requested = String(_manager.last_selected_collectible_id)
	if requested.is_empty() or not _manager.is_collectible_found(requested):
		requested = _choose_default(found_definitions)
	if requested.is_empty():
		_selected_id = ""
		_clear_large_preview()
	elif not _active or not visible:
		_selected_id = requested
	else:
		_select_collectible(requested, not target_collectible_id.is_empty())
	_refresh_card_states()
	set_active(_active)


func set_active(active: bool) -> void:
	_active = active and visible
	_dragging = false
	for viewport in _small_viewports:
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if _active else SubViewport.UPDATE_DISABLED
	if is_instance_valid(_large_viewport):
		_large_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _active else SubViewport.UPDATE_DISABLED


func get_selected_collectible_id() -> String:
	return _selected_id


func get_card_count() -> int:
	return _grid.get_child_count() if _grid else 0


func get_large_model_pivot() -> Node3D:
	return _large_model_pivot


func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false


func _build_interface() -> void:
	_header = Label.new()
	_header.name = "CollectiblesHeader"
	_header.text = "COLECCIONABLES ENCONTRADOS 0 / 14"
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header.add_theme_font_size_override("font_size", 31)
	_header.add_theme_color_override("font_color", CREAM)
	add_child(_header)

	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _line_style(Color("7e622f"), 1))
	add_child(separator)

	var content := HBoxContainer.new()
	content.name = "CollectiblesContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	add_child(content)

	var grid_panel := PanelContainer.new()
	grid_panel.name = "CollectibleGridPanel"
	grid_panel.custom_minimum_size.x = 560
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_stretch_ratio = 0.5
	grid_panel.add_theme_stylebox_override("panel", _style(Color("201b1e"), Color("614a32"), 8, 2, 12))
	content.add_child(grid_panel)
	_grid = GridContainer.new()
	_grid.name = "CollectibleGrid"
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 9)
	_grid.add_theme_constant_override("v_separation", 10)
	grid_panel.add_child(_grid)

	var preview_panel := PanelContainer.new()
	preview_panel.name = "CollectiblePreviewPanel"
	preview_panel.custom_minimum_size.x = 560
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_stretch_ratio = 0.5
	preview_panel.add_theme_stylebox_override("panel", _style(Color("241b1e"), Color("87672f"), 8, 2, 14))
	content.add_child(preview_panel)
	var right_column := VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 10)
	preview_panel.add_child(right_column)

	var model_panel := PanelContainer.new()
	model_panel.name = "LargeModelPanel"
	model_panel.custom_minimum_size.y = 330
	model_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	model_panel.size_flags_stretch_ratio = 0.70
	model_panel.add_theme_stylebox_override("panel", _style(Color("121418"), Color("59452f"), 6, 1, 2))
	right_column.add_child(model_panel)
	_large_preview_host = Control.new()
	_large_preview_host.name = "LargePreviewHost"
	_large_preview_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	model_panel.add_child(_large_preview_host)
	_empty_message = Label.new()
	_empty_message.name = "EmptyCollectibleMessage"
	_empty_message.text = "Selecciona una figura encontrada"
	_empty_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_message.add_theme_font_size_override("font_size", 20)
	_empty_message.add_theme_color_override("font_color", MUTED)
	_empty_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_large_preview_host.add_child(_empty_message)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.name = "CollectibleDescriptionScroll"
	detail_scroll.custom_minimum_size.y = 175
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_stretch_ratio = 0.30
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_column.add_child(detail_scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(detail)
	_detail_title = Label.new()
	_detail_title.name = "CollectibleTitle"
	_detail_title.add_theme_font_size_override("font_size", 30)
	_detail_title.add_theme_color_override("font_color", GOLD_BRIGHT)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_title)
	var detail_line := HSeparator.new()
	detail_line.add_theme_stylebox_override("separator", _line_style(Color("a67c36"), 1))
	detail.add_child(detail_line)
	_detail_description = Label.new()
	_detail_description.name = "CollectibleDescription"
	_detail_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_description.add_theme_font_size_override("font_size", 20)
	_detail_description.add_theme_color_override("font_color", CREAM)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_description)
	_detail_synopsis = Label.new()
	_detail_synopsis.name = "CollectibleFilmSynopsis"
	_detail_synopsis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_synopsis.add_theme_font_size_override("font_size", 16)
	_detail_synopsis.add_theme_color_override("font_color", Color("d3c1a5"))
	_detail_synopsis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_synopsis.visible = false
	detail.add_child(_detail_synopsis)


func _rebuild_grid() -> void:
	_cards.clear()
	_small_viewports.clear()
	_clear_children(_grid)
	for slot_number in range(1, CollectibleCatalog.TOTAL_SLOTS + 1):
		var definition := CollectibleCatalog.get_definition_by_number(slot_number)
		if not definition.is_empty() and _manager.is_collectible_found(String(definition.id)):
			var card := _make_found_card(definition)
			_grid.add_child(card)
			_cards[String(definition.id)] = card
		else:
			_grid.add_child(_make_locked_card(slot_number))


func _make_locked_card(slot_number: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "LockedFigure%02d" % slot_number
	card.custom_minimum_size = Vector2(98, 205)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_stylebox_override("panel", _style(Color("222428"), Color("484a4f"), 6, 1, 4))
	var mystery := Label.new()
	mystery.text = "?"
	mystery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mystery.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mystery.add_theme_font_size_override("font_size", 58)
	mystery.add_theme_color_override("font_color", Color("77777b"))
	mystery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(mystery)
	return card


func _make_found_card(definition: Dictionary) -> Button:
	var collectible_id := String(definition.id)
	var card := Button.new()
	card.name = "Figure_%s" % collectible_id.to_pascal_case()
	card.custom_minimum_size = Vector2(98, 205)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.clip_contents = true
	card.pressed.connect(_select_collectible.bind(collectible_id, false))
	card.focus_entered.connect(_select_collectible.bind(collectible_id, false))
	PointerTheme.set_button_cursor(card)
	var preview_data := _make_preview(definition, Vector2i(128, 214), false)
	var preview_container := preview_data.container as Control
	preview_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview_container)
	var preview_viewport := preview_data.get("viewport") as SubViewport
	if preview_viewport != null:
		_small_viewports.append(preview_viewport)
	var unread := PanelContainer.new()
	unread.name = "Unread"
	unread.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	unread.position = Vector2(-23, 8)
	unread.size = Vector2(15, 15)
	unread.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unread.add_theme_stylebox_override("panel", _style(GOLD_BRIGHT, Color("ffdf86"), 20, 1, 0))
	card.add_child(unread)
	return card


func _choose_default(found_definitions: Array[Dictionary]) -> String:
	for definition in found_definitions:
		if not bool(definition.get("viewed", false)):
			return String(definition.id)
	return String(found_definitions[0].id) if not found_definitions.is_empty() else ""


func _select_collectible(collectible_id: String, force_display: bool = false) -> void:
	if _manager == null or not _manager.is_collectible_found(collectible_id):
		return
	var selection_changed := collectible_id != _selected_id
	_selected_id = collectible_id
	if selection_changed or force_display or not is_instance_valid(_large_viewport):
		_display_collectible(collectible_id)
	_refresh_card_states()


func _display_collectible(collectible_id: String) -> void:
	var definition: Dictionary = _manager.get_collectible_definition(collectible_id) if _manager else {}
	if definition.is_empty() or not bool(definition.get("found", false)):
		_clear_large_preview()
		return
	_clear_children(_large_preview_host)
	_large_viewport = null
	_large_model_pivot = null
	_empty_message = null
	var preview_data := _make_preview(definition, Vector2i(640, 410), true)
	var preview_container := preview_data.container as Control
	preview_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if preview_data.get("interactive", false):
		preview_container.gui_input.connect(_on_large_preview_gui_input)
		preview_container.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_large_preview_host.add_child(preview_container)
	_large_viewport = preview_data.get("viewport") as SubViewport
	_large_model_pivot = preview_data.get("pivot") as Node3D
	_detail_title.text = String(definition.title).to_upper()
	_detail_description.text = String(definition.description)
	var synopsis := String(definition.get("film_synopsis", ""))
	_detail_synopsis.text = synopsis
	_detail_synopsis.visible = not synopsis.is_empty()
	_dragging = false
	_manager.mark_collectible_viewed(collectible_id)
	if _active and is_instance_valid(_large_viewport):
		_large_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _clear_large_preview() -> void:
	if _large_preview_host == null:
		return
	_clear_children(_large_preview_host)
	_large_viewport = null
	_large_model_pivot = null
	_detail_title.text = ""
	_detail_description.text = ""
	_detail_synopsis.text = ""
	_detail_synopsis.visible = false
	_empty_message = Label.new()
	_empty_message.name = "EmptyCollectibleMessage"
	_empty_message.text = "Selecciona una figura encontrada"
	_empty_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_message.add_theme_font_size_override("font_size", 20)
	_empty_message.add_theme_color_override("font_color", MUTED)
	_empty_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_large_preview_host.add_child(_empty_message)


func _refresh_card_states() -> void:
	for collectible_id in _cards:
		var card := _cards[collectible_id] as Button
		var selected := String(collectible_id) == _selected_id
		card.add_theme_stylebox_override("normal", _style(BURGUNDY_LIGHT if selected else CHARCOAL_LIGHT, GOLD if selected else Color("514347"), 6, 3 if selected else 1, 4))
		card.add_theme_stylebox_override("hover", _style(Color("60303a"), GOLD, 6, 2, 4))
		card.add_theme_stylebox_override("pressed", _style(BURGUNDY, GOLD_BRIGHT, 6, 3, 4))
		card.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD_BRIGHT, 6, 3, 4))
		var unread := card.find_child("Unread", true, false) as Control
		if unread:
			unread.visible = not _manager.is_collectible_viewed(String(collectible_id))


func _make_preview(definition: Dictionary, resolution: Vector2i, interactive: bool) -> Dictionary:
	var poster_texture := definition.get("poster_texture") as Texture2D
	if poster_texture != null:
		var frame := CenterContainer.new()
		frame.name = "PosterFrame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var poster := TextureRect.new()
		poster.name = "PosterPreview"
		poster.texture = poster_texture
		poster.custom_minimum_size = Vector2(300, 400) if interactive else Vector2(92, 182)
		poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		poster.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var poster_material := ShaderMaterial.new()
		poster_material.shader = POSTER_UI_SHADER
		poster_material.set_shader_parameter("pixel_grid", Vector2(96, 140) if interactive else Vector2(48, 70))
		poster.material = poster_material
		poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(poster)
		return {"container": frame, "viewport": null, "pivot": null, "interactive": false}
	var container := SubViewportContainer.new()
	container.name = "InteractiveModelPreview" if interactive else "CardModelPreview"
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.name = "ModelViewport"
	viewport.size = resolution
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	container.add_child(viewport)
	var world_root := Node3D.new()
	world_root.name = "PreviewWorld"
	viewport.add_child(world_root)
	var pivot := Node3D.new()
	pivot.name = "ModelPivot"
	world_root.add_child(pivot)
	var model_scene := definition.get("model_scene") as PackedScene
	if model_scene != null:
		var model := model_scene.instantiate() as Node3D
		model.name = "VisualModel"
		model.scale = definition.get("preview_scale", Vector3.ONE)
		model.position = definition.get("preview_offset", Vector3.ZERO)
		var preview_rotation: Vector3 = definition.get("preview_rotation", Vector3.ZERO)
		model.rotation_degrees = preview_rotation
		pivot.add_child(model)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-38, -28, 0)
	key_light.light_color = Color("ffd59b")
	key_light.light_energy = 1.55
	key_light.shadow_enabled = false
	world_root.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-1.2, 0.8, 1.4)
	fill_light.light_color = Color("e4ae4f")
	fill_light.light_energy = 2.0
	fill_light.omni_range = 4.0
	fill_light.shadow_enabled = false
	world_root.add_child(fill_light)
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	camera.fov = 31.0
	camera.look_at_from_position(Vector3(0, 0.22, 2.25), Vector3(0, 0.18, 0), Vector3.UP)
	world_root.add_child(camera)
	camera.current = true
	return {"container": container, "viewport": viewport, "pivot": pivot, "camera": camera, "interactive": interactive}


func _on_large_preview_gui_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		(_large_preview_host.get_child(0) as Control).accept_event()
	elif event is InputEventMouseMotion and _dragging and is_instance_valid(_large_model_pivot):
		_large_model_pivot.rotation.y += event.relative.x * 0.012
		(_large_preview_host.get_child(0) as Control).accept_event()


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
