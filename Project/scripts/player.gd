extends CharacterBody3D
@export var character_id: String = "Hailey"

# Character stats (expandable)
const CHARACTERS = {
	"Hailey": { "speed": 6.0, "jump": 4.5, "color": Color(1,0.71,0.76), "special": "none" },
	"Ethern": { "speed": 5.5, "jump": 5.5, "color": Color(0.4,0.2,0.6), "special": "high_jump" },
	"Amara":  { "speed": 7.0, "jump": 4.0, "color": Color(0.2,0.8,0.4), "special": "sprint" },
	"Leo":    { "speed": 5.0, "jump": 4.5, "color": Color(1.0,1.0,0.9), "special": "night_vision" },
	"Zara":   { "speed": 6.0, "jump": 4.5, "color": Color(0.9,0.6,0.3), "special": "dash" }
}
var speed: float
var jump_force: float
var special: String

@onready var camera: Camera3D = $Camera3D
@onready var mesh_instance: MeshInstance3D = $Body
@onready var world_env: WorldEnvironment = get_node_or_null("/root/Main/World/WorldEnvironment")
# Animation nodes: prefer AnimationTree (state machine) but fall back to AnimationPlayer
@onready var anim_tree: AnimationTree = (has_node("AnimationTree") ? $AnimationTree : (has_node("Model/AnimationTree") ? $Model/AnimationTree : null))
var anim_state: AnimationNodeStateMachinePlayback = null
@onready var anim_player: AnimationPlayer = (has_node("AnimationPlayer") ? $AnimationPlayer : (has_node("Model/AnimationPlayer") ? $Model/AnimationPlayer : null))

@onready var combat: Node = $Combat

var _last_health: int = -1

func _ready():
	apply_character(character_id)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	# init animation tree if present
	if anim_tree:
		anim_tree.active = true
		anim_state = anim_tree.get("parameters/playback")
	# connect combat signals (if combat exists)
	if combat:
		if combat.has_signal("health_changed"):
			combat.health_changed.connect(_on_combat_health_changed)
		if combat.has_signal("died"):
			combat.died.connect(_on_combat_died)
		# initialize last health
		if combat.has_method("current_health"):
			_last_health = combat.current_health

func apply_character(id: String):
	var data = CHARACTERS.get(id)
	if data:
		speed = data.speed
		jump_force = data.jump
		special = data.special
		mesh_instance.material_override = StandardMaterial3D.new()
		mesh_instance.material_override.albedo_color = data.color
		# Future: load different model/animation set based on id

func _physics_process(delta: float):
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		# play jump animation
		_play_jump()
	if special == "night_vision" and Input.is_action_just_pressed("skill_cat_vision"):
		if world_env and world_env.environment:
			world_env.environment.glow_enabled = !world_env.environment.glow_enabled
			print("🌙 Night Vision toggled")
	if special == "dash" and Input.is_action_just_pressed("dash"):
		var dash_velocity = transform.basis.z * -10
		velocity.x = dash_velocity.x
		velocity.z = dash_velocity.z
		print("💨 Dash!")
	# gravity
	velocity.y -= 9.8 * delta
	# move
	move_and_slide()
	# update animations based on movement state
	_update_animation(direction, delta)

func _update_animation(direction: Vector3, delta: float) -> void:
	# determine speed on XZ plane
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	# airborne handling
	if not is_on_floor():
		if velocity.y > 0.1:
			_play_state("Jump")
		else:
			_play_state("Fall")
		return
	# grounded movement
	if planar_speed > (speed * 0.66):
		_play_state("Run")
	elif planar_speed > 0.1:
		_play_state("Walk")
	else:
		_play_state("Idle")

# Animation helpers: prefer AnimationTree (state machine) else AnimationPlayer
func _play_state(state_name: String) -> void:
	if anim_state:
		if anim_state.get_current_node() != state_name:
			anim_state.travel(state_name)
	elif anim_player:
		if not anim_player.is_playing() or anim_player.get_current_animation() != state_name.lower():
			# AnimationPlayer usually uses lowercase names in our import convention
			if anim_player.has_animation(state_name.lower()):
				anim_player.play(state_name.lower())
			# fallback to exact name
			elif anim_player.has_animation(state_name):
				anim_player.play(state_name)

func _play_attack(anim_name: String = "attack_1") -> void:
	if anim_state:
		# if Attack state uses a parameter to pick animation, set it (optional)
		if anim_tree.has_parameter("attack_anim"):
			anim_tree.set("parameters/attack_anim", anim_name)
		anim_state.travel("Attack")
	elif anim_player:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		elif anim_player.has_animation("attack"):
			anim_player.play("attack")
	else:
		# fallback procedural lunge
		_play_attack_anim()

func _play_jump() -> void:
	_play_state("Jump")

func _play_hurt() -> void:
	if anim_state:
		anim_state.travel("Hurt")
	elif anim_player:
		if anim_player.has_animation("hit"):
			anim_player.play("hit")
		elif anim_player.has_animation("hurt"):
			anim_player.play("hurt")
	else:
		_play_hurt_anim()

func _play_death() -> void:
	if anim_state:
		anim_state.travel("Death")
	elif anim_player:
		if anim_player.has_animation("death"):
			anim_player.play("death")
	else:
		# fallback: default death behavior
		pass

func _on_combat_health_changed(current, max_val):
	# play hurt animation if health decreased
	if _last_health == -1:
		_last_health = current
	elif current < _last_health:
		_play_hurt()
		_last_health = current
	# forward to PlayerStats if present
	if Engine.has_singleton("PlayerStats"):
		PlayerStats.health = current
		PlayerStats.max_health = max_val
		PlayerStats.stats_changed.emit()

func _on_combat_died(attacker = null):
	print("Player died (combat)")
	_play_death()
	# TODO: respawn or game-over flow

func _input(event: InputEvent):
	# attack handling
	if Input.is_action_just_pressed("attack"):
		var enemies = get_tree().get_nodes_in_group("enemy")
		var nearest = null
		var min_dist = 1e18
		for e in enemies:
			if not e: continue
			var target_pos = null
			if e is Node3D:
				target_pos = e.global_position
			elif e.get_parent() and e.get_parent() is Node3D:
				target_pos = e.get_parent().global_position
			if target_pos == null:
				continue
			var d = global_position.distance_to(target_pos)
			if d < min_dist:
				min_dist = d
				nearest = e
		if nearest and combat:
			var attacked = false
			if combat.has_method("try_attack"):
				attacked = combat.try_attack(nearest)
			if attacked:
				_play_attack()

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation.x = clamp(camera.rotation.x, -0.8, 0.8)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

# --- Simple procedural animations (fallbacks) ---
func _play_attack_anim() -> void:
	if not mesh_instance:
		return
	var original_transform = mesh_instance.transform
	# quick forward lunge in local -z
	mesh_instance.translate_object_local(Vector3(0, 0, -0.35))
	await get_tree().create_timer(0.08).timeout
	mesh_instance.transform = original_transform

func _play_hurt_anim() -> void:
	if not mesh_instance:
		return
	var mat: StandardMaterial3D = mesh_instance.material_override if mesh_instance.material_override else null
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh_instance.material_override = mat
	var orig_col = mat.albedo_color
	mat.albedo_color = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.15).timeout
	# only restore if still using same material
	if mesh_instance and mesh_instance.material_override == mat:
		mat.albedo_color = orig_col
