extends Control

func _on_play_pressed() -> void:
	# Start new game (go to character select or main scene)
	if Engine.has_singleton("GameManager"):
		GameManager.start_game()
	else:
		get_tree().change_scene(ProjectSettings.get_setting("application/config/main_scene"))

func _on_continue_pressed() -> void:
	if Engine.has_singleton("SaveManager"):
		SaveManager.load_game(1)

func _on_options_pressed() -> void:
	get_tree().change_scene("res://scenes/ui/options.tscn")

func _on_credits_pressed() -> void:
	# simple credit popup
	var d = WindowDialog.new()
	d.dialog_text = "Created by the HEYLA Kids team."
	add_child(d)
	d.popup_centered_minsize()

func _on_quit_pressed() -> void:
	get_tree().quit()
