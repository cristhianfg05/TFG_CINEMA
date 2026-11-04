extends SceneTree

const MODEL := preload("res://assets/pipeline/props/manager_lever_box.glb")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := MODEL.instantiate()
	root.add_child(model)
	await process_frame
	var pivots := model.find_children("Lever_*_Pivot", "Node3D", true, false)
	var mesh_count := model.find_children("*", "MeshInstance3D", true, false).size()
	var okay := pivots.size() == 4 and mesh_count >= 50
	for pivot in pivots:
		okay = okay and is_zero_approx(pivot.rotation.x)
	var first_pivot := model.find_child("Lever_1_Pivot", true, false) as Node3D
	var first_grip := model.find_child("Lever_1_Grip", true, false) as Node3D
	var down_y := first_grip.global_position.y
	first_pivot.rotation_degrees.x = -80.0
	var up_y := first_grip.global_position.y
	okay = okay and up_y > down_y + 0.15
	print("MANAGER_LEVER_IMPORT ", {"pivots": pivots.size(), "meshes": mesh_count, "down_y": down_y, "up_y": up_y, "ok": okay})
	model.queue_free()
	await process_frame
	quit(0 if okay else 1)
