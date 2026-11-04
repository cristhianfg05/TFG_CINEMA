extends SceneTree

const SAVE_PATH := "res://.godot/collectible_system_smoke_save.json"
const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const CollectibleCatalog := preload("res://resources/collectibles/collectible_catalog.gd")
const EXPECTED_DESCRIPTION := "El héroe espacial más valiente del Palace, aunque no necesariamente el más competente. Su casco ocupaba más que el decorado y su pistola nunca apuntaba hacia donde debía."
const POSTER_IDS := [
	"arcade_reel_rescue_normal_poster",
	"arcade_reel_rescue_hard_poster",
	"arcade_second_game_normal_poster",
	"arcade_second_game_hard_poster",
]
const POSTER_TITLES := ["Más allá del horizonte", "Abril entre nosotros", "Última salida", "La puerta del fondo"]
const POSTER_GAMES := ["Rescata el carrete", "Rescata el carrete", "El último acomodador", "El último acomodador"]
const POSTER_DIFFICULTIES := ["Normal", "Difícil", "Normal", "Difícil"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	_delete_save()
	var definitions := CollectibleCatalog.get_definitions()
	_expect(definitions.size() == 14, "The collection must include ten figures and four arcade-poster slots")
	var definition: Dictionary = definitions[0]
	_expect(String(definition.id) == "capitan_orbita" and int(definition.number) == 1, "The stable collectible identity is wrong")
	_expect(String(definition.title) == "Capitán Órbita", "The exact collectible title was not preserved")
	_expect(String(definition.location) == "Sala 1, detrás del altavoz delantero izquierdo, entre el escenario y la pared.", "The exact placement metadata was not preserved")
	_expect(String(definition.description) == EXPECTED_DESCRIPTION, "The exact collectible description was not preserved")
	_expect(definition.model_scene is PackedScene, "The visual model is not data-driven")
	for figure_index in range(10):
		var figure_definition: Dictionary = definitions[figure_index]
		_expect(int(figure_definition.number) == figure_index + 1, "A figure number is missing from the catalog")
		_expect(figure_definition.model_scene is PackedScene and String((figure_definition.model_scene as PackedScene).resource_path).ends_with("/%d.glb" % (figure_index + 1)), "A figure does not use its numbered GLB")
	for index in range(4):
		var poster: Dictionary = definitions[index + 10]
		var expected_image := "res://assets/movies/room_%d/Movie_Cartel.jpeg" % (index + 1)
		var expected_acquisition := "Cartel obtenido superando el juego «%s» en %s." % [POSTER_GAMES[index], POSTER_DIFFICULTIES[index]]
		_expect(String(poster.id) == POSTER_IDS[index] and int(poster.number) == index + 11, "An arcade-poster slot or persistent ID changed")
		_expect(String(poster.title) == POSTER_TITLES[index], "An arcade poster has the wrong film title")
		_expect(String(poster.description) == expected_acquisition, "An arcade poster has the wrong acquisition text")
		_expect(not String(poster.get("film_synopsis", "")).is_empty(), "An arcade poster has no film synopsis")
		var texture := poster.get("poster_texture") as Texture2D
		_expect(texture != null and texture.resource_path == expected_image, "An arcade poster is not using its original movie image")

	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	var intro = get_first_node_in_group("game_intro")
	if intro and intro.has_method("complete_immediately"):
		intro.complete_immediately()
	await process_frame

	var manager = get_first_node_in_group("gameplay_manager")
	var player = get_first_node_in_group("player")
	var menu = get_first_node_in_group("upgrade_menu")
	var hud = main.get_node("GameplayHUD")
	var figure = _find_collectible("capitan_orbita")
	var speaker = main.get_node_or_null("Room01Blockout/CinemaSpeakerLeft") as Node3D
	_expect(manager != null and player != null and menu != null, "Required existing gameplay systems are missing")
	_expect(is_equal_approx(manager.reject_audio.volume_db, -16.0), "The failed-pickup sound is still too loud")
	_expect(manager.get_found_collectible_count() == 0 and manager.get_total_collectible_count() == 14, "Fresh collectible progress or fixed total is wrong")
	_expect(menu._section_bar.get_child(2).text == "?" and menu._section_bar.get_child(2).disabled, "Zero-figure navigation is not a disabled mystery")
	_expect(menu._collectibles_view.get_card_count() == 14, "The mystery grid does not contain fourteen generated slots")
	for slot in menu._collectibles_view._grid.get_children():
		_expect(not slot is BaseButton and slot.focus_mode == Control.FOCUS_NONE, "A locked figure slot is selectable")
		_expect(slot.find_children("*", "SubViewport", true, false).is_empty(), "A locked figure slot wastes a 3D viewport")

	_expect(figure != null and speaker != null, "Capitán Órbita or the front-left speaker is missing")
	if figure and speaker:
		_expect(figure.global_position.x < speaker.global_position.x and figure.global_position.distance_to(speaker.global_position) < 3.0, "Capitán Órbita is not tucked behind the front-left speaker")
		_expect(figure.global_position.x > -10.75 and figure.global_position.z > -14.9, "Capitán Órbita is inside the auditorium wall")
		var query := PhysicsShapeQueryParameters3D.new()
		var probe := SphereShape3D.new()
		probe.radius = 0.10
		query.shape = probe
		query.transform = Transform3D(Basis.IDENTITY, figure.global_position + Vector3.UP * 0.42)
		query.collision_mask = 1
		var blocking_geometry: Array[Dictionary] = main.get_world_3d().direct_space_state.intersect_shape(query, 8)
		_expect(blocking_geometry.is_empty(), "The placed figure overlaps wall or speaker collision")
		var sight_query := PhysicsRayQueryParameters3D.create(Vector3(-10.2, 1.45, -11.55), figure.global_position + Vector3.UP * 0.40, 3)
		sight_query.collide_with_areas = true
		var sight_hit: Dictionary = main.get_world_3d().direct_space_state.intersect_ray(sight_query)
		_expect(sight_hit.get("collider") == figure, "The figure cannot be targeted from the accessible strip behind the speaker")
	_expect(figure.get_interaction_prompt() == "E — Recoger figura", "The figure does not use the existing interaction contract")

	var coins_before: int = manager.coins
	var bag_before: int = manager.bag_volume
	var clean_before: int = manager.get_clean_percent()
	figure.interact(player)
	await process_frame
	_expect(manager.is_collectible_found("capitan_orbita") and not manager.is_collectible_viewed("capitan_orbita"), "Found and unseen collectible states were not kept independently")
	_expect(manager.coins == coins_before and manager.bag_volume == bag_before and manager.get_clean_percent() == clean_before, "The collectible affected coins, bag or cleaning")
	_expect(_find_collectible("capitan_orbita") == null, "The collected physical figure remained in the world")
	_expect(FileAccess.file_exists(SAVE_PATH), "Collectible collection was not saved immediately")
	_expect(menu._notification_active and menu._notification_panel.visible, "The shared discovery notification was not shown")
	_expect(menu._notification_title.text == "Figura encontrada" and menu._notification_hint.text == "Pulsa Tab para verla", "The figure notification text is wrong")
	_expect(hud._objective_sound.stream != null and hud._objective_sound.stream.resource_path.ends_with("objective_piano_candidate_02.wav") and hud._objective_sound.playing, "Picking up a figure did not play the approved objective piano")
	_expect(menu._pending_discovery_type == &"collectible" and menu._pending_discovery_item_id == "capitan_orbita" and menu._pending_discovery_section == &"collectibles", "The shared notification did not retain the collectible deep-link")
	_expect(not paused, "The discovery notification blocked gameplay")
	var notification_generation: int = menu._notification_generation
	_expect(not manager.collect_collectible("capitan_orbita") and menu._notification_generation == notification_generation, "Duplicate collection emitted another notification")

	# Refreshing while hidden may reveal the card structure, but must not mark it
	# viewed until its content is actually shown.
	menu._collectibles_view.refresh()
	var unseen_card := menu._collectibles_view._cards.get("capitan_orbita") as Button
	var unseen_dot := unseen_card.find_child("Unread", true, false) as Control
	_expect(unseen_dot != null and unseen_dot.visible and not manager.is_collectible_viewed("capitan_orbita"), "The new indicator was consumed before opening the figure")

	var tab := InputEventAction.new()
	tab.action = &"upgrade_menu"
	tab.pressed = true
	Input.parse_input_event(tab)
	await process_frame
	_expect(menu.is_open() and menu._section == &"collectibles", "Notification Tab did not deep-link to Collectibles")
	_expect(menu._section_bar.get_child(2).text == "COLECCIONABLES" and not menu._section_bar.get_child(2).disabled, "The first figure did not reveal its section")
	_expect(paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Collectibles did not reuse the archive pause and mouse flow")
	_expect(menu._collectibles_view._header.text == "COLECCIONABLES ENCONTRADOS 1 / 14", "The dynamic collectible header is wrong")
	_expect(menu._collectibles_view.get_card_count() == 14, "The unlocked grid lost one of its fourteen slots")
	_expect(menu._collectibles_view.get_selected_collectible_id() == "capitan_orbita", "The discovered figure was not selected")
	_expect(menu._collectibles_view._detail_title.text == "CAPITÁN ÓRBITA" and menu._collectibles_view._detail_description.text == EXPECTED_DESCRIPTION, "The exact figure details were not displayed")
	_expect(manager.is_collectible_viewed("capitan_orbita"), "Displaying the figure did not mark it viewed")
	var found_slots := 0
	var locked_slots := 0
	for slot in menu._collectibles_view._grid.get_children():
		if slot is Button:
			found_slots += 1
			_expect(not slot.find_children("*", "SubViewport", true, false).is_empty(), "The found card has no 3D preview")
		else:
			locked_slots += 1
			_expect(slot.focus_mode == Control.FOCUS_NONE and not slot is BaseButton, "A blocked card became interactive")
	_expect(found_slots == 1 and locked_slots == 13, "The grid does not contain one found and thirteen unknown slots")
	var viewed_dot := menu._collectibles_view._cards["capitan_orbita"].find_child("Unread", true, false) as Control
	_expect(viewed_dot != null and not viewed_dot.visible, "The unseen indicator did not disappear immediately")
	await process_frame
	_expect(menu.is_open(), "The discovery Tab event also closed the menu")

	var pivot: Node3D = menu._collectibles_view.get_large_model_pivot()
	var rotation_before: Vector3 = pivot.rotation
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	menu._collectibles_view._on_large_preview_gui_input(press)
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(42, 80)
	menu._collectibles_view._on_large_preview_gui_input(drag)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	menu._collectibles_view._on_large_preview_gui_input(release)
	_expect(not is_equal_approx(pivot.rotation.y, rotation_before.y), "Horizontal dragging did not rotate the preview")
	_expect(is_equal_approx(pivot.rotation.x, rotation_before.x) and is_equal_approx(pivot.rotation.z, rotation_before.z), "Dragging tilted the model outside the Y axis")
	_expect(menu._collectibles_view._large_viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "The large preview is not updating while visible")

	var escape := InputEventAction.new()
	escape.action = &"pause"
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	_expect(not menu.is_open() and not paused, "Escape did not restore gameplay from Collectibles")
	_expect(menu._collectibles_view._large_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "The large preview keeps processing with the menu closed")

	var save := JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH)) as Dictionary
	_expect("capitan_orbita" in save.get("collectibles_found", []) and "capitan_orbita" in save.get("collectibles_viewed", []), "Found/viewed collectible IDs are missing from the shared save")
	_expect(String(save.get("last_selected_collectible_id", "")) == "capitan_orbita", "The last selected figure was not saved")

	main.queue_free()
	await process_frame
	var loaded := MAIN_SCENE.instantiate()
	root.add_child(loaded)
	await process_frame
	await physics_frame
	var loaded_intro = get_first_node_in_group("game_intro")
	if loaded_intro and loaded_intro.has_method("complete_immediately"):
		loaded_intro.complete_immediately()
	await process_frame
	var loaded_manager = get_first_node_in_group("gameplay_manager")
	var loaded_menu = get_first_node_in_group("upgrade_menu")
	_expect(loaded_manager.is_collectible_found("capitan_orbita") and loaded_manager.is_collectible_viewed("capitan_orbita"), "Collectible progress did not survive save reload")
	_expect(loaded_manager.last_selected_collectible_id == "capitan_orbita", "Last collectible selection did not survive reload")
	_expect(_find_collectible("capitan_orbita") == null, "The collected figure respawned after loading")
	_expect(loaded_manager.get_found_document_count() == 0 and loaded_menu._section_bar.get_child(3).text == "?", "The document mystery state was broken")
	_expect(loaded_manager.get_upgrade_state(&"sprint").id == "sprint", "The existing upgrade system stopped functioning")
	# Exercise all four poster previews through the same archive UI, while leaving
	# the second arcade unimplemented in the actual game.
	for index in range(4):
		var poster_id: String = POSTER_IDS[index]
		_expect(loaded_manager.collect_collectible(poster_id), "A test poster could not be collected")
		loaded_menu.open_menu(&"collectibles", poster_id)
		await process_frame
		var poster_view = loaded_menu._collectibles_view
		var poster_definition: Dictionary = loaded_manager.get_collectible_definition(poster_id)
		var poster_preview := poster_view._large_preview_host.find_child("PosterPreview", true, false) as TextureRect
		var poster_card := poster_view._cards[poster_id] as Button
		var card_preview := poster_card.find_child("PosterPreview", true, false) as TextureRect
		_expect(poster_view.get_selected_collectible_id() == poster_id, "The poster did not open in the archive")
		_expect(poster_view._detail_description.text == String(poster_definition.description), "The poster acquisition text is not shown")
		_expect(poster_view._detail_synopsis.visible and poster_view._detail_synopsis.text == poster_definition.film_synopsis, "The film synopsis is not shown below the acquisition text")
		_expect(poster_preview != null and poster_preview.texture == poster_definition.poster_texture, "The original poster image is not shown in the large preview")
		_expect(poster_preview != null and poster_preview.custom_minimum_size == Vector2(300, 400) and poster_preview.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "The selected poster size or pixel filter is wrong")
		_expect(card_preview != null and card_preview.custom_minimum_size == Vector2(92, 182) and card_preview.material is ShaderMaterial, "The poster card size or worn/pixelated material is wrong")
		loaded_menu.close_menu()

	loaded.queue_free()
	await process_frame
	_delete_save()
	_finish()


func _find_collectible(collectible_id: String) -> Node:
	for collectible in get_nodes_in_group("collectible_pickup"):
		if String(collectible.collectible_id) == collectible_id:
			return collectible
	return null


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("COLLECTIBLE TEST: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("COLLECTIBLE_SYSTEM_SMOKE_OK")
		quit(0)
	else:
		print("COLLECTIBLE_SYSTEM_SMOKE_FAILED: " + ", ".join(_failures))
		quit(1)
