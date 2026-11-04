extends SceneTree

class ProbeManager extends Node:
	var moved_trash := {}
	var _save_dirty := false
	var coins := 0
	var bag_volume := 0

class ProbePlayer extends CharacterBody3D:
	func get_current_room_id() -> StringName: return &"room_01"

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func floor_box(world: Node3D, at: Vector3, size: Vector3, angle: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=size
	collision.shape=shape
	body.add_child(collision)
	world.add_child(body)
	body.global_position=at
	body.rotation.z=angle
	return body

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var manager := ProbeManager.new()
	world.add_child(manager)
	manager.add_to_group("gameplay_manager")
	var player := ProbePlayer.new()
	world.add_child(player)
	player.add_to_group("player")
	var registry := load("res://scripts/dense_trash_registry.gd").new() as Node3D
	world.add_child(registry)
	var results := []
	for surface in ["flat","ramp","step_down","step_up"]:
		var origin := Vector3(results.size()*18.0,0,0)
		var angle := 0.14 if surface=="ramp" else 0.0
		var floor := floor_box(world,origin+Vector3(0,-.25,0),Vector3(12,.5,12),angle)
		var normal := floor.global_basis.y
		var plane := floor.to_global(Vector3(0,.25,0))
		if surface=="step_down":
			floor_box(world,origin+Vector3(-1.6,.075,0),Vector3(3.2,.15,12))
		elif surface=="step_up":
			floor_box(world,origin+Vector3(1.6,.075,0),Vector3(3.2,.15,12))
		player.global_position=origin+Vector3(-1.5,.2,0)
		await physics_frame
		var indices: Array[int] = []
		for kind in ["ticket","napkin","straw","popcorn","can","bottle","cup","bucket"]:
			var definition := load("res://resources/trash/%s.tres" % kind)
			var info: Dictionary = registry._template(definition)
			var at := origin+Vector3(-.50,0,(indices.size()-3.5)*.65)
			at.y=plane.y-(at.x-plane.x)*normal.x/normal.y + (.15 if surface=="step_down" else 0.0)
			var tilt := Vector3(0,0,PI*.5) if kind in ["can","bottle","cup"] else Vector3.ZERO
			var pose: Dictionary = registry._ground_pose(at+Vector3.UP*.02,info,.45,tilt)
			check(not pose.is_empty(),"Unsupported test pose: %s/%s" % [surface,kind])
			if pose.is_empty(): continue
			indices.append(registry.add_entry(definition,&"room_01","%s:%s" % [surface,kind],pose.pos,pose.rot))
		registry._refresh_proxies()
		await physics_frame
		var starts := {}
		for index in indices:
			starts[index]=Vector3(registry.entries[index].pos)
			registry.sweep(registry.entries[index].pos,Vector3.RIGHT,.40,player)
		var minimum := 1.0
		var worst := {}
		for frame in 150:
			await physics_frame
			for index in indices:
				var entry: Dictionary = registry.entries[index]
				var bounds: AABB = registry.templates[String(entry.definition.id)].bounds
				var transform := Transform3D(Basis.from_euler(entry.rot),entry.pos)
				for corner in 8:
					var point := transform*bounds.get_endpoint(corner)
					var clearance := (point-plane).dot(normal)
					if (surface=="step_down" and point.x<origin.x) or (surface=="step_up" and point.x>=origin.x):
						# At a riser, measure penetration into the nearest face;
						# a corner touching its side is not buried 15cm vertically.
						var depth := absf(point.x-origin.x)
						clearance=maxf(point.y-.15,-depth)
					if clearance<minimum: worst={"id":entry.id,"point":str(point)}
					minimum=minf(minimum,clearance)
		check(minimum>=-.002,"Swept mesh entered %s floor by %.4fm" % [surface,-minimum])
		for index in indices:
			check(Vector3(registry.entries[index].pos).x>Vector3(starts[index]).x+.05,"Sweep did not move %s" % registry.entries[index].id)
		results.append({"surface":surface,"minimum_clearance":minimum,"worst":worst})
		for index in indices: registry.remove_entry(index)
		await process_frame
	check(manager.coins==0 and manager.bag_volume==0,"Sweeping collected or paid trash")
	check(registry.bodies.size()<=48,"Floor protection increased the physics budget")
	print("SWEPT_TRASH_FLOOR_METRICS ",JSON.stringify(results))
	world.queue_free()
	for frame in 3: await process_frame
	print("SWEPT_TRASH_FLOOR_OK" if failures.is_empty() else "SWEPT_TRASH_FLOOR_FAILED")
	quit(0 if failures.is_empty() else 1)
