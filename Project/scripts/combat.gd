# Combat component with improved position handling, friendly-team checks, and enums
extends Node
class_name Combat

# Teams to prevent friendly fire or for AI use
enum Team { NEUTRAL, PLAYER, ENEMY, NPC }
# Damage types (expandable)
enum DamageType { PHYSICAL, MAGIC, TRUE }

@export var team: int = Team.NEUTRAL
@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5
@export var attack_range: float = 2.0

var current_health: int = 0
var can_attack: bool = true
var is_dead: bool = false

signal health_changed(new_health: int, max_health: int)
signal died(attacker: Node)
signal xp_gained(amount: int)

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

# Utility: get a world position for a node (tries Node3D then falls back)
func _get_position(node: Node) -> Vector3:
	if node == null:
		# fallback to parent (usually the character node) if available
		if get_parent() and get_parent() is Node3D:
			return (get_parent() as Node3D).global_position
		return Vector3.ZERO
	if node is Node3D:
		return (node as Node3D).global_position
	# try to find a Node3D child/owner
	if node.has_node("."):
		# unlikely, but safe fallback
		return Vector3.ZERO
	return Vector3.ZERO

# Utility: find a Combat instance on the target (self, child named "Combat", or parent's Combat)
func _find_combat_on(node: Node) -> Combat:
	if not node:
		return null
	# target is itself a Combat instance
	if node is Combat:
		return node
	# node has method take_damage (some custom implementations)
	if node.has_method("take_damage"):
		# can't be sure, but it might be the combat implementation
		return node
	# try child named "Combat"
	if node.has_node("Combat"):
		var c = node.get_node("Combat")
		if c and c is Combat:
			return c
	# try parent (for cases where Combat is sibling)
	if node.get_parent() and node.get_parent().has_node("Combat"):
		var c2 = node.get_parent().get_node("Combat")
		if c2 and c2 is Combat:
			return c2
	return null

# Utility: determine the team of a node (checks Combat.team or node.team)
func _get_team(node: Node) -> int:
	if not node:
		return Team.NEUTRAL
	if node is Combat:
		return (node as Combat).team
	# check for child Combat
	var c = _find_combat_on(node)
	if c:
		return c.team
	# direct property fallback
	if node.has_variable("team"):
		return node.team
	return Team.NEUTRAL

# Main damage receiver
func take_damage(amount: int, attacker: Node = null) -> void:
	if is_dead:
		return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		is_dead = true
		died.emit(attacker)
		var xp_reward: int = max(1, int(max_health / 5))
		xp_gained.emit(xp_reward)
		die()

func die() -> void:
	# Default death: free the owner (or this node)
	# Prefer freeing the owner (the character node) if available
	if get_parent():
		get_parent().queue_free()
	else:
		queue_free()

# Try to attack a target. Returns true when an attack was performed (hit or applied).
# damage_type is available for future logic (resistances, modifiers)
func try_attack(target: Node, damage_type: int = DamageType.PHYSICAL) -> bool:
	if not can_attack or is_dead:
		return false
	if not is_instance_valid(target):
		return false
	# Friendly fire check
	var my_team = team
	var target_team = _get_team(target)
	if my_team != Team.NEUTRAL and target_team == my_team:
		# don't attack same team
		return false
	# position check (robust against Combat node being a child)
	var origin: Vector3 = _get_position(get_parent())
	var target_pos: Vector3 = _get_position(target)
	if origin.distance_to(target_pos) > attack_range:
		return false
	# perform attack
	can_attack = false
	# Prefer to call take_damage on a Combat component if present
	var target_combat: Combat = _find_combat_on(target)
	if target_combat and target_combat.has_method("take_damage"):
		target_combat.take_damage(attack_damage, get_parent())
	elif target.has_method("take_damage"):
		# fallback: call directly on the node
		target.take_damage(attack_damage)
	else:
		# last resort: if this is the player and PlayerStats exists, apply to global stats
		if Engine.has_singleton("PlayerStats"):
			var ps = Engine.get_singleton("PlayerStats")
			if ps and ps.has_method("take_damage"):
				ps.take_damage(attack_damage)
			elif ps and ps.has_variable("health"):
				ps.health = max(0, ps.health - attack_damage)
				ps.stats_changed.emit()
	# cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	return true
