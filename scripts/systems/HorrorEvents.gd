extends Node

var player : Node = null
var event_timer : float = 30.0
var events_done : int = 0

func _ready() -> void:
	await get_tree().create_timer(15.0).timeout
	_schedule()

func init(p: Node) -> void:
	player = p

func _schedule() -> void:
	event_timer = randf_range(20.0, 55.0)

func _process(delta: float) -> void:
	if not player: return
	event_timer -= delta
	if event_timer <= 0:
		_trigger_event()
		_schedule()

func _trigger_event() -> void:
	events_done += 1
	var pool = ["shadow","sound","lights","door"]
	if events_done > 3: pool.append("screamer")
	var ev = pool[randi() % pool.size()]
	match ev:
		"shadow":   _shadow_event()
		"sound":    _sound_event()
		"lights":   _lights_event()
		"door":     _door_event()
		"screamer": _screamer_event()

func _shadow_event() -> void:
	# Create brief shadow figure in player's peripheral vision
	var shadow = MeshInstance3D.new()
	var cm = CapsuleMesh.new(); cm.height = 1.8; cm.radius = 0.25
	shadow.mesh = cm
	var sm = StandardMaterial3D.new()
	sm.albedo_color = Color(0,0,0,0.8)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.set_surface_override_material(0,sm)
	# Place at edge of view
	if player:
		var offset = player.head.global_transform.basis * Vector3(randf_range(-6,-3) if randf()<0.5 else randf_range(3,6), 0, -8)
		shadow.position = player.global_position + offset
	get_tree().current_scene.add_child(shadow)
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(shadow): shadow.queue_free()

func _sound_event() -> void:
	# Will play ambient horror sound at random position
	if player: player.reduce_sanity(3.0)

func _lights_event() -> void:
	var lights = get_tree().get_nodes_in_group("flicker")
	for l in lights:
		if l.has_method("_do_flicker"): l._do_flicker()

func _door_event() -> void:
	if player: player.reduce_sanity(5.0)

func _screamer_event() -> void:
	if player:
		player.reduce_sanity(25.0)
		if player.has_node("HUD"): player.get_node("HUD").flash_white()
