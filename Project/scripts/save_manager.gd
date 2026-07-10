extends Node
class_name SaveManager

const SAVES_DIR := "user://saves/"
const SAVE_FILENAME := "slot_%d.json"

var current_slot: int = 1

func _ready() -> void:
	if not DirAccess.exists(SAVES_DIR):
		DirAccess.make_dir_recursive(SAVES_DIR)

func get_save_path(slot: int) -> String:
	return "%s%s" % [SAVES_DIR, SAVE_FILENAME % slot]

func save_game(slot: int = 1) -> bool:
	var payload := _build_payload()
	payload["meta"]["saved_at"] = OS.get_unix_time()
	payload["meta"]["version"] = 1
	var tmp := get_save_path(slot) + ".tmp"
	var final := get_save_path(slot)
	var json_text := JSON.print(payload)
	var f := FileAccess.open(tmp, FileAccess.ModeFlags.WRITE)
	if not f:
		push_error("SaveManager: cannot open temp file for write: %s" % tmp)
		return false
	f.store_string(json_text)
	f.close()
	if FileAccess.file_exists(final):
		var bak := final + ".bak"
		if FileAccess.file_exists(bak):
			DirAccess.remove_file(bak)
		DirAccess.rename(final, bak)
	DirAccess.rename(tmp, final)
	current_slot = slot
	return true

func load_game(slot: int = 1) -> bool:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		push_error("SaveManager: no save at %s" % path)
		return false
	var f := FileAccess.open(path, FileAccess.ModeFlags.READ)
	if not f:
		push_error("SaveManager: cannot open save %s" % path)
		return false
	var text := f.get_as_text()
	f.close()
	var parsed := JSON.parse_string(text)
	if parsed.error != OK:
		push_error("SaveManager: JSON parse error %d" % parsed.error)
		return false
	return _apply_payload(parsed.result)

func _build_payload() -> Dictionary:
	var payload := {"meta":{}, "player":{}, "inventory":{}, "quests":{}}
	payload.meta.version = 1
	if Engine.has_singleton("PlayerStats"):
		payload.player = PlayerStats.to_dict()
	if Engine.has_singleton("Inventory"):
		payload.inventory = Engine.get_singleton("Inventory").items.duplicate()
	if Engine.has_singleton("QuestManager") and QuestManager.has_method("serialize"):
		payload.quests = QuestManager.serialize()
	elif Engine.has_singleton("QuestManager"):
		payload.quests = QuestManager.quests.duplicate()
	return payload

func _apply_payload(payload: Dictionary) -> bool:
	if not payload:
		return false
	var version := int(payload.get("meta", {}).get("version", 0))
	# Player
	if Engine.has_singleton("PlayerStats") and payload.has("player"):
		PlayerStats.from_dict(payload.player)
	# Inventory
	if Engine.has_singleton("Inventory") and payload.has("inventory"):
		var inv = Engine.get_singleton("Inventory")
		if inv:
			inv.items = payload.inventory.duplicate()
			inv.emit_signal("items_loaded")
	# Quests
	if Engine.has_singleton("QuestManager") and payload.has("quests"):
		if QuestManager.has_method("deserialize"):
			QuestManager.deserialize(payload.quests)
		else:
			QuestManager.quests = payload.quests.duplicate()
	if Engine.has_singleton("PlayerStats"):
		PlayerStats.emit_signal("stats_changed")
	return true
