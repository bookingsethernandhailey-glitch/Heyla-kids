UI & Export README

What I added in feature/ui-polish branch
- Main Menu (res://Project/scenes/ui/main_menu.tscn)
- HUD (res://Project/scenes/ui/hud.tscn)
- Options (res://Project/scenes/ui/options.tscn)
- UI scripts under res://Project/scripts/ui/
- Theme resource at res://Project/assets/ui/theme.tres
- SaveManager already exists and is used by UI to Save/Load
- Export presets placeholder: res://Project/export_presets.cfg

How to test locally
1. Open the project in Godot 4.x and switch to branch `feature/ui-polish`.
2. Open res://Project/scenes/ui/main_menu.tscn and press Play to run the menu.
3. From the menu, press Play to go to the configured main scene (character select by default).
4. To see the HUD, open a scene that includes the HUD.tscn CanvasLayer or add it to your main scene.

Notes & next steps
- I included a reference to res://Project/assets/fonts/Nunito-Regular.ttf; add a TTF there or update the theme resource to a font you prefer.
- Export presets are placeholders — open the Export dialog in Godot to create proper platform exports.
- I will continue polishing visuals, transitions, and add Inventory/Quest UI if you want more in this branch.
