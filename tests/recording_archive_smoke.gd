extends SceneTree

const SAVE_PATH := "res://.godot/recording_archive_smoke_save.json"
const RecordingCatalog := preload("res://resources/recordings/recording_catalog.gd")
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	_remove_test_save()
	root.size = Vector2i(1920, 1080)
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	var manager := main.get_node("GameplayManager") as GameplayManager
	var player := main.get_node("Player") as PlayerController
	var menu := main.get_node("UpgradeMenu") as UpgradeMenu
	var intro := main.get_node("GameIntro") as GameIntro
	var director := main.get_node("RecordingDirector")
	_expect(RecordingCatalog.DEFINITIONS.size() == 16 and not RecordingCatalog.has_definition("15") and not RecordingCatalog.has_definition("18"), "Recording catalog did not leave 15/18 pending")
	intro._recording_panel.visible = true
	await process_frame
	for recording in RecordingCatalog.DEFINITIONS:
		for line in recording.lines:
			intro._recording_text.text = String(line)
			_expect(intro._recording_text.get_line_count() <= 2, "Recording %s exceeds the two-line subtitle box: %s" % [recording.id, line])
	intro._recording_panel.visible = false
	for document_id in ["Doc4", "Doc5", "Doc9", "Doc11"]:
		_expect(manager.has_document_definition(document_id), "%s is missing" % document_id)
	_expect(menu._section_bar.get_child_count() == 5 and menu._section_bar.get_child(4).text == "GRABACIONES", "Cassette tab is not beside Documents")
	_expect(menu._section_bar.get_child(4).icon == menu.CASSETTE_ICON, "Cassette icon is missing")
	menu.open_menu(&"recordings")
	_expect(menu.is_open() and paused and menu._recordings_view.visible, "Recordings view did not open as archive")
	_expect(menu._recordings_list.get_child_count() == 0 and menu._recording_title.text == "AÚN NO HAY GRABACIONES", "Unknown recordings were revealed")
	_expect(not menu._recordings_view.find_child("RecordingsHeader", true, false).text.contains("/"), "Recording total was revealed")
	manager.discover_recording("02")
	await process_frame
	_expect(menu._recordings_list.get_child_count() == 1 and menu._recording_title.text == "GRABACIÓN 02", "New recording was not listed")
	_expect(menu._recording_narrator.text == "Manager:", "Manager name was not shown initially")
	menu.close_menu()
	await process_frame
	_expect(intro._current_recording_id == "02" and intro._recording_state == &"cassette_open", "Discovered recording did not use existing cassette player")
	manager.discover_recording("03")
	_expect(director._pending.has("03") and intro._current_recording_id == "02", "Recordings overlapped instead of queueing")
	player.set_current_room_id(&"room_02")
	_expect(manager.is_recording_found("05"), "Sala 2 entry did not discover 05")
	player.set_current_room_id(&"room_04")
	_expect(manager.is_recording_found("11"), "Fear room entry did not discover 11")
	player.set_current_room_id(&"room_03")
	_expect(manager.is_recording_found("12"), "Action room entry did not discover 12")
	player.set_current_room_id(&"manager_office")
	_expect(manager.is_recording_found("03"), "Manager office entry did not discover 03")
	player.set_current_room_id(&"lobby")
	_expect(manager.is_recording_found("07"), "Lobby entry did not discover 07")
	player.global_position = Vector3(14.75, 1.0, -14.64)
	director._process(0.0)
	_expect(manager.is_recording_found("08"), "Cinema entrance proximity did not discover 08")
	manager.room_completed = true
	manager.state_changed.emit()
	_expect(manager.is_recording_found("02"), "Sala 1 completion did not retain 02")
	for pair in [["Doc5", "04"], ["Doc4", "06"], ["Doc9", "13"], ["Doc11", "16"]]:
		manager.collect_document(pair[0])
		menu.open_menu(&"documents", pair[0])
		_expect(not manager.is_recording_found(pair[1]), "%s fired before closing the document" % pair[1])
		menu.close_menu()
		_expect(manager.is_recording_found(pair[1]), "%s did not fire on document close" % pair[1])
	menu.open_menu(&"recordings", "14")
	manager.discover_recording("14")
	menu._refresh_recordings("14")
	_expect(menu._recording_narrator.text == "Manager:", "Mateo's name appeared before 13 was heard")
	menu.close_menu()
	manager.mark_recording_heard("13")
	menu.open_menu(&"recordings", "14")
	_expect(menu._recording_narrator.text == "Mateo:", "Mateo's name was not revealed after 13")
	menu.close_menu()
	manager.collect_collectible("arcade_reel_rescue_normal_poster")
	_expect(not manager.is_recording_found("09"), "Poster counted as Palace figure")
	manager.collect_collectible("capitan_orbita")
	_expect(manager.is_recording_found("09") and not manager.is_recording_found("10") and not manager.is_recording_found("17"), "Figure milestones counted posters or future figures")
	for room_id in manager.HAMMER_REQUIRED_AREAS:
		manager.room_trash_remaining[String(room_id)] = 0
	manager.state_changed.emit()
	_expect(manager.is_recording_found("14"), "Full non-final cinema did not discover 14")
	manager._save_progress()
	main.queue_free()
	await process_frame
	var restored := scene.instantiate()
	root.add_child(restored)
	await process_frame
	var restored_manager := restored.get_node("GameplayManager") as GameplayManager
	_expect(restored_manager.loaded_save and restored_manager.is_recording_found("09") and restored_manager.is_recording_found("14"), "Recording archive was not persisted")
	_expect(restored_manager.is_recording_heard("13"), "Narrator reveal was not persisted")
	restored.queue_free()
	await process_frame
	_remove_test_save()
	if failures.is_empty():
		print("RECORDING_ARCHIVE_SMOKE_OK")
		quit(0)
	else:
		print("RECORDING_ARCHIVE_SMOKE_FAILED: %s" % " | ".join(failures))
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _remove_test_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
