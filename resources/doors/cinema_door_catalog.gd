class_name CinemaDoorCatalog
extends RefCounted

const ROLLER_SHUTTER_SCENE := preload("res://scenes/gameplay/roller_shutter_door.tscn")

# Seven accesses share this scene. Only Room 1 has architecture in the project
# today; future rooms instantiate the same component when their holes exist.
const ACCESS_IDS: Array[StringName] = [
	&"room_01",
	&"room_02",
	&"manager_office",
	&"left_corridor_vestibule",
	&"room_03",
	&"room_04",
	&"final_room",
]


static func instantiate_for(access_id: StringName, narrow: bool = false) -> RollerShutterDoor:
	if access_id not in ACCESS_IDS:
		push_error("Unknown cinema access: %s" % access_id)
		return null
	var door := ROLLER_SHUTTER_SCENE.instantiate() as RollerShutterDoor
	door.variant = RollerShutterDoor.DoorVariant.NARROW if narrow else RollerShutterDoor.DoorVariant.WIDE
	door.name = "RollerDoor_%s" % String(access_id).to_pascal_case()
	door.set_meta("cinema_access_id", access_id)
	return door
