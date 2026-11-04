class_name PointerTheme
extends RefCounted

const POINTER_ROOT := "res://assets/models/source/general/pointers/"
const CURSOR_DEFAULT_PATH := POINTER_ROOT + "cursor_default.png"
const CURSOR_CLICKABLE_PATH := POINTER_ROOT + "cursor_menu_clickable.png"
const CURSOR_SIZE := Vector2i(64, 64)
const CURSOR_DEFAULT_HOTSPOT := Vector2(16, 11)
const CURSOR_CLICKABLE_HOTSPOT := Vector2(32, 6)

static var _default_cursor: ImageTexture
static var _clickable_cursor: ImageTexture


static func apply_menu_cursors() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _default_cursor == null:
		_default_cursor = _load_cursor(CURSOR_DEFAULT_PATH)
	if _clickable_cursor == null:
		_clickable_cursor = _load_cursor(CURSOR_CLICKABLE_PATH)
	if _default_cursor:
		Input.set_custom_mouse_cursor(_default_cursor, Input.CURSOR_ARROW, CURSOR_DEFAULT_HOTSPOT)
	if _clickable_cursor:
		Input.set_custom_mouse_cursor(_clickable_cursor, Input.CURSOR_POINTING_HAND, CURSOR_CLICKABLE_HOTSPOT)


static func set_button_cursor(button: BaseButton) -> void:
	button.mouse_default_cursor_shape = (
		Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
	)


static func _load_cursor(path: String) -> ImageTexture:
	var source := load(path) as Texture2D
	if source == null:
		push_error("No se pudo cargar el cursor: %s" % path)
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		push_error("El cursor no contiene una imagen válida: %s" % path)
		return null
	image.resize(CURSOR_SIZE.x, CURSOR_SIZE.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)
