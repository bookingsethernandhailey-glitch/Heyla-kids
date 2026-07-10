extends Node
class_name QuestManager

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal objective_completed(quest_id: String, objective_index: int)

# quests: dictionary of quest_id -> quest data
# Quest structure:
# { id: String, title: String, description: String, completed: bool,
#   objectives: [ { type: "kill" | "collect", target: String, required: int, progress: int, completed: bool } ] }

var quests: Dictionary = {}

func _ready() -> void:
	# Example starter quests (remove or extend in-game)
	add_quest({
		"id":"quest_slay_goblins",
		"title":"Goblin Menace",
		"description":"Eliminate 5 goblins threatening the village.",
		"completed":false,
		"objectives": [
			{ "type":"kill", "target":"goblin", "required":5, "progress":0, "completed":false }
		]
	})

	add_quest({
		"id":"quest_collect_coins",
		"title":"Coin Collector",
		"description":"Gather 10 coins for the shopkeeper.",
		"completed":false,
		"objectives": [
			{ "type":"collect", "target":"coin", "required":10, "progress":0, "completed":false }
		]
	})

func add_quest(q: Dictionary) -> void:
	if not q.has("id"):
		push_error("Quest must have an id")
		return
	q["completed"] = q.get("completed", false)
	var objectives = q.get("objectives", [])
	for i in range(objectives.size()):
		objectives[i]["progress"] = objectives[i].get("progress", 0)
		objectives[i]["completed"] = objectives[i].get("completed", false)
	q["objectives"] = objectives
	quests[q.id] = q
	emit_signal("quest_updated", q.id)

func get_quest(id: String) -> Dictionary:
	return quests.get(id, null)

func list_quests() -> Array:
	return quests.values()

func on_enemy_killed(enemy_type: String) -> void:
	# called when an enemy dies; increment relevant kill objectives
	for qid in quests.keys():
		var q = quests[qid]
		if q["completed"]:
			continue
		var updated = false
		for i in range(q["objectives"].size()):
			var obj = q["objectives"][i]
			if obj["completed"]:
				continue
			if obj["type"] == "kill" and obj["target"] == enemy_type:
				obj["progress"] += 1
				updated = true
				emit_signal("objective_completed", qid, i)
				if obj["progress"] >= obj["required"]:
					obj["completed"] = true
					emit_signal("objective_completed", qid, i)
		# check quest completion
		if updated:
			var all_done = true
			for obj2 in q["objectives"]:
				if not obj2["completed"]:
					all_done = false
					break
			if all_done:
				q["completed"] = true
				emit_signal("quest_completed", qid)
			else:
				emit_signal("quest_updated", qid)

func on_item_collected(item_id: String, amount: int = 1) -> void:
	# called when a player collects items; increment collect objectives
	for qid in quests.keys():
		var q = quests[qid]
		if q["completed"]:
			continue
		var updated = false
		for i in range(q["objectives"].size()):
			var obj = q["objectives"][i]
			if obj["completed"]:
				continue
			if obj["type"] == "collect" and obj["target"] == item_id:
				obj["progress"] += amount
				updated = true
				emit_signal("objective_completed", qid, i)
				if obj["progress"] >= obj["required"]:
					obj["completed"] = true
					emit_signal("objective_completed", qid, i)
		# check quest completion
		if updated:
			var all_done = true
			for obj2 in q["objectives"]:
				if not obj2["completed"]:
					all_done = false
					break
			if all_done:
				q["completed"] = true
				emit_signal("quest_completed", qid)
			else:
				emit_signal("quest_updated", qid)

# Utility API
func add_progress(quest_id: String, objective_index: int, amount: int = 1) -> void:
	var q = get_quest(quest_id)
	if not q:
		return
	var obj = q["objectives"][objective_index]
	if obj["completed"]:
		return
	obj["progress"] += amount
	emit_signal("objective_completed", quest_id, objective_index)
	if obj["progress"] >= obj["required"]:
		obj["completed"] = true
		# re-evaluate quest
		var all_done = true
		for o in q["objectives"]:
			if not o["completed"]:
				all_done = false
				break
		if all_done:
			q["completed"] = true
			emit_signal("quest_completed", quest_id)
		else:
			emit_signal("quest_updated", quest_id)
