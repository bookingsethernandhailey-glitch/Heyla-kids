extends Control

func _on_master_volume_changed(value: float) -> void:
	# set master bus volume if available
	var idx = -1
	if AudioServer.has_bus("Master"):
		idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, value)

func _on_back_pressed() -> void:
	get_tree().change_scene("res://scenes/ui/main_menu.tscn")
