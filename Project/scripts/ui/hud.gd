extends CanvasLayer

@onready var health_bar: TextureProgress = $HealthBar
@onready var xp_bar: TextureProgress = $XPBar
@onready var coins_label: Label = $Coins

func _ready() -> void:
	_update_from_stats()
	if Engine.has_singleton("PlayerStats"):
		PlayerStats.connect("stats_changed", Callable(self, "_update_from_stats"))

func _update_from_stats() -> void:
	if Engine.has_singleton("PlayerStats"):
		var ps = Engine.get_singleton("PlayerStats")
		health_bar.max_value = ps.max_health
		health_bar.value = ps.health
		# XP progress: compute threshold
		var next = ps.level > 0 ? int(100 * pow(1.25, ps.level - 1)) : 100
		xp_bar.max_value = next
		xp_bar.value = ps.experience
		coins_label.text = "Coins: %d" % ps.coins
