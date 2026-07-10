extends CharacterBody3D

@export var speed: float = 2.0
@export var chase_range: float = 8.0
@export var attack_range: float = 1.5

var player: Node3D = null
var combat: Node = null  # expects a child node named "Combat" with combat.gd attached
var state: String = "idle"

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	player = players.size() > 0 ? players[0] : null
	if has_node("Combat"):
		combat = $Combat
		# tune combat parameters for this enemy
		if combat.has_method("attack_damage"):
			pass
	if combat:
		combat.attack_damage = 15
		combat.attack_range = attack_range
	add_to_group("enemy")

func _physics_process(delta):
	if not player or (combat and combat.is_dead):
		return
	var distance = global_position.distance_to(player.global_position)
	match state:
		"idle":
			if distance < chase_range:
				state = "chase"
		"chase":
			if distance > chase_range:
				state = "idle"
			else:
				var dir = (player.global_position - global_position).normalized()
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
				move_and_slide()
				if distance < attack_range:
					state = "attack"
		"attack":
			var attacked = false
			if combat:
				attacked = combat.try_attack(player)
			if not attacked or distance > attack_range:
				state = "chase"
