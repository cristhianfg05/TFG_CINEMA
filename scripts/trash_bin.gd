extends StaticBody3D

@export var room_id: StringName = &"room_01"

const GUIDANCE_BASE_HEIGHT := 2.35
const GUIDANCE_GOLD := Color("e9ad3d")
const REAR_REJECTION_DOT := -0.45
const UNIT_DEPOSIT_HEIGHT := 1.25

var _meshes: Array[MeshInstance3D] = []
var _base_materials: Array[Material] = []
var _highlight_materials: Array[Material] = []
var _model_base_scale := Vector3.ONE
var _pending_deposit_pulses := 0
var _deposit_animation_running := false
var _guidance_arrow: Node3D
var _guidance_time := 0.0
var _manager: Node
var _unit_visuals := 0
var _deposit_models: Dictionary = {}
var _focus_prewarmed := false
var _focus_requested := false
const DEPOSIT_POOL_PER_TYPE := 4


func _ready() -> void:
	_model_base_scale = $Model.scale
	_find_meshes($Model)
	for mesh in _meshes:
		var original_override := mesh.material_override
		var source_material := original_override
		if source_material == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
			source_material = mesh.mesh.surface_get_material(0)
		_base_materials.append(original_override)
		var highlighted := source_material.duplicate() as Material if source_material != null else StandardMaterial3D.new()
		if highlighted is StandardMaterial3D:
			var standard := highlighted as StandardMaterial3D
			standard.emission_enabled = true
			standard.emission = Color("6a5114")
			standard.emission_energy_multiplier = 0.55
		_highlight_materials.append(highlighted)
	_build_guidance_arrow()
	_manager = get_tree().get_first_node_in_group("gameplay_manager")
	if _manager and _manager.has_signal("state_changed"):
		_manager.state_changed.connect(_refresh_guidance_arrow)
	_refresh_guidance_arrow()
	_prepare_deposit_models()
	if DisplayServer.get_name()=="headless": _focus_prewarmed=true
	else: call_deferred("_prewarm_interaction")


func _process(delta: float) -> void:
	if _guidance_arrow == null or not _guidance_arrow.visible:
		return
	_guidance_time += delta
	var bob := sin(_guidance_time * TAU / 1.05)
	var accordion := sin(_guidance_time * TAU / 0.72)
	_guidance_arrow.position.y = GUIDANCE_BASE_HEIGHT + bob * 0.12
	_guidance_arrow.scale = Vector3(
		1.0 + accordion * 0.055,
		1.0 - accordion * 0.085,
		1.0 + accordion * 0.055
	)


func _build_guidance_arrow() -> void:
	_guidance_arrow = Node3D.new()
	_guidance_arrow.name = "GuidanceArrow"
	_guidance_arrow.position = Vector3(0.0, GUIDANCE_BASE_HEIGHT, 0.0)
	_guidance_arrow.visible = false
	add_child(_guidance_arrow)

	var material := StandardMaterial3D.new()
	material.albedo_color = GUIDANCE_GOLD
	material.roughness = 0.48
	material.metallic = 0.16
	material.emission_enabled = true
	material.emission = Color("9b5d16")
	material.emission_energy_multiplier = 0.85

	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.14, 0.46, 0.14)
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	shaft.position.y = 0.20
	shaft.mesh = shaft_mesh
	shaft.material_override = material
	_guidance_arrow.add_child(shaft)

	var point_mesh := CylinderMesh.new()
	point_mesh.top_radius = 0.29
	point_mesh.bottom_radius = 0.0
	point_mesh.height = 0.34
	point_mesh.radial_segments = 6
	point_mesh.rings = 1
	var point := MeshInstance3D.new()
	point.name = "Point"
	point.position.y = -0.18
	point.mesh = point_mesh
	point.material_override = material
	_guidance_arrow.add_child(point)


func _refresh_guidance_arrow() -> void:
	if _guidance_arrow == null:
		return
	var should_show := (
		room_id == &"room_01"
		and _manager != null
		and _manager.has_method("is_trash_bin_guidance_active")
		and bool(_manager.is_trash_bin_guidance_active())
	)
	_guidance_arrow.visible = should_show
	set_process(should_show)
	if not should_show:
		_guidance_time = 0.0
		_guidance_arrow.position.y = GUIDANCE_BASE_HEIGHT
		_guidance_arrow.scale = Vector3.ONE


func is_guidance_arrow_visible() -> bool:
	return _guidance_arrow != null and _guidance_arrow.visible


func get_guidance_arrow() -> Node3D:
	return _guidance_arrow


func set_focused(focused: bool) -> void:
	_focus_requested=focused
	if not _focus_prewarmed: return
	for mesh_index in _meshes.size():
		_meshes[mesh_index].material_override = (
			_highlight_materials[mesh_index] if focused else _base_materials[mesh_index]
		)


func _find_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_meshes.append(node)
	for child in node.get_children():
		_find_meshes(child)


func get_interaction_prompt() -> String:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager and not manager.carried_sack.is_empty():
		return "Acerca el saco para reciclarlo"
	if manager and manager.bag_volume > 0:
		return "Mantén E — Entregar basura (%d uds.)" % manager.bag_volume
	return "Bolsa vacía"


func interact(_player: Node) -> void:
	var manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.begin_deposit(self)


func _prepare_deposit_models() -> void:
	if _manager==null: return
	for definition in _manager.ONE_UNIT_DEFINITIONS + _manager.TWO_UNIT_DEFINITIONS:
		var pool: Array[Node3D] = []
		for slot in DEPOSIT_POOL_PER_TYPE:
			var wrapper := Node3D.new()
			wrapper.name="UnitDeposit_%s_%d" % [definition.id,slot]
			wrapper.set_meta("definition_id",String(definition.id))
			wrapper.set_meta("in_use",false)
			var model: Node3D = definition.model.instantiate()
			model.scale=Vector3.ONE*float(definition.model_scale)
			model.rotation_degrees=definition.model_rotation_degrees
			wrapper.add_child(model)
			# Animate the item's centre, since the supplied assets have different
			# ground pivots. A bottle must not rise a whole bottle-height above
			# the same trajectory followed by a flat ticket.
			var bounds := AABB()
			var first := true
			for mesh in wrapper.find_children("*","MeshInstance3D",true,false):
				mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var transform: Transform3D=mesh.transform
				var ancestor: Node=mesh.get_parent()
				while ancestor != wrapper:
					if ancestor is Node3D: transform=ancestor.transform*transform
					ancestor=ancestor.get_parent()
				var box: AABB=transform*mesh.mesh.get_aabb()
				bounds=box if first else bounds.merge(box)
				first=false
			model.position-=bounds.get_center()
			add_child(wrapper)
			wrapper.hide()
			pool.append(wrapper)
		_deposit_models[String(definition.id)]=pool

func _prewarm_interaction() -> void:
	# Draw the real focus materials and item meshes during startup, before a
	# first glance or deposit can compile their render pipelines on demand.
	var viewport := SubViewport.new()
	viewport.name="BinInteractionWarmup"
	viewport.size=Vector2i(128,96)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(viewport)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=5.0
	camera.position=Vector3(0,.5,5)
	viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-30,-25,0)
	viewport.add_child(light)
	for highlighted in [false,true]:
		var copy := $Model.duplicate() as Node3D
		copy.position=Vector3(-1.7 if highlighted else -1.0,-.45,0)
		copy.scale=Vector3.ONE*.7
		viewport.add_child(copy)
		if highlighted:
			for index in _meshes.size():
				var path: NodePath=$Model.get_path_to(_meshes[index])
				(copy.get_node(path) as MeshInstance3D).material_override=_highlight_materials[index]
	var index := 0
	for pool in _deposit_models.values():
		var copy := (pool[0] as Node3D).duplicate() as Node3D
		viewport.add_child(copy)
		copy.show()
		copy.position=Vector3(-.25+float(index%4)*.58,-.3+float(index/4)*.7,0)
		index+=1
	await RenderingServer.frame_post_draw
	_focus_prewarmed=true
	viewport.queue_free()
	set_focused(_focus_requested)

func get_deposit_flight_point(start: Vector3, end: Vector3, progress: float) -> Vector3:
	var control := (start+end)*.5+Vector3.UP*clampf(start.distance_to(end)*.4,.35,.6)
	return start.bezier_interpolate(control,control,end,progress)

func play_unit_deposit(definition_id: String = "") -> void:
	var scrap: Node3D
	for candidate in _deposit_models.get(definition_id,[]):
		if not bool(candidate.get_meta("in_use")):
			scrap=candidate
			break
	if scrap != null:
		_unit_visuals+=1
		scrap.set_meta("in_use",true)
		scrap.scale=Vector3.ONE
		scrap.show()
		var player := get_tree().get_first_node_in_group("player") as PlayerController
		var start := get_absorption_point()+global_basis.z*.8+Vector3.UP*.45
		if player: start=player.camera.to_global(Vector3(.28,-.38,-.70))
		var end := global_position+Vector3.UP*UNIT_DEPOSIT_HEIGHT
		var initial_rotation := Vector3(.12,randf()*TAU,-.18)
		scrap.global_position=start
		scrap.rotation=initial_rotation
		scrap.set_meta("flight_start",start)
		scrap.set_meta("flight_end",end)
		var duration := .55
		var flight := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		flight.tween_method(func(t: float):
			scrap.global_position=get_deposit_flight_point(start,end,t)
			scrap.rotation=initial_rotation+Vector3(.7,1.3,.4)*t
			scrap.scale=Vector3.ONE*lerpf(1.0,.10,clampf((t-.82)/.18,0,1)),0.0,1.0,duration)
		flight.tween_callback(func():
			scrap.hide()
			scrap.set_meta("in_use",false)
			_unit_visuals-=1
			if is_instance_valid(_manager): _manager.play_unit_deposit_feedback())
	elif _manager != null:
		_manager.play_unit_deposit_feedback()
	$Model.scale = _model_base_scale * Vector3(1.02, 0.96, 1.02)
	if _deposit_animation_running:
		return
	_deposit_animation_running = true
	var pulse := create_tween()
	pulse.tween_property($Model, "scale", _model_base_scale, 0.10)
	pulse.tween_callback(func(): _deposit_animation_running = false)


func get_absorption_point() -> Vector3:
	# The sack is tested against the opening instead of the bin's floor pivot.
	return global_position + Vector3.UP * 0.68


func can_accept_sack(sack: Node3D, radius: float) -> bool:
	if sack == null or not is_instance_valid(sack):
		return false
	var absorption_point := get_absorption_point()
	if not sack.has_method("is_within_absorption_radius"):
		return false
	if not sack.is_within_absorption_radius(absorption_point, radius):
		return false
	var probe_position: Vector3 = (
		sack.get_absorption_probe_position()
		if sack.has_method("get_absorption_probe_position")
		else sack.global_position
	)
	if not is_position_in_acceptance_arc(probe_position):
		return false
	return _has_clear_absorption_path(probe_position, sack)


func is_position_in_acceptance_arc(world_position: Vector3) -> bool:
	var to_source := world_position - get_absorption_point()
	to_source.y = 0.0
	if to_source.is_zero_approx():
		return true
	# The supplied bin model's opening points along local +Z. With the current
	# 180-degree placement this is world -Z, toward the cinema screen.
	var intake_forward := global_basis.z
	intake_forward.y = 0.0
	intake_forward = intake_forward.normalized()
	return intake_forward.dot(to_source.normalized()) >= REAR_REJECTION_DOT


func _has_clear_absorption_path(world_position: Vector3, sack: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(get_absorption_point(), world_position, 1)
	query.exclude = [get_rid()]
	if sack is CollisionObject3D:
		query.exclude.append((sack as CollisionObject3D).get_rid())
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func play_deposit_animation() -> void:
	# Queue nearby deliveries instead of creating competing tweens on the model.
	_pending_deposit_pulses = mini(_pending_deposit_pulses + 1, 4)
	if not _deposit_animation_running:
		_run_deposit_animation()


func _run_deposit_animation() -> void:
	_deposit_animation_running = true
	while _pending_deposit_pulses > 0:
		_pending_deposit_pulses -= 1
		$Model.scale = _model_base_scale
		var tween := create_tween()
		tween.tween_property($Model, "scale", _model_base_scale * Vector3(1.055, 0.84, 1.055), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property($Model, "scale", _model_base_scale * Vector3(0.975, 1.075, 0.975), 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property($Model, "scale", _model_base_scale, 0.17).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished
	_deposit_animation_running = false
