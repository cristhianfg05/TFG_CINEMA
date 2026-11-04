extends SceneTree

# One-time conversion of the approved generated sources into tiny arcade sprites.
# The full-resolution PNGs remain in art_source for future adjustments.
const SOURCE := "res://art_source/arcade_last_usher_survivor/"
const DESTINATION := "res://assets/pipeline/arcade_last_usher_survivor/"


func _initialize() -> void:
	for item in [{"name": "usher", "size": 24}, {"name": "shadow", "size": 22}, {"name": "patroller", "size": 22}, {"name": "sprinter", "size": 22}, {"name": "boss", "size": 44}]:
		var image := Image.load_from_file(SOURCE + String(item.name) + "_source.png")
		if image.is_empty():
			push_error("Missing arcade sprite source: " + String(item.name))
			quit(1)
			return
		image.resize(int(item.size), int(item.size), Image.INTERPOLATE_LANCZOS)
		var error := image.save_png(DESTINATION + String(item.name) + ".png")
		if error != OK:
			push_error("Could not save arcade sprite: " + String(item.name))
			quit(1)
			return
		print("ARCADE_SPRITE_BUILT ", item.name, " ", image.get_size())
	quit(0)
