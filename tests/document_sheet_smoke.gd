extends SceneTree

const SAVE_PATH := "res://.godot/document_sheet_smoke_save.json"
const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const SHEET_SCENE := preload("res://assets/pipeline/props/document_sheet.glb")
const PAPER_STREAM := preload("res://assets/audio/sfx/documents/document_pickup_sheet_02_first_half.wav")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	_delete_save()
	var sheet := SHEET_SCENE.instantiate()
	_expect(sheet.find_children("*", "MeshInstance3D", true, false).size() == 2, "Imported sheet must contain body and print meshes")
	sheet.free()
	_expect(PAPER_STREAM.get_length() > 0.5 and PAPER_STREAM.get_length() < 0.7, "Approved SFX must be only the first half of candidate 02")

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
	var document: DocumentPickup
	for node in get_nodes_in_group("document_pickup"):
		if node.document_id == "Doc1":
			document = node as DocumentPickup
			break
	_expect(manager != null and player != null and document != null, "Main scene did not load the document interaction")
	if manager != null and document != null and player != null:
		_expect(document.get_node_or_null("Paper/DocumentSheet3D") != null, "New GLB is absent from the document scene")
		_expect(not document.get_node("Paper/LegacyPaperFallback").visible, "Legacy rectangle must remain hidden")
		_expect(document._visual_meshes.size() == 2, "Focus must find the two imported sheet meshes")
		if not document._visual_meshes.is_empty():
			var mesh_part := document._visual_meshes[0] as MeshInstance3D
			document.set_focused(true)
			_expect(mesh_part.material_overlay != null, "Focus highlight did not reach the imported mesh")
			document.set_focused(false)
			_expect(mesh_part.material_overlay == null, "Focus highlight was not cleared")
		_expect(manager.document_pickup_audio.stream == PAPER_STREAM and manager.document_pickup_audio.bus == &"Player", "Chosen audio is not configured on Player")
		document.interact(player)
		await process_frame
		_expect(manager.is_document_found("Doc1"), "Document interaction did not record collection")
		_expect(manager.document_pickup_audio.playing, "Document pickup did not play the selected audio")

	main.queue_free()
	await process_frame
	_delete_save()
	if _failures.is_empty():
		print("DOCUMENT_SHEET_SMOKE_OK")
		quit(0)
	else:
		print("DOCUMENT_SHEET_SMOKE_FAILED: %s" % ", ".join(_failures))
		quit(1)


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)
