extends StaticBody3D

const IDLE_ANIMATION := &"Manager_HeadIdle"

@export var humanoid_bone_map: BoneMap


func _ready() -> void:
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_error("Manager rig has no AnimationPlayer")
		return
	var player := players[0] as AnimationPlayer
	if not player.has_animation(IDLE_ANIMATION):
		push_error("Manager head idle is missing")
		return
	player.get_animation(IDLE_ANIMATION).loop_mode = Animation.LOOP_LINEAR
	player.play(IDLE_ANIMATION)
	player.advance(0.0)
