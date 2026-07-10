extends Node

# Global player stats (autoload)
# Access from anywhere via PlayerStats.<variable>

# Basic stats
var lives: int = 3
var health: int = 100
var max_health: int = 100
var coins: int = 0
var experience: int = 0
var level: int = 1

# Progression / unlocks
var unlocked_characters: Array = ["Hailey"]

# Inventory placeholder
var inventory: Dictionary = {}

func add_coins(amount: int) -> void:
	coins += amount

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		lives = max(0, lives - 1)
		respawn()

func heal(amount: int) -> void:
	health = min(max_health, health + amount)

func respawn() -> void:
	health = max_health
	# Future: implement respawn position handling

func reset() -> void:
	lives = 3
	health = max_health
	coins = 0
	experience = 0
	level = 1
	inventory.clear()
