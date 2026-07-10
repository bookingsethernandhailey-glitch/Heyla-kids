extends CharacterBody3D
class_name Enemy

@export var speed: float = 2.0
@export var chase_range: float = 8.0
@export var attack_range: float = 1.5

var player: Node3D = null
@onready var combat: Node = has_node("Combat") ? $Combat : null
@onready var agent: NavigationAgent3D = has_node("NavigationAgent3D") ? $NavigationAgent3D : null
var state: String = "idle"

# Animation support: prefer AnimationTree (state machine) with fallback to AnimationPlayer
@onready var anim_tree: AnimationTree = (has_node("AnimationTree") ? $AnimationTree : (has_node("Model/AnimationTree") ? $Model/AnimationTree : null))
var anim_state: AnimationNodeStateMachinePlayback = null
@onready var anim_player: AnimationPlayer = (has_node("AnimationPlayer") ? $AnimationPlayer : (has_node("Model/AnimationPlayer") ? $Model/AnimationPlayer : null))

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	player = players.size() > 0 ? players[0] : null
	if combat:
		combat.attack_damage = 15
		combat.attack_range = attack_range
	if not agent:
		push_warning("Enemy: NavigationAgent3D child not found — will use direct movement fallback.")
	else:
		# tune agent defaults (can be changed per-instance in inspector)
		agent.radius = 0.5
		agent.max_speed = speed
		agent.target_desired_distance = 0.1
	add_to_group("enemy")

	# init animations
	if anim_tree:
		anim_tree.active = true
		anim_state = anim_tree.get("parameters/playback")

func _physics_process(delta: float) -> void:
	if not player or (combat and combat.is_dead):
		return
	var distance: float = global_position.distance_to(player.global_position)

	match state:
		"idle":
			if distance < chase_range:
				state = "chase"
				if agent:
					agent.set_target_position(player.global_position)
			_play_state("Idle")

		"chase":
			if distance > chase_range:
				state = "idle"
			else:
				# Use NavigationAgent3D when available for pathfinding & avoidance
				if agent:
					# continuously update the target so the agent follows a moving player
					agent.set_target_position(player.global_position)

					# request next path position
					var next_pos: Vector3 = agent.get_next_path_position()
					if next_pos == Vector3.ZERO:
						_move_direct_toward(player.global_position, delta)
					else:
						_move_direct_toward(next_pos, delta)
				else:
					# no agent — simple direct chase
					_move_direct_toward(player.global_position, delta)

				_play_state("Run")

				if distance < attack_range:
					state = "attack"

		"attack":
			var attacked: bool = false
			if combat:
				attacked = combat.try_attack(player)
				_play_attack()
			if not attacked or distance > attack_range:
				state = "chase"

# helper: move toward a world position (keeps movement on XZ plane)
func _move_direct_toward(target_pos: Vector3, delta: float) -> void:
	var dir = target_pos - global_position
	dir.y = 0
	if dir.length() == 0:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 10)
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

# --- Animation helpers (mirror Player behaviour) -------------------------
func _play_state(state_name: String) -> void:
	if anim_state:
		if anim_state.get_current_node() != state_name:
			anim_state.travel(state_name)
	elif anim_player:
		if anim_player.has_animation(state_name.lower()):
			anim_player.play(state_name.lower())
		elif anim_player.has_animation(state_name):
			anim_player.play(state_name)

func _play_attack(anim_name: String = "attack_1") -> void:
	if anim_state:
		if anim_tree.has_parameter("attack_anim"):
			anim_tree.set("parameters/attack_anim", anim_name)
		anim_state.travel("Attack")
	elif anim_player:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		elif anim_player.has_animation("attack"):
			anim_player.play("attack")

func _play_hurt() -> void:
	if anim_state:
		anim_state.travel("Hurt")
	elif anim_player:
		if anim_player.has_animation("hit"):
			anim_player.play("hit")
		elif anim_player.has_animation("hurt"):
			anim_player.play("hurt")

func _play_death() -> void:
	if anim_state:
		anim_state.travel("Death")
	elif anim_player:
		if anim_player.has_animation("death"):
			anim_player.play("death")
