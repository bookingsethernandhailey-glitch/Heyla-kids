extends Node

# Global player stats (autoload)
# Access from anywhere via PlayerStats.<variable>

# Signals
signal stats_changed
signal level_up(new_level: int)

# Basic stats
var lives: int = 3
var health: int = 100
var max_health: int = 100
var coins: int = 0
var experience: int = 0
var level: int = 1

# Progression / unlocks
var unlocked_characters: Array = ["Hailey"]

# Inventory placeholder (kept for backward compatibility)
var inventory: Dictionary = {}

# Leveling config
const XP_PER_LEVEL_BASE: int = 100
const XP_GROWTH: float = 1.25

func _ready() -> void:
	# ensure consistent state
	health = clamp(health, 0, max_health)

# ---- Gameplay helpers --------------------------------------------------
func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("stats_changed")

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	emit_signal("stats_changed")

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		lives = max(0, lives - 1)
		respawn()
	emit_signal("stats_changed")

func respawn() -> void:
	health = max_health
	# Future: implement respawn position handling
	emit_signal("stats_changed")

func reset() -> void:
	lives = 3
	health = max_health
	coins = 0
	experience = 0
	level = 1
	inventory.clear()
	emit_signal("stats_changed")

# ---- Progression -------------------------------------------------------
func _xp_threshold_for_level(lvl: int) -> int:
	# exponential growth: base * (growth)^(lvl-1)
	return int(XP_PER_LEVEL_BASE * pow(XP_GROWTH, max(0, lvl - 1)))

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	# level up while we have enough XP
	while experience >= _xp_threshold_for_level(level):
		experience -= _xp_threshold_for_level(level)
		level += 1
		# increase max health slightly per level
		max_health += 10
		health = max_health
		emit_signal("level_up", level)
	# Notify listeners after XP change / leveling
	emit_signal("stats_changed")

# ---- Serialization (save/load) ----------------------------------------
func to_dict() -> Dictionary:
	return {
		"lives": lives,
		"health": health,
		"max_health": max_health,
		"coins": coins,
		"experience": experience,
		"level": level,
		"unlocked_characters": unlocked_characters.duplicate(),
		"inventory": inventory.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	if not data:
		return
	lives = int(data.get("lives", lives))
	health = int(data.get("health", health))
	max_health = int(data.get("max_health", max_health))
	coins = int(data.get("coins", coins))
	experience = int(data.get("experience", experience))
	level = int(data.get("level", level))
	unlocked_characters = data.get("unlocked_characters", unlocked_characters)
	inventory = data.get("inventory", inventory)
	emit_signal("stats_changed")
