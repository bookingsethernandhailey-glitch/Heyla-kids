extends Node3D
const CHARACTER_NAMES = ["Hailey","Ethern","Amara","Leo","Zara"]
var selected_idx = 0
var character_nodes = []

func _ready():
	spawn_characters()
	select_character(0)

func spawn_characters():
	var offset = -2.0
	for i in range(CHARACTER_NAMES.size()):
		var id = CHARACTER_NAMES[i]
		var pos = Vector3(offset + i * 1.2, 0.5, 0)
		# pedestal
		var pedestal = MeshInstance3D.new()
		pedestal.mesh = BoxMesh.new()
		pedestal.mesh.size = Vector3(0.8,0.1,0.8)
		pedestal.material_override = StandardMaterial3D.new()
		pedestal.material_override.albedo_color = Color(0.4,0.4,0.4)
		pedestal.position = pos - Vector3(0,0.4,0)
		add_child(pedestal)
		# character body (sphere placeholder)
		var body = MeshInstance3D.new()
		body.mesh = SphereMesh.new()
		body.mesh.radius = 0.3
		body.mesh.height = 0.6
		body.material_override = StandardMaterial3D.new()
		body.material_override.albedo_color = get_color_for_character(id)
		body.position = pos
		add_child(body)
		character_nodes.append(body)
		# name label
		var label = Label3D.new()
		label.text = id
		label.position = pos + Vector3(0,-0.6,0)
		label.font_size = 14
		add_child(label)

func get_color_for_character(id: String) -> Color:
	match id:
		"Hailey": return Color(1,0.71,0.76)
		"Ethern": return Color(0.4,0.2,0.6)
		"Amara": return Color(0.2,0.8,0.4)
		"Leo": return Color(1.0,1.0,0.9)
		"Zara": return Color(0.9,0.6,0.3)
	return Color.WHITE

func select_character(idx: int):
	selected_idx = idx
	for i in range(character_nodes.size()):
		var mat = character_nodes[i].material_override
		if i == idx:
			mat.emission_enabled = true
			mat.emission_color = Color(1,0.8,0)
		else:
			mat.emission_enabled = false
	var gm = get_node("/root/GameManager")
	if gm:
		gm.selected_character = CHARACTER_NAMES[idx]

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var dir = camera.project_ray_normal(event.position)
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, from + dir * 100)
		var result = space.intersect_ray(query)
		if result and result.collider in character_nodes:
			var idx = character_nodes.find(result.collider)
			if idx != -1:
				select_character(idx)
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		var idx = -1
		match key:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
			KEY_5: idx = 4
		if idx != -1 and idx < CHARACTER_NAMES.size():
			select_character(idx)
		if key == KEY_ENTER:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
