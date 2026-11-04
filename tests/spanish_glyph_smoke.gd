extends SceneTree

const HUD_FONT := preload("res://assets/fonts/PalaceHUD-Bold.ttf")
const SPANISH_GLYPHS := "áéíóúÁÉÍÓÚñÑüÜ¿¡"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var pixel_glyphs: Dictionary = ArcadeReelRescue.ArcadeReelScreen.PIXEL_GLYPHS
	for glyph in SPANISH_GLYPHS:
		if not HUD_FONT.has_char(glyph.unicode_at(0)):
			push_error("The main HUD font lacks Spanish glyph: %s" % glyph)
			quit(1)
			return
		var uppercase := glyph.to_upper()
		if not pixel_glyphs.has(uppercase) or pixel_glyphs[uppercase] == pixel_glyphs["?"]:
			push_error("The shared arcade pixel font lacks Spanish glyph: %s" % glyph)
			quit(1)
			return
	print("SPANISH_GLYPH_SMOKE_OK")
	quit(0)
