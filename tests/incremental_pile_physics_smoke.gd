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

func solid(world: Node3D, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=size
	collision.shape=shape
	body.add_child(collision)
	world.add_child(body)
	body.global_position=at

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var manager := ProbeManager.new()
	world.add_child(manager)
	manager.add_to_group("gameplay_manager")
	var player := ProbePlayer.new()
	world.add_child(player)
	player.add_to_group("player")
	player.position=Vector3(0,0,1.5)
	solid(world,Vector3(0,-.25,0),Vector3(12,.5,12))
	var registry := load("res://scripts/dense_trash_registry.gd").new() as Node3D
	world.add_child(registry)
	var definition := load("res://resources/trash/bucket.tres")
	var info: Dictionary = registry._template(definition)
	var height := float(info.top)-float(info.bottom)
	var lower := Vector3(0,-float(info.bottom)+.015,0)
	await physics_frame
	var restored: Dictionary = registry._ground_pose(Vector3(2,1.1,0),info,.8,Vector3.ZERO)
	check(not restored.is_empty() and absf(Vector3(restored.pos).y+float(info.bottom))<.015,"A saved airborne object did not settle before becoming visible")
	var bottom: int = registry.add_entry(definition,&"room_01","probe:bottom",lower,Vector3.ZERO)
	var top: int = registry.add_entry(definition,&"room_01","probe:top",lower+Vector3.UP*(height+.015),Vector3.ZERO)
	var airborne: int = registry.add_entry(definition,&"room_01","probe:airborne",Vector3(-3,1,0),Vector3.ZERO)
	for frame in 10: await physics_frame
	registry._wake(airborne,Vector3.ZERO)
	var airborne_body: RigidBody3D = registry.bodies[airborne].body
	airborne_body.sleeping=false
	airborne_body.linear_velocity=Vector3.ZERO
	registry.bodies[airborne].age=1.0
	registry._physics_process(0.0)
	check(registry.bodies.has(airborne),"A zero-velocity airborne piece was frozen at its apex")
	for frame in 100: await physics_frame
	var before: Vector3 = registry.entries[top].pos
	var proxy: Node3D = registry.proxies[bottom]
	proxy.collecting=true
	proxy.collision_layer=0
	registry.reserve(bottom)
	registry.remove_entry(bottom)
	proxy.queue_free()
	for frame in 100: await physics_frame
	var after: Vector3 = registry.entries[top].pos
	check(after.y < before.y - height*.35,"Upper trash did not fall after removing its support")
	check(after.y+float(info.bottom)>-.04,"Falling trash penetrated the floor")
	check(manager.coins==0 and manager.bag_volume==0,"Pile collapse collected or paid trash")
	# A large object must also be sweepable, and a solid wall must stop it.
	var start: Vector3 = registry.entries[top].pos
	solid(world,Vector3(start.x+.55,.6,start.z),Vector3(.12,1.2,3))
	player.global_position=start-Vector3.RIGHT*.8
	for frame in 3: await physics_frame
	registry.sweep(start,Vector3.RIGHT,1.6,player)
	for frame in 90: await physics_frame
	var swept: Vector3 = registry.entries[top].pos
	check(swept.x>start.x+.03,"Broom did not move a large trash object")
	check(swept.x<start.x+.55,"Broom pushed trash through a solid wall")
	check(manager.coins==0 and manager.bag_volume==0,"Broom put trash in the bag or paid money")
	var pull_start: Vector3 = registry.entries[top].pos
	registry.pull(top,pull_start+Vector3(-1,.3,0),1.0/60.0)
	for frame in 12: await physics_frame
	check(Vector3(registry.entries[top].pos).x<pull_start.x-.05,"Vacuum could not pull large trash")
	check(registry.bodies.size()<=48 and registry.proxies.size()<=256,"Physics pool exceeded its cap")
	print("PILE_PHYSICS_METRICS ",JSON.stringify({"height":height,"fall":before.y-after.y,"sweep":swept.x-start.x,"bodies":registry.bodies.size()}))
	world.queue_free()
	for frame in 5: await process_frame
	print("INCREMENTAL_PILE_PHYSICS_OK" if failures.is_empty() else "INCREMENTAL_PILE_PHYSICS_FAILED")
	quit(0 if failures.is_empty() else 1)
