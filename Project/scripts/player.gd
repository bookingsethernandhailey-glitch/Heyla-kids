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
@onready var world_env: WorldEnvironment = get_node("/root/Main/World/WorldEnvironment")
@onready var anim_player: AnimationPlayer = $AnimationPlayer  # placeholder for future animations
@onready var combat: Node = $Combat

func _ready():
	apply_character(character_id)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	# connect combat signals (if combat exists)
	if combat:
		if combat.has_signal("health_changed"):
			combat.health_changed.connect(_on_combat_health_changed)
		if combat.has_signal("died"):
			combat.died.connect(_on_combat_died)

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
		# Future: play jump animation
	if special == "night_vision" and Input.is_action_just_pressed("skill_cat_vision"):
		if world_env and world_env.environment:
			world_env.environment.glow_enabled = !world_env.environment.glow_enabled
			print("🌙 Night Vision toggled")
	if special == "dash" and Input.is_action_just_pressed("dash"):
		var dash_velocity = transform.basis.z * -10
		velocity.x = dash_velocity.x
		velocity.z = dash_velocity.z
		print("💨 Dash!")
	velocity.y -= 9.8 * delta
	move_and_slide()
	# Future: update animation states based on velocity

func _on_combat_health_changed(current, max_val):
	# forward to PlayerStats if present
	if Engine.has_singleton("PlayerStats"):
		PlayerStats.health = current
		PlayerStats.max_health = max_val
		PlayerStats.stats_changed.emit()

func _on_combat_died():
	print("Player died (combat)")
	# TODO: respawn or game-over flow

func _input(event: InputEvent):
	# attack handling
	if Input.is_action_just_pressed("attack"):
		var enemies = get_tree().get_nodes_in_group("enemy")
		var nearest = null
		var min_dist = 1e18
		for e in enemies:
			if not e: continue
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
		if nearest and combat:
			combat.try_attack(nearest)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation.x = clamp(camera.rotation.x, -0.8, 0.8)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
