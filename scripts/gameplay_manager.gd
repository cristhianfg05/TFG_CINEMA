class_name GameplayManager
extends Node

signal state_changed
signal notification_requested(message: String)

const SAVE_PATH := "user://cinema_cleaner_save.json"
const SAVE_VERSION := 1
const TRASH_SCENE := preload("res://scenes/gameplay/trash_item.tscn")
const LOST_ITEM_SCENE := preload("res://scenes/gameplay/lost_item.tscn")
const WATCH_DEFINITION := preload("res://resources/lost_items/cheap_watch.tres")
const UPGRADES: Array[Resource] = [
	preload("res://resources/upgrades/quick_hands_1.tres"),
	preload("res://resources/upgrades/reinforced_bag_1.tres"),
]
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
@export var base_bag_capacity: float = 10.0
@export var base_pickup_cooldown: float = 1.0

var bag_volume: float = 0.0
var coins: int = 0
var remaining_trash: int = 0
var total_trash: int = 0
var pickup_cooldown: float = 1.0
var held_lost_items: Array[String] = []
var lost_item_state: String = "available"
var purchased_upgrades: Dictionary = {}
var room_completed: bool = false
var _pending_reward: int = 0
var _pickup_cooldown_remaining: float = 0.0

@onready var trash_items: Node3D = $TrashItems
@onready var lost_items: Node3D = $LostItems
@onready var pickup_audio: AudioStreamPlayer = $PickupAudio
@onready var empty_audio: AudioStreamPlayer = $EmptyAudio


func _ready() -> void:
	pickup_audio.stream = _make_tone(430.0, 0.06)
	empty_audio.stream = _make_tone(170.0, 0.14)
	_load_progress()
	_apply_upgrades()
	_spawn_trash()
	_spawn_lost_item_if_needed()
	state_changed.emit()
	call_deferred("_evaluate_room_completion")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	_pickup_cooldown_remaining = maxf(0.0, _pickup_cooldown_remaining - delta)


func can_collect(definition: Resource) -> bool:
	return definition != null and bag_volume + float(definition.volume) <= bag_capacity + 0.0001


func try_collect(item: Node, bypass_cooldown: bool = false) -> bool:
	if item == null or not is_instance_valid(item) or item.definition == null:
		return false
	if not bypass_cooldown and not can_pick_up_now():
		return false
	var definition: Resource = item.definition
	if not can_collect(definition):
		return false
	bag_volume += float(definition.volume)
	_pending_reward += int(definition.reward)
	remaining_trash = maxi(0, remaining_trash - 1)
	_pickup_cooldown_remaining = pickup_cooldown
	item.collect()
	if DisplayServer.get_name() != "headless":
		pickup_audio.play()
	state_changed.emit()
	_evaluate_room_completion()
	return true


func request_collect(item: Node) -> bool:
	if item == null or not is_instance_valid(item) or item.definition == null:
		return false
	if not can_collect(item.definition):
		notification_requested.emit("La bolsa está llena. Vacíala en el contenedor verde.")
		return false
	if not can_pick_up_now():
		notification_requested.emit(
			"Espera %.1f s para recoger otro objeto." % get_pickup_cooldown_remaining()
		)
		return false
	return try_collect(item)


func can_pick_up_now() -> bool:
	return get_pickup_cooldown_remaining() <= 0.0


func get_pickup_cooldown_remaining() -> float:
	return _pickup_cooldown_remaining


func empty_bag() -> bool:
	if bag_volume <= 0.0:
		return false
	coins += _pending_reward
	bag_volume = 0.0
	_pending_reward = 0
	if DisplayServer.get_name() != "headless":
		empty_audio.play()
	_save_progress()
	state_changed.emit()
	return true


func get_clean_percent() -> int:
	if total_trash <= 0:
		return 100
	return roundi(float(total_trash - remaining_trash) / float(total_trash) * 100.0)


func collect_lost_item(item: Node) -> bool:
	if lost_item_state != "available" or item == null or item.definition == null:
		return false
	held_lost_items.append(String(item.definition.id))
	lost_item_state = "carried"
	item.collect()
	notification_requested.emit("Objeto perdido guardado. Entrégalo en el cajón azul.")
	_save_progress()
	state_changed.emit()
	return true


func destroy_lost_item(item: Node) -> bool:
	if lost_item_state != "available" or item == null or item.definition == null:
		return false
	coins -= int(item.definition.destruction_penalty)
	lost_item_state = "destroyed"
	item.collect()
	notification_requested.emit(
		"Era un objeto perdido: -%d monedas. Los objetos dorados se entregan, no se tiran."
		% int(item.definition.destruction_penalty)
	)
	_save_progress()
	state_changed.emit()
	return true


func deposit_lost_items() -> bool:
	if lost_item_state != "carried" or held_lost_items.is_empty():
		return false
	held_lost_items.clear()
	lost_item_state = "returned"
	coins += int(WATCH_DEFINITION.return_reward)
	notification_requested.emit(
		"Reloj entregado: +%d monedas. Los objetos dorados tienen otro destino."
		% int(WATCH_DEFINITION.return_reward)
	)
	_save_progress()
	state_changed.emit()
	return true


func get_next_upgrade() -> Resource:
	for definition in UPGRADES:
		if not has_upgrade(definition.id):
			return definition
	return null


func has_upgrade(upgrade_id: StringName) -> bool:
	return bool(purchased_upgrades.get(String(upgrade_id), false))


func try_purchase_next_upgrade() -> bool:
	var definition := get_next_upgrade()
	if definition == null:
		notification_requested.emit("Ya tienes todas las mejoras de esta sala.")
		return false
	if coins < int(definition.cost):
		notification_requested.emit(
			"Necesitas %d monedas para %s." % [int(definition.cost), definition.display_name]
		)
		return false
	coins -= int(definition.cost)
	purchased_upgrades[String(definition.id)] = true
	_apply_upgrades()
	notification_requested.emit("Mejora comprada: %s." % definition.display_name)
	_save_progress()
	state_changed.emit()
	_evaluate_room_completion()
	return true


func is_exit_unlocked() -> bool:
	return room_completed or (
		get_clean_percent() >= 95
		and has_upgrade(&"quick_hands_1")
		and has_upgrade(&"reinforced_bag_1")
	)


func get_exit_requirement_text() -> String:
	if is_exit_unlocked():
		return "Salida abierta"
	var requirements: Array[String] = []
	if get_clean_percent() < 95:
		requirements.append("limpieza 95 %")
	if not has_upgrade(&"quick_hands_1") or not has_upgrade(&"reinforced_bag_1"):
		requirements.append("las 2 mejoras")
	return "Salida cerrada: falta %s" % " y ".join(requirements)


func explain_exit_requirements() -> void:
	notification_requested.emit(get_exit_requirement_text())


func get_objective_text() -> String:
	if room_completed:
		return "Sala completada — atraviesa la puerta"
	if get_clean_percent() == 0:
		return "Apunta cerca de la basura y usa clic derecho para recogerla"
	if get_clean_percent() < 95:
		return "Objetivo: limpia al menos el 95 %"
	var next_upgrade := get_next_upgrade()
	if next_upgrade:
		return "Objetivo: compra %s al encargado" % next_upgrade.display_name
	return "Objetivo completado — dirígete a la salida"


func _apply_upgrades() -> void:
	bag_capacity = 20.0 if has_upgrade(&"reinforced_bag_1") else base_bag_capacity
	pickup_cooldown = 0.35 if has_upgrade(&"quick_hands_1") else base_pickup_cooldown


func _evaluate_room_completion() -> void:
	if room_completed or not is_exit_unlocked():
		return
	room_completed = true
	notification_requested.emit("¡Sala completada! La puerta de salida está abierta.")
	_save_progress()
	state_changed.emit()


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


func _spawn_lost_item_if_needed() -> void:
	if lost_item_state != "available":
		return
	var item := LOST_ITEM_SCENE.instantiate()
	item.name = "CheapWatch"
	item.definition = WATCH_DEFINITION
	item.position = Vector3(0.75, 0.03, -0.4)
	lost_items.add_child(item)


func _save_progress() -> void:
	var data := {
		"version": SAVE_VERSION,
		"coins": coins,
		"upgrades": purchased_upgrades.keys(),
		"room_completed": room_completed,
		"lost_item_state": lost_item_state,
		"held_lost_items": held_lost_items,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar el progreso: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		return
	coins = int(parsed.get("coins", 0))
	room_completed = bool(parsed.get("room_completed", false))
	lost_item_state = String(parsed.get("lost_item_state", "available"))
	held_lost_items.clear()
	for item_id in parsed.get("held_lost_items", []):
		held_lost_items.append(String(item_id))
	purchased_upgrades.clear()
	for upgrade_id in parsed.get("upgrades", []):
		purchased_upgrades[String(upgrade_id)] = true


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
		var sample := 128.0 + sin(TAU * frequency * time) * 36.0 * envelope
		audio_data[sample_index] = clampi(roundi(sample), 0, 255)
	stream.data = audio_data
	return stream
