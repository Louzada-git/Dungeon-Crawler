extends RefCounted
class_name DataFile
## Reads the game's JSON data (data/*.json and the like). A missing or broken
## file is reported with the parser's line and message, instead of leaving an
## empty catalog behind in silence.

## The file as a Dictionary. `key`, when given, must hold a Dictionary inside
## it. `optional` files may be missing without a report. {} when it cannot be read.
static func read(path: String, key: String = "", optional: bool = false) -> Dictionary:
	if not FileAccess.file_exists(path):
		if not optional:
			push_error("Arquivo de dados não encontrado: " + path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("JSON inválido em %s, linha %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var data = json.data
	if not data is Dictionary:
		push_error("Formato inesperado em %s: o arquivo não é um objeto" % path)
		return {}
	if key != "" and not data.get(key) is Dictionary:
		push_error("Formato inesperado em %s: falta \"%s\"" % [path, key])
		return {}
	return data
