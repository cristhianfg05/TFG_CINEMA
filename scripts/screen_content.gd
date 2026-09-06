extends Node3D


func _ready() -> void:
	add_to_group("screen_content")
	var image := _make_placeholder_image()
	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.emission_enabled = true
	material.emission_texture = texture
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 0.65

	var display := MeshInstance3D.new()
	display.name = "ProvisionalFilmImage"
	var quad := QuadMesh.new()
	quad.size = Vector2(11.7, 4.1)
	display.mesh = quad
	display.material_override = material
	add_child(display)


func _make_placeholder_image() -> Image:
	var width := 128
	var height := 72
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var blend := float(y) / float(height - 1)
		var sky := Color("261d46").lerp(Color("d36b52"), blend)
		for x in width:
			image.set_pixel(x, y, sky)

	var sun_center := Vector2(91, 25)
	for y in height:
		for x in width:
			if Vector2(x, y).distance_to(sun_center) < 10.0:
				image.set_pixel(x, y, Color("ffd77d"))

	for x in width:
		var building_height := 7 + ((x * 17) % 22)
		for y in range(height - building_height, height):
			image.set_pixel(x, y, Color("171824"))
	return image
