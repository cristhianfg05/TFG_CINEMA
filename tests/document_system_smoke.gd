extends SceneTree

const SAVE_PATH := "res://.godot/document_system_smoke_save.json"
const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const DocumentCatalog := preload("res://resources/documents/document_catalog.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	_delete_save()
	var definitions := DocumentCatalog.load_definitions()
	_expect(definitions.size() == 2, "Both current document definitions were not loaded")
	_expect(String(definitions[0].id) == "Doc1" and String(definitions[1].id) == "Doc2", "Documents are not sorted by filename or IDs are not stable")
	_expect(String(definitions[0].location) == "Primera fila sala 1, enfrente del jugador al comenzar", "Updated Doc1 location was not decoded")
	_expect(String(definitions[1].location) == "Última fila de Sala 1", "Spanish document metadata was not decoded")
	_expect(String(definitions[0].subtitle) == "Encontrado enfrente de la pantalla de la primera sala.", "Doc1 visible subtitle was not read from line 3")
	_expect(String(definitions[1].subtitle) == "Entontrado al final de la primera sala, cerca de las butacas traseras", "Doc2 visible subtitle was not read from line 3")
	_expect(String(definitions[0].body).begins_with("Encender luces de los pasillos."), "Doc1 body did not start at line 4")
	_expect("\n" in String(definitions[0].body) and "\n" in String(definitions[1].body), "Document paragraphs were not preserved")

	var fixture_directory := "res://.godot/document_loader_fixture"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_directory))
	var fixture := FileAccess.open(fixture_directory + "/01_bom_crlf.txt", FileAccess.WRITE)
	fixture.store_string("\ufeffTÍTULO Ñ\r\nSala de prueba\r\nEncontrado durante la prueba\r\n  Conserva espacios\r\n\r\n[b]Texto literal[/b]\r\n" + "Párrafo largo con caracteres españoles. ".repeat(90))
	fixture.close()
	var fixtures := DocumentCatalog.load_definitions(fixture_directory)
	_expect(fixtures.size() == 1 and String(fixtures[0].title) == "TÍTULO Ñ", "UTF-8 BOM or CRLF parsing failed")
	_expect(String(fixtures[0].subtitle) == "Encontrado durante la prueba", "Line 3 was not parsed as the visible subtitle")
	_expect(String(fixtures[0].body).begins_with("  Conserva espacios\n\n"), "Leading spaces or blank paragraphs were not preserved")

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
	var physical_documents := get_nodes_in_group("document_pickup")
	var doc1 = _find_physical_document(physical_documents, "Doc1")
	var doc2 = _find_physical_document(physical_documents, "Doc2")
	_expect(manager != null and menu != null and player != null, "Required existing gameplay systems are missing")
	_expect(manager.get_found_document_count() == 0, "Fresh save did not start with zero documents")
	_expect(menu._section_bar.get_child(3).text == "?" and menu._section_bar.get_child(3).disabled, "Zero-document navigation is not a disabled mystery")
	_expect(physical_documents.size() == 2 and doc1 != null and doc2 != null, "Both unambiguous Room 1 documents were not placed")
	if doc1:
		_expect(doc1.global_position.distance_to(Vector3(-1.54, 0.035, -11.25)) < 0.05, "Doc1 is not in front of the initial player position")
		_expect(doc1.global_position.distance_to(player.global_position) <= player.interaction_raycast.target_position.length(), "Doc1 is outside the player's initial interaction range")

	var coins_before: int = manager.coins
	var bag_before: int = manager.bag_volume
	var clean_before: int = manager.get_clean_percent()
	var document = doc1
	_expect(document.get_interaction_prompt() == "E — Recoger documento", "Document does not expose the existing interaction contract")
	document.interact(player)
	await process_frame
	_expect(manager.is_document_found("Doc1") and not manager.is_document_read("Doc1"), "Found and unread states were not kept independently")
	_expect(manager.coins == coins_before and manager.bag_volume == bag_before and manager.get_clean_percent() == clean_before, "Document affected coins, bag capacity or cleaning")
	_expect(get_nodes_in_group("document_pickup").size() == 1 and _find_physical_document(get_nodes_in_group("document_pickup"), "Doc2") != null, "Only the collected physical document should leave the world")
	_expect(FileAccess.file_exists(SAVE_PATH), "Document collection was not saved immediately")
	_expect(menu._notification_active and menu._notification_panel.visible and menu._pending_discovery_item_id == "Doc1" and menu._pending_discovery_section == &"documents", "Document notification was not shown or did not preserve the latest target")
	_expect(is_equal_approx(menu.DISCOVERY_NOTIFICATION_DURATION, 8.0) and not paused, "Discovery notification duration or non-blocking gameplay state is wrong")
	var notification_generation: int = menu._notification_generation
	_expect(not manager.collect_document("Doc1") and menu._notification_generation == notification_generation, "Duplicate collection emitted a second notification")

	var tab := InputEventAction.new()
	tab.action = &"upgrade_menu"
	tab.pressed = true
	Input.parse_input_event(tab)
	await process_frame
	_expect(menu.is_open() and menu._section == &"documents", "Notification Tab did not deep-link to Documents")
	_expect(menu._section_bar.get_child(3).text == "DOCUMENTOS" and not menu._section_bar.get_child(3).disabled and menu._section_bar.get_child(3).icon == menu.DOCUMENT_ICON, "First document did not reveal the navigation section and shared icon")
	_expect(paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Documents did not use pause and visible-mouse flow")
	_expect(menu._documents_header.text == "DOCUMENTOS ENCONTRADOS 1 / 12", "Document header denominator or found count is wrong")
	_expect(menu._documents_list.get_child_count() == 1, "Unfound document metadata was revealed in the list")
	_expect(menu._selected_document_id == "Doc1" and menu._document_title.text == "LISTA DE APERTURA", "Found document was not selected and displayed")
	_expect(menu._document_subtitle.text == "Encontrado enfrente de la pantalla de la primera sala.", "Internal placement metadata was shown instead of the line-3 subtitle")
	_expect(menu._document_body.text.begins_with("Encender luces de los pasillos.") and not menu._document_body.text.begins_with(menu._document_subtitle.text), "Visible subtitle was duplicated in the document body")
	_expect(manager.is_document_read("Doc1"), "Displaying document content did not mark it read")
	await process_frame
	_expect(menu.is_open(), "The same Tab event immediately closed the menu")
	var unread_dot := menu._document_rows["Doc1"].find_child("Unread", true, false) as Control
	_expect(unread_dot != null and not unread_dot.visible, "Unread indicator did not disappear immediately")

	var escape := InputEventAction.new()
	escape.action = &"pause"
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	_expect(not menu.is_open() and not paused, "Escape did not restore gameplay from Documents")
	if DisplayServer.get_name() != "headless":
		_expect(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Escape did not recapture the gameplay mouse")

	Input.parse_input_event(tab)
	await process_frame
	_expect(menu.is_open() and menu._section == &"documents", "Documents did not reopen through the existing Tab flow")
	Input.parse_input_event(tab)
	await process_frame
	_expect(not menu.is_open() and not paused, "Tab did not close Documents exactly once")

	# The other physical document remains independent. Its notification must
	# replace the pending ID and deep-link to the newly found entry.
	doc2 = _find_physical_document(get_nodes_in_group("document_pickup"), "Doc2")
	_expect(doc2 != null, "Doc2 disappeared before it was collected")
	doc2.interact(player)
	await process_frame
	_expect(manager.is_document_found("Doc2") and not manager.is_document_read("Doc2"), "Second document did not preserve its unread state")
	_expect(menu._pending_discovery_item_id == "Doc2" and menu._pending_discovery_section == &"documents" and manager.get_found_document_count() == 2, "Latest notification or document count did not update")
	Input.parse_input_event(tab)
	await process_frame
	_expect(menu.is_open() and menu._selected_document_id == "Doc2" and menu._document_title.text == "LA SALA QUE NO SE DISFRAZA", "Second document did not deep-link to its content")
	_expect(menu._documents_header.text == "DOCUMENTOS ENCONTRADOS 2 / 12", "Visible document header did not update to two found documents")
	_expect(manager.is_document_read("Doc2"), "Second document was not marked read when displayed")
	Input.parse_input_event(tab)
	await process_frame
	_expect(not menu.is_open() and not paused, "Second document menu did not close cleanly")

	# Inject the loader fixture only into this isolated test session to verify a
	# genuinely long body and vertical scroll without adding invented lore.
	var long_definition: Dictionary = fixtures[0].duplicate(true)
	long_definition.found = true
	manager.document_definitions.append(long_definition)
	manager._document_definitions_by_id[String(long_definition.id)] = long_definition
	manager._found_document_ids[String(long_definition.id)] = true
	menu.open_menu(&"documents", String(long_definition.id))
	await process_frame
	await process_frame
	_expect(menu._document_body.text.begins_with("  Conserva espacios\n\n"), "Long body was altered by the reader")
	_expect("[b]Texto literal[/b]" in menu._document_body.text and menu._document_body is Label, "TXT markup was interpreted instead of displayed literally")
	_expect(menu._document_scroll.get_v_scroll_bar().max_value > menu._document_scroll.get_v_scroll_bar().page, "Long document did not enable vertical scrolling")
	menu._document_scroll.scroll_vertical = 100
	menu._select_document("Doc2")
	await process_frame
	_expect(menu._document_scroll.scroll_vertical == 0, "Selecting another document did not reset scroll to the top")
	menu.close_menu()

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
	_expect(loaded_manager.is_document_found("Doc1") and loaded_manager.is_document_read("Doc1"), "Doc1 found/read state did not survive save reload")
	_expect(loaded_manager.is_document_found("Doc2") and loaded_manager.is_document_read("Doc2"), "Doc2 found/read state did not survive save reload")
	_expect(loaded_manager.last_selected_document_id == "Doc2", "Last document selection was not persisted")
	_expect(get_nodes_in_group("document_pickup").is_empty(), "Found documents respawned after loading")
	_expect(loaded_manager.get_upgrade_state(&"sprint").id == "sprint", "Existing upgrade system stopped functioning")

	loaded.queue_free()
	await process_frame
	_delete_save()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_directory + "/01_bom_crlf.txt"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_directory))
	_finish()


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _find_physical_document(documents: Array[Node], document_id: String) -> Node:
	for document in documents:
		if String(document.document_id) == document_id:
			return document
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)


func _finish() -> void:
	if _failures.is_empty():
		print("DOCUMENT_SYSTEM_SMOKE_OK")
		quit(0)
	else:
		print("DOCUMENT_SYSTEM_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)
