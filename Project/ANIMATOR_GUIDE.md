# ANIMATOR_GUIDE.md

This guide describes the animation conventions, import settings, and the AnimationTree state machine template used by HEYLA Kids. Follow this exactly so animations plug into the game's runtime with minimal setup.

1) Naming convention (required)
- Use these exact animation names (lowercase preferred) when exporting from your DCC:
  - idle
  - idle_breathe       (optional) — small breathing/idle variance
  - walk
  - run
  - sprint             (optional)
  - jump               (jump start)
  - fall               (in-air fall)
  - land               (landing)
  - attack_1
  - attack_2
  - attack_heavy
  - combo_1, combo_2   (optional combo variants)
  - dodge
  - block
  - hit (or hurt)
  - knockback
  - death
  - victory
  - interact
  - special_<ability>  (e.g. hailey_heal, amara_dash)

Facial (blendshapes) naming (optional):
  - face_happy
  - face_surprised
  - face_angry
  - face_sad
  - face_laugh
  - face_sleepy

2) Animation sets recommended by role
- Player (per character) — core set (recommended 30+ but minimum set below):
  idle, walk, run, jump, fall, land, attack_1, attack_2, attack_heavy, hit, death, victory, interact, special_<name>
- Enemy (per enemy type):
  idle, patrol (can reuse idle), notice, chase (run), attack_1, hit, stunned, death, special_attack
- NPC (ambient only):
  sit, read, sweep, talk, wave, laugh, clap, sleep, eat, walk
- Boss (cinematic):
  entrance, idle, taunt, heavy_attack, jump_attack, charge, summon, ultimate, stagger, death_cutscene

3) Import pipeline (recommended)
- Preferred formats: .glb / .gltf (keeps animation clips and is easy to manage with Godot 4).
- Export clips: export each animation as a separate named clip (the exporter or DCC should allow naming clips).
- In Godot import options:
  - Import > Animation: enable import of animations
  - Do not bake root if you want code-driven movement (recommended). If using root motion, export the root motion track and set expectation in README.
  - Reimport after naming changes.

4) AnimationTree structure (recommended)
- Create AnimationTree under your model node and set Active = On.
- Set Tree Root to an AnimationNodeStateMachine (call it `StateMachine`).
- Add the following states in the state machine (exact names):
  Idle, Walk, Run, Sprint, Jump, Fall, Land, Attack, Hurt, Death, Victory, Special
- For movement blending, you may use an AnimationNodeBlendSpace1D or 2D named `MoveBlend` with parameter `move_speed`.
- For Attack, use an AnimationNodeBlend or a parameter named `attack_anim` which selects between attack_1/attack_2/attack_heavy.

5) State transitions (recommended)
- Idle <-> Walk/Run (by speed)
- Walk/Run -> Sprint (high speed)
- Any -> Jump when jump starts
- Jump -> Fall when vertical velocity < 0
- Fall -> Land when is_on_floor
- Any -> Hurt on hit
- Any -> Death on death
- Idle/Run -> Attack on attack trigger; Attack returns to Idle/Run after animation finish

6) Script API expectations
- Game scripts will look for AnimationTree at one of these paths on the character node:
  - $AnimationTree
  - $Model/AnimationTree
  If an AnimationTree is found, the runtime uses its state machine playback via:
    var playback = anim_tree.get("parameters/playback")
    playback.travel("Run")

- If an AnimationTree is NOT found, the fallback is AnimationPlayer at either $AnimationPlayer or $Model/AnimationPlayer. The scripts will try to play animations by name (first `lowercase` name, then exact name).

- Script helper calls available (in player/enemy scripts):
  - _play_state(state_name:String)
  - _play_attack(anim_name:String = "attack_1")
  - _play_hurt()
  - _play_death()
  - update animations by calling _update_animation(direction, delta) after movement updates

7) Blendshape / facial animation hooks
- If your mesh has blendshapes (morph targets), name them as above (face_happy, etc.).
- To set a blendshape from script:
  var mesh = $Model/MeshInstance3D
  if mesh and mesh.mesh.get_blend_shape_count() > 0:
    mesh.set("blend_shapes/face_happy", 1.0)
  (Note: exact API may vary with Godot version; animators should test.)

8) Root motion vs code-driven movement
- Recommendation: code-driven movement (CharacterBody3D.move_and_slide()) for precise gameplay control and collision behavior.
- If you want root motion, export a root motion track and inform the engine code; we can add an extract step to apply root deltas to the CharacterBody3D.

9) Export tips for riggers
- Keep animation lengths tight; avoid long idle loops with camera-moving artifacts.
- Use in-place animations for locomotion when possible (easier collision behavior).
- Provide clear naming and a short metadata file if you export multiple variants (example: hailey_v1_metadata.json listing clip names)

10) Testing checklist for animators
- Import .glb into Godot and confirm all clips are present in AnimationPlayer.
- Add AnimationTree and create the state machine with the state names above.
- Play in editor and trigger transitions via script or manually calling playback.travel("Run").
- Confirm Attack animations return to movement state on finish (use AnimationPlayer.animation_finished to debug).

11) Animators FAQ
Q: My attack animation moves the character forward and clips through enemies.
A: Prefer in-place animations (no root motion) for gameplay attacks, or ensure the attack root motion is small and the collision is handled by the Combat component.

Q: How do I add extra emotes?
A: Add them as `special_<name>` and the game will not assume behavior; the designers can trigger them explicitly.

12) Where to place templates and resources
- Place animation tree templates under: `res://Project/scenes/anim_templates/`
- Place exported .glb characters under: `res://Project/assets/models/` and name them `hailey.glb`, `leo.glb`, etc.

---

# AnimationTree skeleton scene
I included a small example scene resource in `res://Project/scenes/anim_templates/anim_tree_template.tscn` that shows the AnimationPlayer and AnimationTree nodes and describes where to assign animations. Use that as your starting point.

Thank you — follow this guide and animators can iterate quickly without touching code repeatedly.
