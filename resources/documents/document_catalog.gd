class_name DocumentCatalog
extends RefCounted

const DOCUMENT_DIRECTORY := "res://assets/notes"
const EXPECTED_DOCUMENT_TOTAL := 12


static func load_definitions(directory_path: String = DOCUMENT_DIRECTORY) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_report_error("No se pudo abrir el directorio de documentos '%s' (error %s)." % [directory_path, DirAccess.get_open_error()])
		return definitions

	var file_names := PackedStringArray()
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() == "txt":
			file_names.append(file_name)
	file_names.sort()

	for file_name in file_names:
		var file_path := "%s/%s" % [directory_path.trim_suffix("/"), file_name]
		var definition := _load_definition(file_path, file_name)
		if not definition.is_empty():
			definitions.append(definition)

	if definitions.size() != EXPECTED_DOCUMENT_TOTAL:
		_report_warning(
			"Catálogo de documentos incompleto: se esperaban %d definiciones válidas y se cargaron %d de %d TXT. El total mostrado seguirá siendo %d."
			% [EXPECTED_DOCUMENT_TOTAL, definitions.size(), file_names.size(), EXPECTED_DOCUMENT_TOTAL]
		)
	return definitions


static func _load_definition(file_path: String, file_name: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_report_error("No se pudo leer el documento '%s' (error %s); se omite." % [file_path, FileAccess.get_open_error()])
		return {}

	var source := file.get_as_text()
	# Comparing the codepoint avoids embedding a BOM character in compiled
	# release bytecode. In exported PCKs that literal could become an empty
	# string, making begins_with() true and stripping every document's first
	# real character.
	if not source.is_empty() and source.unicode_at(0) == 0xfeff:
		source = source.substr(1)
	# Normalizar únicamente los finales de línea permite conservar espacios,
	# líneas vacías y párrafos exactamente como están escritos en el TXT.
	source = source.replace("\r\n", "\n").replace("\r", "\n")
	var lines := source.split("\n", true)
	var title := String(lines[0]).strip_edges() if lines.size() >= 1 else ""
	var location := String(lines[1]).strip_edges() if lines.size() >= 2 else ""
	var subtitle := String(lines[2]).strip_edges() if lines.size() >= 3 else ""
	var body := "\n".join(Array(lines).slice(3)) if lines.size() >= 4 else ""
	var missing: Array[String] = []
	if title.is_empty():
		missing.append("título (línea 1)")
	if location.is_empty():
		missing.append("indicación interna de colocación (línea 2)")
	if subtitle.is_empty():
		missing.append("subtítulo visible (línea 3)")
	if body.strip_edges().is_empty():
		missing.append("cuerpo (desde la línea 4)")
	if not missing.is_empty():
		_report_error("Documento inválido '%s': falta %s; se omite sin detener la partida." % [file_path, ", ".join(missing)])
		return {}

	return {
		"id": file_name.get_basename(),
		"title": title,
		"location": location,
		"subtitle": subtitle,
		"body": body,
		"file_path": file_path,
		"found": false,
		"read": false,
	}


static func _report_error(message: String) -> void:
	if OS.is_debug_build():
		push_error(message)


static func _report_warning(message: String) -> void:
	if OS.is_debug_build():
		push_warning(message)
