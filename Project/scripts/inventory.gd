extends Node
class_name Inventory

# Simple inventory/autoload singleton.
# Stores item counts in a dictionary: items[item_id] = count
# Provides simple add/remove/query and item definitions.

var items: Dictionary = {}

const ITEM_DEFINITIONS: Dictionary = {
	"coin": {"name":"Coin", "description":"Currency used to buy items", "stackable":true},
	"health_potion": {"name":"Health Potion", "description":"Restores 50 HP", "stackable":true}
}

signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

func _ready() -> void:
	# ensure items exists
	if items == null:
		items = {}

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	items[item_id] = items.get(item_id, 0) + amount
	emit_signal("item_added", item_id, amount)
	# If coins are tracked in PlayerStats also increment that for convenience
	if item_id == "coin" and Engine.has_singleton("PlayerStats"):
		var ps = Engine.get_singleton("PlayerStats")
		if ps and ps.has_variable("coins"):
			ps.coins = ps.coins + amount
			if ps.has_signal("stats_changed"):
				ps.stats_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	var have = items.get(item_id, 0)
	if have < amount:
		return false
	items[item_id] = have - amount
	if items[item_id] <= 0:
		items.erase(item_id)
	emit_signal("item_removed", item_id, amount)
	return true

func get_count(item_id: String) -> int:
	return items.get(item_id, 0)

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_count(item_id) >= amount

func clear() -> void:
	items.clear()

func list_items() -> Array:
	var arr: Array = []
	for k in items.keys():
		arr.append({"id":k, "amount": items[k], "meta": ITEM_DEFINITIONS.get(k, {})})
	return arr
