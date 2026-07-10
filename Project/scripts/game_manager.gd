extends Node
class_name GameManager

# Small central game manager for scene flow, pause, and saves.
# This script is autoloaded in Project/project.godot as GameManager already.

var selected_character: String = "Hailey"
var is_paused: bool = false

func _ready() -> void:
	# ensure SaveManager exists before using
	pass

func start_game():
	# Load character select or main level
	var scene_path = ProjectSettings.get_setting("application/config/main_scene")
	get_tree().change_scene(scene_path)

func continue_game(slot: int = 1) -> void:
	if Engine.has_singleton("SaveManager"):
		SaveManager.load_game(slot)

func save_game(slot: int = 1) -> void:
	if Engine.has_singleton("SaveManager"):
		SaveManager.save_game(slot)

func load_game(slot: int = 1) -> void:
	if Engine.has_singleton("SaveManager"):
		SaveManager.load_game(slot)

func pause_game():
	if is_paused:
		return
	get_tree().paused = true
	is_paused = true

func resume_game():
	if not is_paused:
		return
	get_tree().paused = false
	is_paused = false

func quit_to_menu():
	# optional: show main menu scene
	get_tree().change_scene("res://scenes/ui/main_menu.tscn")

func quit_game():
	get_tree().quit()
