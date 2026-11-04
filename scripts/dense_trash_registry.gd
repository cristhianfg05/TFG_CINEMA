extends Node3D

# Permanent data + shared render batches; only nearby entries get interaction
# colliders. Real rigid bodies are pooled by demand for local pile collapses.
const Proxy := preload("res://scripts/dense_trash_proxy.gd")
const CELL := 2.0
const CHUNK := 8.0
const MAX_PROXIES := 256
const MAX_BODIES := 48
const BROOM_PUSH_SPEED := 4.4 # Applies to the base broom and both upgrade levels.
const MOVING_COLLISION_CLEARANCE := 0.025
const FLOOR_VISUAL_CLEARANCE := 0.004
const COUNTS := {"room_01":Vector2i(600,50),"left_corridor":Vector2i(255,25),
	"manager_office":Vector2i(36,4),"room_02":Vector2i(990,110),"room_03":Vector2i(945,105),
	"lobby":Vector2i(1350,150),"right_corridor":Vector2i(185,15),"room_04":Vector2i(1320,130)}
var entries: Array[Dictionary] = []
var cells: Dictionary = {}
var groups: Dictionary = {}
var templates: Dictionary = {}
var proxies: Dictionary = {}
var bodies: Dictionary = {}
var wake_queue: Dictionary = {}
var manager: Node
var refresh_time := 0.0
var _revealed_room := ""
var _reveal_material: StandardMaterial3D
var profile_total_usec := 0
var profile_ticks := 0
var _placement_exclusions: Array[RID] = []
var _minimum_floor: Callable

func _ready() -> void:
	add_to_group("dense_trash_registry")
	manager = get_tree().get_first_node_in_group("gameplay_manager")

func _cell(pos: Vector3) -> Vector3i:
	return Vector3i(floori(pos.x / CELL),floori(pos.y / CELL),floori(pos.z / CELL))

func nearby(pos: Vector3, radius: float) -> Array[int]:
	var result: Array[int] = []
	var extent := ceili(radius / CELL)
	var base := _cell(pos)
	for x in range(-extent,extent+1):
		for y in range(-extent,extent+1):
			for z in range(-extent,extent+1):
				for index in cells.get(base + Vector3i(x,y,z),[]):
					var item: Dictionary = entries[index]
					if item.alive and not item.reserved and Vector3(item.pos).distance_squared_to(pos) <= radius*radius:
						result.append(index)
	return result

func populate(room: StringName, small: Array[Vector3], large: Array[Vector3], parent: Node3D = null) -> void:
	if not COUNTS.has(String(room)): return
	var count: Vector2i = COUNTS[String(room)]
	_migrate_room(room,count)
	manager.register_room_trash(room,count.x+count.y,count.x+count.y*2)
	if room == &"room_01":
		manager.total_trash = count.x+count.y
		manager.remaining_trash = int(manager.room_trash_remaining[String(room)])
	await get_tree().physics_frame
	if not is_inside_tree(): return
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player: _placement_exclusions = [player.get_rid()]
	_minimum_floor = Callable()
	if room==&"room_01": _minimum_floor = Callable(manager,"_get_trash_floor_height")
	elif room==&"room_02":
		_minimum_floor = func(at: Vector3) -> float:
			if at.z>=parent.SEATING_REAR_Z and at.z<=parent.SEATING_FRONT_Z:
				return parent._trash_surface_height(at.x,at.z)
			return -INF
	var rng := RandomNumberGenerator.new()
	rng.seed = int(manager._trash_layout_seed) + String(room).hash()
	var occupied := {}
	for size_class in 2:
		var anchors: Array[Vector3] = []
		for local_anchor in (small if size_class==0 else large):
			anchors.append(parent.to_global(local_anchor) if parent != null else local_anchor)
		if anchors.is_empty(): continue
		for index in range(anchors.size()-1,0,-1):
			var other := rng.randi_range(0,index)
			var swap := anchors[index]
			anchors[index] = anchors[other]
			anchors[other] = swap
		var pool: Array = manager.ONE_UNIT_DEFINITIONS if size_class==0 else manager.TWO_UNIT_DEFINITIONS
		var total := count.x if size_class==0 else count.y
		for i in total:
			var id := "%s:%s:%03d" % [room,"small" if size_class==0 else "large",i+1]
			var definition: Resource = pool[i % pool.size()]
			var info := _template(definition)
			var yaw := rng.randf_range(-PI,PI)
			var tilt := Vector3.ZERO
			if String(definition.id) in ["bottle","can","cup"] and rng.randf()<0.65:
				tilt.z = PI*.5 * (-1.0 if rng.randf()<.5 else 1.0)
			var pose := _scatter_pose(anchors,i,info,yaw,tilt,rng,occupied)
			# Consume the same layout/RNG slots for retired pieces too: collecting
			# one object must never shuffle the remaining room when continuing.
			_record_scatter_space(pose,occupied)
			if manager.is_world_trash_collected(id): continue
			var pos: Vector3 = pose.pos
			var rot: Vector3 = pose.rot
			if manager.moved_trash.has(id):
				var saved: Array = manager.moved_trash[id]
				var saved_rotation := Vector3(saved[3],saved[4],saved[5]) if saved.size()>=6 else rot
				var grounded := _ground_pose(Vector3(saved[0],saved[1],saved[2]),info,saved_rotation.y,Vector3(saved_rotation.x,0,saved_rotation.z))
				if not grounded.is_empty():
					pos = grounded.pos
					rot = grounded.rot
				manager.moved_trash[id] = [pos.x,pos.y,pos.z,rot.x,rot.y,rot.z]
				manager._save_dirty = true
			add_entry(definition,room,id,pos,rot)
	if room == &"room_01":
		manager.total_trash = count.x+count.y
		manager.remaining_trash = int(manager.room_trash_remaining[String(room)])
	manager.state_changed.emit()

func _scatter_pose(anchors: Array[Vector3], index: int, info: Dictionary, yaw: float,
		tilt: Vector3, rng: RandomNumberGenerator, occupied: Dictionary) -> Dictionary:
	var best := {}
	var best_score := -INF
	for attempt in 20:
		var anchor := anchors[(index+int(attempt/4)*37) % anchors.size()]
		var angle := rng.randf()*TAU
		var radius := sqrt(rng.randf()) * (0.32 if attempt<4 else 0.55)
		var offset := Vector3(cos(angle),0,sin(angle))*radius
		var side := PhysicsRayQueryParameters3D.create(anchor+Vector3.UP*.12,anchor+offset+Vector3.UP*.12,5)
		side.exclude = _placement_exclusions
		if not get_world_3d().direct_space_state.intersect_ray(side).is_empty(): continue
		var pose := _ground_pose(anchor+offset,info,yaw,tilt)
		if pose.is_empty(): continue
		var score := _scatter_clearance(pose,occupied)
		if score>best_score:
			best = pose
			best_score = score
		if score>=0.0: return pose
	if not best.is_empty(): return best
	# Narrow seat cushions and stair edges may reject the jitter footprint.
	# Fall back to a valid surface in this same room, never to a raised pile.
	for anchor in anchors:
		var pose := _ground_pose(anchor,info,yaw,Vector3.ZERO)
		if not pose.is_empty(): return pose
	push_error("No supported trash position in room at %s" % anchors[0])
	return {"pos":anchors[0],"rot":Vector3.ZERO,"radius":info.radius}

func _ground_pose(anchor: Vector3, info: Dictionary, yaw: float, tilt: Vector3) -> Dictionary:
	var occupancy := PhysicsPointQueryParameters3D.new()
	occupancy.position = anchor+Vector3.UP*.03
	occupancy.collision_mask = 5
	occupancy.exclude = _placement_exclusions
	if not get_world_3d().direct_space_state.intersect_point(occupancy,1).is_empty(): return {}
	var query := PhysicsRayQueryParameters3D.create(anchor+Vector3.UP*.08,anchor-Vector3.UP*2.0,5)
	query.exclude = _placement_exclusions
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or Vector3(hit.normal).y<.65: return {}
	var normal: Vector3 = hit.normal
	var z_axis := Vector3(sin(yaw),0,cos(yaw)).slide(normal).normalized()
	var alignment := Basis(normal.cross(z_axis).normalized(),normal,z_axis)
	var tip := Basis.from_euler(tilt)
	var resting_bounds: AABB = Transform3D(tip,Vector3.ZERO) * (info.bounds as AABB)
	var pos: Vector3 = hit.position-normal*resting_bounds.position.y+normal*.004
	# Check the four footprint corners against the actual support plane. This
	# prevents crossing risers or hanging over cushion edges in the initial pose.
	for x in [resting_bounds.position.x,resting_bounds.end.x]:
		for z in [resting_bounds.position.z,resting_bounds.end.z]:
			var corner: Vector3 = pos+alignment*Vector3(x,resting_bounds.position.y,z)
			var support := PhysicsRayQueryParameters3D.create(corner+Vector3.UP*.055,corner-Vector3.UP*.09,5)
			support.exclude = _placement_exclusions
			var contact := get_world_3d().direct_space_state.intersect_ray(support)
			if contact.is_empty() or absf(Vector3(contact.position).y-corner.y)>.045: return {}
	var basis := alignment*tip
	var world_bounds: AABB = Transform3D(basis,Vector3.ZERO) * (info.bounds as AABB)
	var center := pos+basis*Vector3(info.bounds.get_center())
	occupancy.position = center
	if not get_world_3d().direct_space_state.intersect_point(occupancy,1).is_empty(): return {}
	var transform := Transform3D(basis,pos)
	for endpoint in 8:
		var corner: Vector3 = transform*(info.bounds as AABB).get_endpoint(endpoint)
		occupancy.position = corner+Vector3.UP*.025
		if not get_world_3d().direct_space_state.intersect_point(occupancy,1).is_empty(): return {}
		if _minimum_floor.is_valid() and corner.y<float(_minimum_floor.call(corner))-.055: return {}
	return {"pos":pos,"rot":basis.get_euler(),"radius":clampf(Vector2(world_bounds.size.x,world_bounds.size.z).length()*.5,.05,.5)}

func _scatter_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x),floori(pos.z))

func _record_scatter_space(pose: Dictionary, occupied: Dictionary) -> void:
	var key := _scatter_cell(pose.pos)
	if not occupied.has(key): occupied[key] = []
	occupied[key].append(pose)

func _scatter_clearance(pose: Dictionary, occupied: Dictionary) -> float:
	var key := _scatter_cell(pose.pos)
	var result := 1.0
	for x in range(-1,2):
		for z in range(-1,2):
			for other in occupied.get(key+Vector2i(x,z),[]):
				if absf(Vector3(other.pos).y-Vector3(pose.pos).y)>.3: continue
				var distance := Vector2(Vector3(other.pos).x-Vector3(pose.pos).x,Vector3(other.pos).z-Vector3(pose.pos).z).length()
				result = minf(result,distance-(float(other.radius)+float(pose.radius))*.65)
	return result

func _migrate_room(room: StringName, count: Vector2i) -> void:
	if not manager.legacy_layout_pending or manager.legacy_layout_migrated.has(String(room)): return
	var old_totals := {"room_01":400,"left_corridor":120,"manager_office":18,"room_02":480,"room_03":440,"lobby":555,"right_corridor":90,"room_04":660}
	var retired := 0
	for key in manager._collected_world_trash_ids:
		if String(key).begins_with(String(room)+":"): retired+=1
	var fraction := float(retired)/float(old_totals[String(room)])
	if room==&"room_01" and manager.room_completed: fraction=0.95
	if manager.final_wall_open: fraction=1.0
	var wanted := mini(count.x+count.y,ceili(fraction*float(count.x+count.y)))
	for large in 2:
		for index in (count.x if large==0 else count.y):
			if retired>=wanted: break
			var id := "%s:%s:%03d" % [room,"small" if large==0 else "large",index+1]
			if not manager._collected_world_trash_ids.has(id):
				manager._collected_world_trash_ids[id]=true
				retired+=1
	manager.legacy_layout_migrated[String(room)]=true
	if manager.legacy_layout_migrated.size()==COUNTS.size(): manager.legacy_layout_pending=false
	manager._save_dirty=true

func _template(definition: Resource) -> Dictionary:
	var key := String(definition.id)
	if templates.has(key): return templates[key]
	var model := definition.model.instantiate() as Node3D
	var prefix := Transform3D(Basis.from_euler(Vector3(definition.model_rotation_degrees)*PI/180.0).scaled(Vector3.ONE*float(definition.model_scale)),Vector3.ZERO)
	var parts: Array[Dictionary] = []
	_extract_parts(model, prefix * model.transform, parts)
	var bounds := AABB()
	var first := true
	for part in parts:
		var box: AABB = part.transform * part.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	model.free()
	var info := {"parts":parts,"bottom":bounds.position.y,"top":bounds.end.y,
		"radius":clampf(Vector2(bounds.size.x,bounds.size.z).length()*.5,0.05,0.40),"bounds":bounds}
	templates[key] = info
	return info

func _extract_parts(node: Node3D, transform: Transform3D, parts: Array[Dictionary]) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var mesh := node.mesh.duplicate() as Mesh
		for surface in mesh.get_surface_count():
			var source: Material = node.material_override if node.material_override else node.get_active_material(surface)
			if source is StandardMaterial3D:
				var material := source.duplicate() as StandardMaterial3D
				material.vertex_color_use_as_albedo = true
				mesh.surface_set_material(surface,material)
		parts.append({"mesh":mesh,"transform":transform})
	for child in node.get_children():
		if child is Node3D: _extract_parts(child,transform*child.transform,parts)

func add_entry(definition: Resource, room: StringName, id: String, pos: Vector3, rot: Vector3) -> int:
	var info := _template(definition)
	var key := "%s:%s:%d:%d" % [room,definition.id,floori(pos.x/CHUNK),floori(pos.z/CHUNK)]
	if not groups.has(key):
		var views: Array[MultiMeshInstance3D] = []
		for part in info.parts:
			var view := MultiMeshInstance3D.new()
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = part.mesh
			view.multimesh = mm
			view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Visibility follows the moving batch, rather than its original center.
			add_child(view)
			views.append(view)
		groups[key] = {"views":views,"indices":[],"capacity":0,"room":String(room),"parts":info.parts}
	var group: Dictionary = groups[key]
	var index := entries.size()
	var oriented: AABB = Transform3D(Basis.from_euler(rot),Vector3.ZERO) * (info.bounds as AABB)
	var entry := {"definition":definition,"room":room,"id":id,"pos":pos,"rot":rot,
		"alive":true,"reserved":false,"group":key,"slot":group.indices.size(),"cell":_cell(pos),
		"radius":info.radius,"bottom":oriented.position.y,"top":oriented.end.y}
	entries.append(entry)
	group.indices.append(index)
	if not cells.has(entry.cell): cells[entry.cell] = []
	cells[entry.cell].append(index)
	if group.indices.size() > int(group.capacity):
		group.capacity = int(group.capacity)+32
		for view in group.views: view.multimesh.instance_count = int(group.capacity)
		for existing in group.indices: _render(existing)
	else:
		_render(index)
	for view in group.views: view.multimesh.visible_instance_count = group.indices.size()
	return index

func _render(index: int) -> void:
	var entry: Dictionary = entries[index]
	var group: Dictionary = groups[entry.group]
	var base := Transform3D(Basis.from_euler(entry.rot),entry.pos)
	if not entry.alive or entry.reserved: base.basis = Basis.from_scale(Vector3.ZERO)
	for part in group.views.size():
		var view: MultiMeshInstance3D = group.views[part]
		view.multimesh.set_instance_transform(entry.slot,base*group.parts[part].transform)
		view.multimesh.set_instance_color(entry.slot,Color.WHITE)
		var bounds := AABB(Vector3(entry.pos)-Vector3.ONE,Vector3.ONE*2.0)
		view.multimesh.custom_aabb = bounds if view.multimesh.custom_aabb.size==Vector3.ZERO else view.multimesh.custom_aabb.merge(bounds)

func tint(index: int, color: Color) -> void:
	var entry: Dictionary = entries[index]
	for view in groups[entry.group].views: view.multimesh.set_instance_color(entry.slot,color)

func _set_position(index: int, pos: Vector3, rot: Vector3) -> void:
	var entry: Dictionary = entries[index]
	var cell := _cell(pos)
	if cell != entry.cell:
		cells[entry.cell].erase(index)
		if not cells.has(cell): cells[cell] = []
		cells[cell].append(index)
		entry.cell = cell
	entry.pos = pos
	entry.rot = rot
	var oriented: AABB = Transform3D(Basis.from_euler(rot),Vector3.ZERO) * (templates[String(entry.definition.id)].bounds as AABB)
	entry.bottom = oriented.position.y
	entry.top = oriented.end.y
	if proxies.has(index) and not proxies[index].collecting:
		proxies[index].global_position = pos
		proxies[index].rotation = rot
	manager.moved_trash[entry.id] = [pos.x,pos.y,pos.z,rot.x,rot.y,rot.z]
	manager._save_dirty = true
	_render(index)

func reserve(index: int) -> void:
	entries[index].reserved = true
	_retire_body(index)
	_render(index)
	for other in nearby(entries[index].pos + Vector3.UP*.35,0.95):
		if other != index and Vector3(entries[other].pos).y > Vector3(entries[index].pos).y:
			wake_queue[other] = Vector3.ZERO

func remove_entry(index: int) -> void:
	if not entries[index].alive: return
	_retire_body(index)
	wake_queue.erase(index)
	entries[index].alive = false
	manager.moved_trash.erase(entries[index].id)
	cells[entries[index].cell].erase(index)
	var proxy = proxies.get(index)
	proxies.erase(index)
	if is_instance_valid(proxy): proxy.queue_free()
	var group: Dictionary = groups[entries[index].group]
	var slot := int(entries[index].slot)
	var last := int(group.indices.back())
	group.indices[slot] = last
	entries[last].slot = slot
	group.indices.pop_back()
	if last != index: _render(last)
	for view in group.views: view.multimesh.visible_instance_count = group.indices.size()

func pull(index: int, target: Vector3, delta: float) -> void:
	if not entries[index].alive or entries[index].reserved: return
	_wake(index,(target-Vector3(entries[index].pos)).normalized()*4.4)
	if bodies.has(index):
		var body: RigidBody3D = bodies[index].body
		body.linear_velocity = body.linear_velocity.move_toward((target-body.global_position).normalized()*4.4,19.0*delta)

func sweep(center: Vector3, forward: Vector3, width: float, player: Node3D) -> void:
	var side := Vector3(-forward.z,0,forward.x)
	for index in nearby(center,1.8):
		var offset: Vector3 = entries[index].pos-center
		if absf(offset.dot(side)) > width*.5 or absf(offset.dot(forward)) > 0.65 or absf(offset.y) > 1.15: continue
		var target: Vector3 = entries[index].pos + Vector3.UP*maxf(.08,(float(entries[index].bottom)+float(entries[index].top))*.5)
		var query := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*.4,target,5)
		query.exclude = [player.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		wake_queue[index] = forward*BROOM_PUSH_SPEED + Vector3.UP*.12

func _wake(index: int, velocity: Vector3) -> void:
	if bodies.has(index):
		if not velocity.is_zero_approx():
			bodies[index].body.sleeping = false
			bodies[index].body.linear_velocity = velocity.limit_length(4.5)
		return
	if bodies.size() >= MAX_BODIES or not proxies.has(index): return
	var entry: Dictionary = entries[index]
	if not entry.alive or entry.reserved: return
	var body := RigidBody3D.new()
	body.collision_layer = 16
	body.collision_mask = 21
	body.continuous_cd = true
	body.mass = 0.08*int(entry.definition.size_units)
	body.linear_damp = 4.2
	body.angular_damp = 4.0
	var collision := CollisionShape3D.new()
	# Keep the moving collider slightly outside the visible mesh. Thin paper
	# otherwise disappears inside the solver's normal contact tolerance.
	var shape := proxies[index].get_node("Shape").shape.duplicate() as BoxShape3D
	shape.size += Vector3.ONE * MOVING_COLLISION_CLEARANCE * 2.0
	shape.margin = 0.004
	collision.shape = shape
	collision.position = proxies[index].get_node("Shape").position
	body.add_child(collision)
	add_child(body)
	body.global_position = entry.pos
	body.rotation = entry.rot
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	if player:
		body.add_collision_exception_with(player)
		player.add_collision_exception_with(body)
		_placement_exclusions = [player.get_rid()]
	body.linear_velocity = velocity
	body.angular_velocity = Vector3(0.2,0.4,0.3) if velocity.length() > 0.1 else Vector3.ZERO
	proxies[index].collision_layer = 2
	bodies[index] = {"body":body,"age":0.0,"last_transform":body.global_transform}

func _retire_body(index: int) -> void:
	if bodies.has(index):
		bodies[index].body.queue_free()
		bodies.erase(index)
	if proxies.has(index) and not proxies[index].collecting: proxies[index].collision_layer = 18

func _floor(anchor: Vector3, depth: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(anchor+Vector3.UP*.08,anchor-Vector3.UP*depth,5)
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player: query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit.position.y) if not hit.is_empty() else maxf(0.0,anchor.y-.24)

func _has_resting_support(index: int, body: RigidBody3D) -> bool:
	var bounds: AABB = templates[String(entries[index].definition.id)].bounds
	var box: AABB = body.global_transform*bounds
	var foot := Vector3(box.get_center().x,box.position.y,box.get_center().z)
	var query := PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.04,foot-Vector3.UP*.08,21)
	query.exclude = [body.get_rid()]
	if proxies.has(index): query.exclude.append(proxies[index].get_rid())
	var contact := get_world_3d().direct_space_state.intersect_ray(query)
	return not contact.is_empty() and Vector3(contact.normal).y>.4

func _keep_body_above_surface(index: int, body: RigidBody3D) -> void:
	var bounds: AABB = templates[String(entries[index].definition.id)].bounds
	var previous: Transform3D = bodies[index].last_transform
	var current := body.global_transform
	var lift := 0.0
	var support_normal := Vector3.UP
	var space := get_world_3d().direct_space_state
	for corner_index in 8:
		var local := bounds.get_endpoint(corner_index)
		var point := current * local
		var last_point := previous * local
		# Follow the swept height, not a tall ray from above the room: this
		# catches falling/rotating pieces without pulling trash through seats.
		var start := Vector3(point.x,maxf(point.y,last_point.y)+0.08,point.z)
		var query := PhysicsRayQueryParameters3D.create(start,point-Vector3.UP*.02,5)
		query.exclude = _placement_exclusions
		var hit := space.intersect_ray(query)
		if hit.is_empty() or Vector3(hit.normal).y<.65: continue
		var correction := Vector3(hit.position).y + FLOOR_VISUAL_CLEARANCE - point.y
		if correction>lift:
			lift=correction
			support_normal=hit.normal
	if lift>0.0005:
		body.global_position.y += lift
		if body.linear_velocity.dot(support_normal)<0.0:
			body.linear_velocity=body.linear_velocity.slide(support_normal)

func _physics_process(delta: float) -> void:
	var started := Time.get_ticks_usec()
	refresh_time -= delta
	if refresh_time <= 0.0:
		refresh_time = 0.12
		_refresh_proxies()
	for index in wake_queue.keys():
		if bodies.size() >= MAX_BODIES: break
		_wake(index,wake_queue[index])
		wake_queue.erase(index)
	for index in bodies.keys():
		var body: RigidBody3D = bodies[index].body
		bodies[index].age = float(bodies[index].age)+delta
		_keep_body_above_surface(index,body)
		bodies[index].last_transform=body.global_transform
		_set_position(index,body.global_position,body.rotation)
		# A low velocity at the apex of a flight is not a resting pose. Never
		# freeze a moving piece in mid-air just because its speed briefly hits 0.
		if float(bodies[index].age)>0.65 and (body.sleeping or (body.linear_velocity.length()<0.04 and _has_resting_support(index,body))):
			_retire_body(index)
	profile_total_usec += Time.get_ticks_usec()-started
	profile_ticks += 1

func _refresh_proxies() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null: return
	var local := nearby(player.global_position+Vector3.UP*.5,6.0)
	local.sort_custom(func(a: int,b: int): return Vector3(entries[a].pos).distance_squared_to(player.global_position)<Vector3(entries[b].pos).distance_squared_to(player.global_position))
	local.resize(mini(local.size(),MAX_PROXIES))
	for index in proxies.keys():
		if not is_instance_valid(proxies[index]) or proxies[index].is_queued_for_deletion():
			proxies.erase(index)
			continue
		if index not in local and not proxies[index].collecting and not bodies.has(index):
			proxies[index].queue_free()
			proxies.erase(index)
	for index in local:
		if proxies.has(index): continue
		if proxies.size() >= MAX_PROXIES: break
		var entry: Dictionary = entries[index]
		var proxy := Proxy.new()
		proxy.registry = self
		proxy.entry_index = index
		proxy.definition = entry.definition
		proxy.room_id = entry.room
		proxy.world_item_id = entry.id
		# Other systems may remove a proxy (debug cleanup, scene teardown).
		# Never retain a freed node; an alive entry can obtain a new proxy later.
		proxy.tree_exiting.connect(_on_proxy_tree_exiting.bind(index,proxy))
		var collision := CollisionShape3D.new()
		collision.name = "Shape"
		var bounds: AABB = templates[String(entry.definition.id)].bounds
		var shape := BoxShape3D.new()
		shape.size = Vector3(maxf(bounds.size.x,.06),maxf(bounds.size.y,.025),maxf(bounds.size.z,.06))
		collision.shape = shape
		collision.position = bounds.get_center()
		proxy.add_child(collision)
		add_child(proxy)
		proxy.global_position = entry.pos
		proxy.rotation = entry.rot
		proxies[index] = proxy
		# Already resting on their surface. Proximity only enables interaction;
		# it must not start a visible gravity/settling pass on entering the room.
	var room := String(player.get_current_room_id())
	for group in groups.values():
		for view in group.views:
			var bounds: AABB = view.multimesh.custom_aabb
			var nearest := player.global_position.clamp(bounds.position, bounds.end)
			var distance_squared := nearest.distance_squared_to(player.global_position)
			view.visible = not group.indices.is_empty() and ((group.room==room and distance_squared<676.0) or distance_squared<100.0 or group.room==_revealed_room)

func _on_proxy_tree_exiting(index: int, proxy: Node) -> void:
	# A replacement may already exist when an old proxy finishes queue_free().
	if proxies.get(index) == proxy:
		proxies.erase(index)

func reveal(room: StringName, enabled: bool) -> void:
	_revealed_room = String(room) if enabled else ""
	if _reveal_material == null:
		_reveal_material = StandardMaterial3D.new()
		_reveal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_reveal_material.no_depth_test = true
		_reveal_material.albedo_color = Color("f4ad37")
	for group in groups.values():
		for view in group.views:
			view.material_overlay = _reveal_material if enabled and group.room==String(room) else null
