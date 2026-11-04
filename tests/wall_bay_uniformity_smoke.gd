extends SceneTree

const SAVE_PATH := "res://.godot/wall_bay_uniformity_smoke_save.json"

var _failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("CINEMA_CLEANER_TEST_SAVE_PATH", SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var specs := [
		{"name": "Sala 1", "room": main.get_node("Room01Blockout"), "center": 0.0, "start": -15.0, "end": 15.0, "count": 6,
			"lower": "WallPanel_*", "upper": "", "pillar": "WallPillar_*", "grille": "Grille_*", "speaker": "WallSpeaker_*", "light_a": "WallLightA_*", "light_b": "WallLightB_*", "glow_a": "WallGlowA_*", "glow_b": "WallGlowB_*"},
		{"name": "Sala 2", "room": main.get_node("Room02Blockout"), "center": 21.1, "start": 25.0, "end": 57.0, "count": 6,
			"lower": "Room02WallLower_*", "upper": "Room02WallUpper_*", "pillar": "Room02WallPillar_*", "grille": "Room02Grille_*", "speaker": "Room02WallSpeaker_*", "light_a": "Room02WallLightA_*", "light_b": "Room02WallLightB_*", "glow_a": "Room02WallGlowA_*", "glow_b": "Room02WallGlowB_*"},
		{"name": "Sala 3", "room": main.get_node("Room03Blockout"), "center": -9.375, "start": 25.0, "end": 57.0, "count": 6,
			"lower": "SidePanel_*", "upper": "SidePlaster_*", "pillar": "SidePillar_*", "grille": "WallGrille_*", "speaker": "WallSpeaker_*", "light_a": "WallLightA_*", "light_b": "WallLightB_*", "glow_a": "WallGlowA_*", "glow_b": "WallGlowB_*"},
		{"name": "Sala 4", "room": main.get_node("Room04Blockout"), "center": -44.0, "start": -63.0, "end": -9.0, "count": 10,
			"lower": "SidePanel_*", "upper": "SidePlaster_*", "pillar": "SidePillar_*", "grille": "WallGrille_*", "speaker": "WallSpeaker_*", "light_a": "WallLightA_*", "light_b": "WallLightB_*", "glow_a": "WallGlowA_*", "glow_b": "WallGlowB_*"},
	]
	for spec in specs:
		_check_room(spec)
	_check_end_walls(main)
	_check_corridor_walls(main)
	main.queue_free()
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if _failures.is_empty():
		print("WALL_BAY_UNIFORMITY_SMOKE_OK")
		quit(0)
	else:
		print("WALL_BAY_UNIFORMITY_SMOKE_FAILED: " + ", ".join(_failures))
		quit(1)


func _check_room(spec: Dictionary) -> void:
	var room := spec.room as Node3D
	var count := int(spec.count)
	var center := float(spec.center)
	var start := float(spec.start)
	var bay_length := (float(spec.end) - start) / float(count)
	var groups := {}
	for key in ["lower", "upper", "pillar", "grille", "speaker", "light_a", "light_b", "glow_a", "glow_b"]:
		groups[key] = room.find_children(String(spec[key]), "Node3D", false, false) if not String(spec[key]).is_empty() else []
		var expected_count := 0 if String(spec[key]).is_empty() else (2 * (count + 1) if key == "pillar" else 2 * count)
		_expect(groups[key].size() == expected_count, "%s: incorrect %s count" % [spec.name, key])
	for key in ["light_a", "light_b"]:
		for item in groups[key]:
			var lamp := item as Node3D
			var model := lamp.get_child(0) as Node3D
			_expect(is_equal_approx(absf(lamp.rotation.x + model.rotation.x), PI * 0.5) and is_zero_approx(lamp.rotation.z + model.rotation.z), "%s: horizontal lamp is turned upright" % spec.name)
	if not String(spec.upper).is_empty():
		var base_pattern := "Room02SideBase_*" if String(spec.name) == "Sala 2" else "SideBase_*"
		for item in room.find_children(base_pattern, "Node3D", false, false):
			var base_mesh := (item.get_child(0) as MeshInstance3D).mesh as BoxMesh
			_expect(is_equal_approx(base_mesh.size.y, 0.43), "%s: black skirting is taller than in the other auditoria" % spec.name)
	for side in [-1, 1]:
		for bay in count:
			var z := start + (bay + 0.5) * bay_length
			for key in ["lower", "grille", "speaker"]:
				_expect(_at(groups[key], center, side, z) != null, "%s: %s is not centred in bay %d" % [spec.name, key, bay])
			for key in ["lower", "upper"]:
				if groups[key].is_empty():
					continue
				var panel := _at(groups[key], center, side, z)
				_expect(panel != null, "%s: %s is not centred in bay %d" % [spec.name, key, bay])
				if panel != null:
					var visual := panel.get_child(0) as MeshInstance3D
					_expect(is_equal_approx((visual.mesh as BoxMesh).size.z, bay_length), "%s: unequal %s width in bay %d" % [spec.name, key, bay])
					if String(spec.upper).is_empty():
						_expect(is_equal_approx(panel.position.y, 3.5) and is_equal_approx((visual.mesh as BoxMesh).size.y, 7.0), "Sala 1: lateral wall is not red from floor to ceiling")
					elif key == "lower":
						_check_join(panel, _at(groups["upper"], center, side, z), "%s lateral bay %d" % [spec.name, bay])
			_expect(_at(groups["light_a"], center, side, z - 1.55) != null, "%s: left horizontal lamp missing in bay %d" % [spec.name, bay])
			_expect(_at(groups["light_b"], center, side, z + 1.55) != null, "%s: right horizontal lamp missing in bay %d" % [spec.name, bay])
			for lamp_key in ["a", "b"]:
				var lamp_z := z + (-1.55 if lamp_key == "a" else 1.55)
				var lamp: Node3D = _at(groups["light_" + lamp_key], center, side, lamp_z)
				var glow: Node3D = _at(groups["glow_" + lamp_key], center, side, lamp_z)
				_expect(glow != null, "%s: lamp %s has no light source in bay %d" % [spec.name, lamp_key, bay])
				if lamp != null and glow != null:
					_expect(is_equal_approx(glow.position.y, lamp.position.y) and absf(glow.position.z - lamp.position.z) < 0.02, "%s: light source is detached from lamp %s in bay %d" % [spec.name, lamp_key, bay])
					var inward: float = (lamp.position.x - glow.position.x) * float(side)
					_expect(inward > 0.30 and inward < 0.46, "%s: light source is not just in front of lamp %s in bay %d" % [spec.name, lamp_key, bay])
					_expect(absf(glow.position.z - z) > 1.4, "%s: light source is at the speaker in bay %d" % [spec.name, bay])
		for boundary in count + 1:
			_expect(_at(groups["pillar"], center, side, start + boundary * bay_length) != null, "%s: column missing at boundary %d" % [spec.name, boundary])


func _check_end_walls(main: Node3D) -> void:
	var room1 := main.get_node("Room01Blockout")
	for wall in ["FrontWallPanel_01", "RearWallPanel_01", "RearWallHeader"]:
		var node := room1.get_node(wall) as Node3D
		var mesh := (node.get_child(0) as MeshInstance3D).mesh as BoxMesh
		_expect(mesh.material.resource_path.ends_with("cinema_panel_wine.tres"), "Sala 1: an end wall is not wine-red")
	var room2 := main.get_node("Room02Blockout")
	_check_join(room2.get_node("Room02ScreenWallLower_01"), room2.get_node("Room02ScreenWallUpper_01"), "Sala 2 screen wall")
	_check_join(room2.get_node("Room02EntryWinePanel_01"), room2.get_node("Room02EntryCreamPanel_01"), "Sala 2 entry wall")
	for room_name in ["Room03Blockout", "Room04Blockout"]:
		var room := main.get_node(room_name)
		_check_join(room.get_node("ScreenWallPanel_00"), room.get_node("ScreenWallPlaster_00"), "%s screen wall" % room_name)
		_check_join(room.get_node("EntryWestWingPanel_00"), room.get_node("EntryWestWingPlaster_00"), "%s entry wall" % room_name)
		for wall_label in ["ScreenWall", "EntryWestWing", "EntryEastWing"]:
			var panels := room.find_children("%sPanel_*" % wall_label, "Node3D", false, false)
			var pillars := room.find_children("%sPillar_*" % wall_label, "Node3D", false, false)
			_expect(pillars.size() == panels.size() + 1, "%s: %s has incomplete black columns" % [room_name, wall_label])
			for panel in panels:
				var panel_mesh := (panel.get_child(0) as MeshInstance3D).mesh as BoxMesh
				if room_name == "Room04Blockout":
					_check_fear_panel_material(panel_mesh.material, "%s %s" % [room_name, wall_label])
				for edge in [-1.0, 1.0]:
					var edge_x: float = panel.position.x + edge * panel_mesh.size.x * 0.5
					var found_edge := false
					for pillar in pillars:
						if absf(pillar.position.x - edge_x) < 0.02:
							found_edge = true
					_expect(found_edge, "%s: %s has a bay without a bordering column" % [room_name, wall_label])
			if wall_label == "ScreenWall":
				var screen_z: float = room.get_node("Screen").position.z
				for pillar in pillars:
					_expect(absf(pillar.position.z - screen_z) >= 0.23, "%s: a column intersects the projection plane" % room_name)
	var fear_room := main.get_node("Room04Blockout")
	for side_panel in fear_room.find_children("SidePanel_*", "Node3D", false, false):
		var mesh := (side_panel.get_child(0) as MeshInstance3D).mesh as BoxMesh
		_check_fear_panel_material(mesh.material, "Sala 4 lateral wall")


func _check_fear_panel_material(material: Material, label: String) -> void:
	var red := material as StandardMaterial3D
	_expect(red != null, "%s: red material missing" % label)
	if red == null:
		return
	_expect(red.uv1_triplanar and not red.uv1_world_triplanar, "%s: red motif is not repeated inside each column bay" % label)
	_expect(is_equal_approx(red.uv1_scale.x, 1.0 / 5.4) and is_equal_approx(red.uv1_scale.y, 1.0 / 2.10) and is_equal_approx(red.uv1_scale.z, 1.0 / 5.4), "%s: red motif has inconsistent physical size" % label)


func _check_corridor_walls(main: Node3D) -> void:
	var expansion := main.get_node("CinemaExpansionBlockout")
	_check_join(expansion.get_node("LobbyNorthLower_00"), expansion.get_node("LobbyNorthUpper_00"), "vestibule")
	_check_join(expansion.get_node("FinalWallNorthLower_00"), expansion.get_node("FinalWallNorthUpper_00"), "left corridor")
	var right_wing := main.get_node("LeftWingBlockout")
	_check_join(right_wing.get_node("VestibuleSideSouthLower"), right_wing.get_node("VestibuleSideSouthUpper"), "right corridor")
	_check_join(right_wing.get_node("OfficeNorthLower"), right_wing.get_node("OfficeNorthUpper"), "manager office")


func _check_join(lower: Node3D, upper: Node3D, label: String) -> void:
	if lower == null or upper == null:
		_expect(false, "%s: red or aged-white wall segment missing" % label)
		return
	var lower_mesh := (lower.get_child(0) as MeshInstance3D).mesh as BoxMesh
	var upper_mesh := (upper.get_child(0) as MeshInstance3D).mesh as BoxMesh
	_expect(is_equal_approx(lower.position.y + lower_mesh.size.y * 0.5, 2.53), "%s: red wall does not end at the shared height" % label)
	_expect(is_equal_approx(upper.position.y - upper_mesh.size.y * 0.5, 2.53), "%s: aged-white wall does not begin at the shared height" % label)
	_expect(upper_mesh.material.resource_path.ends_with("corridor_aged_plaster.tres"), "%s: plain white replaced the aged plaster" % label)


func _at(nodes: Array[Node], center: float, side: int, target_z: float) -> Node3D:
	var found_node: Node3D
	for item in nodes:
		var node := item as Node3D
		if (node.position.x - center) * side > 0.0 and absf(node.position.z - target_z) < 0.02:
			if found_node != null:
				return null
			found_node = node
	return found_node


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("WALL BAY TEST: %s" % message)
