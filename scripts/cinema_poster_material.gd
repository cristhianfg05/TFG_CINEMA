class_name CinemaPosterMaterial
extends RefCounted

const AGED_POSTER_SHADER := preload("res://shaders/cinema_aged_poster.gdshader")


static func create_for_room(room_number: int) -> ShaderMaterial:
	var source_path := "res://assets/movies/room_%d/Movie_Cartel.jpeg" % room_number
	var source := load(source_path) as Texture2D
	if source == null:
		push_error("Missing movie poster: %s" % source_path)
		return null
	var material := ShaderMaterial.new()
	material.resource_name = "Room%02dAgedPoster" % room_number
	material.shader = AGED_POSTER_SHADER
	material.set_shader_parameter("poster_texture", source)
	return material
