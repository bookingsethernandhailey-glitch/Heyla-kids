extends Node3D
@onready var ui_label = $UI/Label
@onready var orbs = $World/Orbs
var orb_nodes = []

func _ready():
	for child in orbs.get_children():
		orb_nodes.append(child)
	MissionManager.all_collected.connect(_on_all_collected)
	_update_ui()

func _update_ui():
	ui_label.text = "Orbs: " + str(MissionManager.collected) + "/" + str(MissionManager.total)

func _on_all_collected():
	ui_label.text = "🎉 Victory! All orbs collected!"

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var dir = camera.project_ray_normal(event.position)
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, from + dir * 100)
		var result = space.intersect_ray(query)
		if result and result.collider in orb_nodes:
			var orb = result.collider
			if orb.visible:
				orb.visible = false
				MissionManager.collect()
				_update_ui()
