## Procedurally builds the hospital ward geometry at runtime
## No external 3D assets needed!
extends Node3D
class_name LevelBuilder

# Materials
var mat_wall  : StandardMaterial3D
var mat_floor : StandardMaterial3D
var mat_ceil  : StandardMaterial3D
var mat_door  : StandardMaterial3D
var mat_window: StandardMaterial3D

# Room layout: [x, z, width, depth, type]
var rooms := [
	[0,   0,   8,  6,  "corridor"],
	[0,   6,  12, 10,  "ward"],
	[0,  16,   8,  6,  "corridor"],
	[12,  4,   8,  8,  "office"],
	[-12, 4,   8,  8,  "bathroom"],
	[0,  22,  14, 12,  "main_hall"],
]

func _ready() -> void:
	_setup_materials()
	_build_level()
	_place_props()
	_add_atmosphere()

func _setup_materials() -> void:
	mat_wall = StandardMaterial3D.new()
	mat_wall.albedo_color = Color(0.75, 0.72, 0.68)
	mat_wall.roughness = 0.9; mat_wall.metallic = 0.0

	mat_floor = StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.3, 0.28, 0.25)
	mat_floor.roughness = 0.85

	mat_ceil = StandardMaterial3D.new()
	mat_ceil.albedo_color = Color(0.68, 0.66, 0.62)
	mat_ceil.roughness = 0.95

	mat_door = StandardMaterial3D.new()
	mat_door.albedo_color = Color(0.35, 0.28, 0.22)
	mat_door.roughness = 0.7

	mat_window = StandardMaterial3D.new()
	mat_window.albedo_color = Color(0.3, 0.4, 0.5, 0.35)
	mat_window.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_window.roughness = 0.05; mat_window.metallic = 0.4

func _build_level() -> void:
	for room in rooms:
		_make_room(room[0], room[1], room[2], room[3], room[4])

func _make_room(rx: float, rz: float, rw: float, rd: float, type: String) -> void:
	var h = 3.2
	var hw = rw*0.5; var hd = rd*0.5

	# Floor
	_add_box(rx, -0.1, rz, rw, 0.2, rd, mat_floor)
	# Ceiling
	_add_box(rx, h+0.1, rz, rw, 0.2, rd, mat_ceil)
	# Walls
	_add_box(rx, h*0.5, rz-hd, rw, h, 0.2, mat_wall)   # front
	_add_box(rx, h*0.5, rz+hd, rw, h, 0.2, mat_wall)   # back
	_add_box(rx-hw, h*0.5, rz, 0.2, h, rd, mat_wall)   # left
	_add_box(rx+hw, h*0.5, rz, 0.2, h, rd, mat_wall)   # right

	# Type-specific props
	match type:
		"ward":
			_add_beds(rx, rz, rw, rd)
		"office":
			_add_desk(rx, rz)
		"corridor":
			_add_corridor_details(rx, rz, rw, rd)
		"main_hall":
			_add_hall_details(rx, rz)

func _add_box(x: float, y: float, z: float, w: float, h: float, d: float, mat: Material) -> void:
	var mesh_inst = MeshInstance3D.new()
	var bm = BoxMesh.new(); bm.size = Vector3(w, h, d)
	mesh_inst.mesh = bm
	mesh_inst.position = Vector3(x, y, z)
	mesh_inst.set_surface_override_material(0, mat)
	add_child(mesh_inst)

	# Static collision
	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(w, h, d)
	body.add_child(shape)
	body.position = Vector3(x, y, z)
	add_child(body)

func _add_beds(rx: float, rz: float, rw: float, rd: float) -> void:
	var bed_mat = StandardMaterial3D.new()
	bed_mat.albedo_color = Color(0.82, 0.80, 0.78)

	var positions = [
		Vector3(rx-2, 0.4, rz-2), Vector3(rx+2, 0.4, rz-2),
		Vector3(rx-2, 0.4, rz+2), Vector3(rx+2, 0.4, rz+2),
	]
	for pos in positions:
		# Bed frame
		var f = MeshInstance3D.new(); var fm = BoxMesh.new()
		fm.size = Vector3(1.0, 0.8, 2.2); f.mesh = fm
		f.position = pos; f.set_surface_override_material(0, bed_mat)
		add_child(f)
		# Pillow
		var p = MeshInstance3D.new(); var pm = BoxMesh.new()
		pm.size = Vector3(0.7, 0.12, 0.5); p.mesh = pm
		p.position = pos + Vector3(0, 0.46, -0.8)
		var pm2 = StandardMaterial3D.new(); pm2.albedo_color = Color(0.9,0.88,0.85)
		p.set_surface_override_material(0, pm2)
		add_child(p)

func _add_desk(rx: float, rz: float) -> void:
	var dm = StandardMaterial3D.new(); dm.albedo_color = Color(0.4,0.32,0.22)
	var desk = MeshInstance3D.new(); var dsk = BoxMesh.new()
	dsk.size = Vector3(2.0,0.08,1.0); desk.mesh = dsk
	desk.position = Vector3(rx, 0.8, rz); desk.set_surface_override_material(0,dm)
	add_child(desk)
	# Chair
	var cm = StandardMaterial3D.new(); cm.albedo_color = Color(0.2,0.18,0.15)
	var chair = MeshInstance3D.new(); var chm = BoxMesh.new()
	chm.size = Vector3(0.55,0.06,0.55); chair.mesh = chm
	chair.position = Vector3(rx, 0.48, rz+0.9); chair.set_surface_override_material(0,cm)
	add_child(chair)
	# Paper on desk
	var paper = MeshInstance3D.new(); var papm = BoxMesh.new()
	papm.size = Vector3(0.3,0.01,0.22); paper.mesh = papm
	var papm2 = StandardMaterial3D.new(); papm2.albedo_color = Color(0.92,0.90,0.85)
	paper.set_surface_override_material(0, papm2)
	paper.position = Vector3(rx+0.3, 0.85, rz-0.1)
	add_child(paper)

func _add_corridor_details(rx: float, rz: float, rw: float, rd: float) -> void:
	# Wall sconce lights
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.9,0.85,0.7)
	lm.emission_enabled = true; lm.emission = Color(1.0,0.9,0.6)*1.5
	var sconce = MeshInstance3D.new(); var sm = CylinderMesh.new()
	sm.top_radius = 0.06; sm.bottom_radius = 0.1; sm.height = 0.2
	sconce.mesh = sm; sconce.position = Vector3(rx-rw*0.4, 2.6, rz)
	sconce.set_surface_override_material(0, lm)
	add_child(sconce)

func _add_hall_details(rx: float, rz: float) -> void:
	# Reception desk
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.5,0.42,0.35)
	var reception = MeshInstance3D.new(); var rcm = BoxMesh.new()
	rcm.size = Vector3(4.0, 1.1, 1.2); reception.mesh = rcm
	reception.position = Vector3(rx, 0.55, rz-3); reception.set_surface_override_material(0,rm)
	add_child(reception)

func _place_props() -> void:
	# Flickering lights throughout
	var light_positions = [
		Vector3(0, 3.0, 3), Vector3(0, 3.0, 11), Vector3(0, 3.0, 19),
		Vector3(8, 3.0, 8), Vector3(-8, 3.0, 8), Vector3(0, 3.0, 28),
	]
	for lp in light_positions:
		var omni = OmniLight3D.new()
		omni.position = lp
		omni.light_color = Color(0.9, 0.85, 0.7)
		omni.light_energy = 1.8; omni.omni_range = 10.0
		omni.shadow_enabled = true
		omni.set_script(load("res://scripts/systems/FlickerLight.gd"))
		add_child(omni)

func _add_atmosphere() -> void:
	# World environment
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0,0,0)
	env.ambient_light_color = Color(0.04,0.04,0.08)
	env.ambient_light_energy = 0.15
	env.fog_enabled = true
	env.fog_density = 0.018
	env.fog_light_color = Color(0.06,0.05,0.1)
	env.glow_enabled = true
	env.glow_bloom = 0.15; env.glow_intensity = 0.4
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.85
	env.adjustment_contrast = 1.25
	env.adjustment_saturation = 0.7
	we.environment = env
	add_child(we)
