extends Node

@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 2.0

var current_health: int
var can_attack: bool = true
var is_dead: bool = false

signal health_changed(new_health, max_health)
signal died

func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int):
	if is_dead: return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		is_dead = true
		died.emit()
		die()

func die():
	# Override in child for death animation, drop loot, etc.
	queue_free()

func try_attack(target: Node) -> bool:
	if not can_attack or is_dead: return false
	if target == null:
		return false
	var owner_pos = owner.global_position if owner and owner.has_method("global_position") else get_parent().global_position
	var target_pos = target.global_position if target and target.has_method("global_position") else Vector3.ZERO
	if owner_pos.distance_to(target_pos) > attack_range:
		return false
	can_attack = false
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	# cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	return true
