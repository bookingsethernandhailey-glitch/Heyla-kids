# ==============================================
# COMBAT SYSTEM SCRIPT
# ==============================================
extends Node
class_name Combat

@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 2.0

var current_health: int = 0
var can_attack: bool = true
var is_dead: bool = false

signal health_changed(new_health: int, max_health: int)
signal died
signal xp_gained(amount: int)

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	if is_dead: return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		is_dead = true
		died.emit()
		var xp_reward: int = max_health / 5
		xp_gained.emit(xp_reward)
		die()

func die() -> void:
	queue_free()

func try_attack(target: Node) -> bool:
	if not can_attack or is_dead or not is_instance_valid(target):
		return false
	if target.global_position.distance_to(global_position) > attack_range:
		return false
	can_attack = false
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	return true
