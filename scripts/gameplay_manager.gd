extends Node

signal state_changed

const TRASH_SCENE := preload("res://scenes/gameplay/trash_item.tscn")
const DEFINITIONS: Array[Resource] = [
	preload("res://resources/trash/ticket.tres"),
	preload("res://resources/trash/napkin.tres"),
	preload("res://resources/trash/cup.tres"),
	preload("res://resources/trash/bottle.tres"),
	preload("res://resources/trash/can.tres"),
	preload("res://resources/trash/straw.tres"),
	preload("res://resources/trash/popcorn.tres"),
	preload("res://resources/trash/bucket.tres"),
]
const SPAWN_POSITIONS: Array[Vector3] = [
	Vector3(0.0, 0.02, -10.0), Vector3(0.0, 0.02, -7.8),
	Vector3(0.0, 0.02, -5.8), Vector3(0.0, 0.02, -3.4),
	Vector3(0.0, 0.02, -1.0), Vector3(0.0, 0.02, 1.4),
	Vector3(0.0, 0.02, 3.8), Vector3(0.0, 0.02, 6.2),
	Vector3(-8.7, 0.02, -9.0), Vector3(-8.7, 0.02, -5.8),
	Vector3(-8.7, 0.02, -2.2), Vector3(-8.7, 0.02, 1.4),
	Vector3(-8.7, 0.02, 5.0), Vector3(-8.7, 0.02, 9.0),
	Vector3(8.7, 0.02, -10.0), Vector3(8.7, 0.02, -7.0),
	Vector3(8.7, 0.02, -3.4), Vector3(8.7, 0.02, 0.2),
	Vector3(8.7, 0.02, 4.2), Vector3(8.7, 0.02, 8.0),
]

@export var bag_capacity: float = 10.0

var bag_volume: float = 0.0
var coins: int = 0
var remaining_trash: int = 0
var total_trash: int = 0
var _pending_reward: int = 0

@onready var trash_items: Node3D = $TrashItems
@onready var pickup_audio: AudioStreamPlayer = $PickupAudio
@onready var empty_audio: AudioStreamPlayer = $EmptyAudio


func _ready() -> void:
	pickup_audio.stream = _make_tone(660.0, 0.07)
	empty_audio.stream = _make_tone(220.0, 0.18)
	_spawn_trash()
	state_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		get_tree().reload_current_scene()


func can_collect(definition: Resource) -> bool:
	return definition != null and bag_volume + float(definition.volume) <= bag_capacity + 0.0001


func try_collect(item: Node) -> bool:
	if item == null or not is_instance_valid(item) or item.definition == null:
		return false
	var definition: Resource = item.definition
	if not can_collect(definition):
		return false
	bag_volume += float(definition.volume)
	_pending_reward += int(definition.reward)
	remaining_trash = maxi(0, remaining_trash - 1)
	item.collect()
	if DisplayServer.get_name() != "headless":
		pickup_audio.play()
	state_changed.emit()
	return true


func empty_bag() -> bool:
	if bag_volume <= 0.0:
		return false
	coins += _pending_reward
	bag_volume = 0.0
	_pending_reward = 0
	if DisplayServer.get_name() != "headless":
		empty_audio.play()
	state_changed.emit()
	return true


func get_clean_percent() -> int:
	if total_trash <= 0:
		return 100
	return roundi(float(total_trash - remaining_trash) / float(total_trash) * 100.0)


func _spawn_trash() -> void:
	for index in SPAWN_POSITIONS.size():
		var item := TRASH_SCENE.instantiate()
		item.name = "Trash_%02d_%s" % [index + 1, DEFINITIONS[index % DEFINITIONS.size()].id]
		item.definition = DEFINITIONS[index % DEFINITIONS.size()]
		item.position = SPAWN_POSITIONS[index]
		item.rotation.y = deg_to_rad(float((index * 47) % 360))
		trash_items.add_child(item)
	total_trash = SPAWN_POSITIONS.size()
	remaining_trash = total_trash


func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var sample_count := int(stream.mix_rate * duration)
	var audio_data := PackedByteArray()
	audio_data.resize(sample_count)
	for sample_index in sample_count:
		var time := float(sample_index) / float(stream.mix_rate)
		var envelope := 1.0 - float(sample_index) / float(sample_count)
		var sample := 128.0 + sin(TAU * frequency * time) * 72.0 * envelope
		audio_data[sample_index] = clampi(roundi(sample), 0, 255)
	stream.data = audio_data
	return stream
