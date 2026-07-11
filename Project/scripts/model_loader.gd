extends Node3D

@export var model_path: String = "res://Project/assets/models/placeholder.glb"

# Replaces a primitive placeholder in a character scene with an imported GLB scene at runtime.
# Set `model_path` to the GLB you placed in res://Project/assets/models/ (e.g. hailey.glb).

func _ready():
	if ResourceLoader.exists(model_path):
		var packed = ResourceLoader.load(model_path)
		if packed and packed is PackedScene:
			var inst = packed.instantiate()
			# Remove children placeholder meshes (keep nodes marked with "keep_on_replace")
			for child in get_children():
				if child is MeshInstance3D and not child.name.ends_with("_keep"):
					child.queue_free()
			add_child(inst)
			inst.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
			print("[ModelLoader] Instantiated model: %s" % model_path)
		else:
			print("[ModelLoader] Resource exists but is not a PackedScene: %s" % model_path)
	else:
		print("[ModelLoader] Model not found at: %s (place GLB at this path)" % model_path)
