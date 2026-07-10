# Combat component with improved position handling, friendly-team checks, enums, and VFX/SFX hooks
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

# Sound and particle hooks (assign AudioStream / PackedScene in inspector)
@export var hit_sound: AudioStream
@export var death_sound: AudioStream
@export var hit_particles_scene: PackedScene
@export var death_particles_scene: PackedScene
@export var hit_volume_db: float = 0.0
@export var death_volume_db: float = 0.0

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
	if node.has_node("Combat"):
		var c = node.get_node("Combat")
		if c and c is Node:
			var p = c.get_parent()
			if p and p is Node3D:
				return p.global_position
	return Vector3.ZERO

# Utility: find a Combat instance on the target (self, child named "Combat", or parent's Combat)
func _find_combat_on(node: Node) -> Combat:
	if not node:
		return null
	# target is itself a Combat instance
	if node is Combat:
		return node
	# node has method take_damage (some custom implementations)
	if node.has_method("take_damage") and node.get_class() == "Combat":
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

# --- VFX / SFX helpers --------------------------------------------------
func _play_sound_at(pos: Vector3, stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_db = volume_db
	player.transform.origin = pos
	# Add to the current scene root so it survives when the owner is freed
	var root = get_tree().get_current_scene()
	if root:
		root.add_child(player)
	else:
		add_child(player)
	player.play()
	# schedule free after a short delay (approximate)
	player.call_deferred("set_autoplay", false)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(player):
		player.queue_free()

func _spawn_particles_at(pos: Vector3, scene: PackedScene) -> void:
	if not scene:
		return
	var inst = scene.instantiate()
	if inst is Node3D:
		inst.global_position = pos
		var root = get_tree().get_current_scene()
		if root:
			root.add_child(inst)
		else:
			add_child(inst)
		# If particle node has lifetime, schedule free after a short time
		# Try to start emission if CPUParticles3D/GPUParticles3D
		if inst.has_method("emitting"):
			inst.emitting = true
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(inst):
			inst.queue_free()

# --- Damage API ---------------------------------------------------------
func take_damage(amount: int, attacker: Node = null) -> void:
	if is_dead:
		return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	# play hit effects at the character root
	var root_pos = _get_position(get_parent())
	if hit_sound:
		_play_sound_at(root_pos, hit_sound, hit_volume_db)
	if hit_particles_scene:
		_spawn_particles_at(root_pos, hit_particles_scene)
	if current_health <= 0:
		is_dead = true
		died.emit(attacker)
		var xp_reward: int = max(1, int(max_health / 5))
		xp_gained.emit(xp_reward)
		# play death effects
		if death_sound:
			_play_sound_at(root_pos, death_sound, death_volume_db)
		if death_particles_scene:
			_spawn_particles_at(root_pos, death_particles_scene)
		# allow particle/sound to spawn before freeing owner; queue_free shortly
		# free the owner (die behavior) after a tiny delay to ensure effects are instantiated
		await get_tree().create_timer(0.05).timeout
		die()

func die() -> void:
	# Default death: free the owner (or this node)
	# Prefer freeing the owner (the character node) if available
	if get_parent():
		get_parent().queue_free()
	else:
		queue_free()

# --- Attack / Combat ----------------------------------------------------
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
		# optionally play hit SFX at the target
		var tpos = _get_position(target)
		if target_combat.hit_sound:
			_play_sound_at(tpos, target_combat.hit_sound, target_combat.hit_volume_db)
		if target_combat.hit_particles_scene:
			_spawn_particles_at(tpos, target_combat.hit_particles_scene)
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
