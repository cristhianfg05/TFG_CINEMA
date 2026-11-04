extends Control

const SWEEP_DURATION := 0.46
const REST_POSITION := Vector3(0.36, -0.72, -1.52)
const PUSH_OFFSET := Vector3(-0.035, -0.10, -0.60)

var manager: Node
var viewport: SubViewport
var pose: Node3D
var sweep_time := 0.0

func _ready() -> void:
	name = "BroomFirstPersonView"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.stretch = true
	add_child(container)
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.size = Vector2i(get_viewport_rect().size)
	container.add_child(viewport)
	var camera := Camera3D.new()
	camera.fov = 55
	viewport.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35,-30,0)
	key.light_energy = 1.8
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15,140,0)
	fill.light_energy = 0.7
	viewport.add_child(fill)
	pose = load("res://assets/pipeline/props/cinema_broom.glb").instantiate()
	pose.scale = Vector3.ONE * 0.55
	camera.add_child(pose)
	manager = get_tree().get_first_node_in_group("gameplay_manager")
	if manager:
		manager.broom_swept.connect(func(): sweep_time = SWEEP_DURATION)
	_update_pose()

func _process(delta: float) -> void:
	if manager == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	visible = manager.equipped_tool == "broom" and not (manager.hammer_taken and not manager.final_wall_open) and player != null and not player.is_sitting()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible and is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	sweep_time = maxf(0.0, sweep_time - delta)
	_update_pose()

func _update_pose() -> void:
	var elapsed := SWEEP_DURATION - sweep_time
	var reach := 0.0
	if sweep_time > 0.0:
		if elapsed < 0.07:
			reach = -0.10 * smoothstep(0.0, 0.07, elapsed)
		elif elapsed < 0.24:
			reach = lerpf(-0.10, 1.0, smoothstep(0.07, 0.24, elapsed))
		else:
			reach = 1.0 - smoothstep(0.24, SWEEP_DURATION, elapsed)
	# The head stays low; the handle leans back towards the player. Push away
	# along camera depth instead of swinging the entire broom sideways.
	pose.position = REST_POSITION + PUSH_OFFSET * reach
	pose.rotation_degrees = Vector3(24.0 - reach * 14.0, 8.0, -5.0 + reach * 3.0)
