extends CharacterBody3D
class_name Ghost

@export var speed_patrol : float = 1.8
@export var speed_chase  : float = 5.5
@export var detect_range : float = 14.0
@export var attack_range : float = 2.0
@export var sanity_drain : float = 18.0
@export var ghost_type   : int   = 0

@onready var nav   : NavigationAgent3D  = $Nav
@onready var area  : Area3D             = $Area
@onready var mesh  : MeshInstance3D     = $Mesh
@onready var audio : AudioStreamPlayer3D = $Audio

enum S {PATROL, CHASE, ATTACK, VANISH}
var state  : S = S.PATROL
var target : Node3D = null
var timer  : float  = 0.0
var alpha  : float  = 0.25
var t      : float  = 0.0
var patrol_pts : Array = []
var pat_i  : int = 0
const GRAV = 9.8

func _ready() -> void:
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)
	_set_alpha(alpha)
	for ch in get_children():
		if ch is Marker3D: patrol_pts.append(ch)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y -= GRAV * delta
	t += delta; timer -= delta
	_flicker(delta)
	match state:
		S.PATROL: _patrol(delta)
		S.CHASE:  _chase(delta)
		S.ATTACK: _attack(delta)
		S.VANISH: _vanish(delta)
	move_and_slide()

func _flicker(delta: float) -> void:
	var f = sin(t*9.0)*0.04 + sin(t*3.5)*0.02
	var a = alpha + f
	if state == S.CHASE and target:
		var d = global_position.distance_to(target.global_position)
		a = lerp(0.85, 0.15, d/detect_range)
	_set_alpha(clamp(a, 0.0, 1.0))

func _patrol(delta: float) -> void:
	if patrol_pts.is_empty():
		velocity.x = 0; velocity.z = 0; return
	nav.target_position = patrol_pts[pat_i].global_position
	var next = nav.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity.x = dir.x * speed_patrol
	velocity.z = dir.z * speed_patrol
	if global_position.distance_to(patrol_pts[pat_i].global_position) < 1.5:
		pat_i = (pat_i+1) % patrol_pts.size()
		if randf() < 0.25: timer = randf_range(1,3)

func _chase(delta: float) -> void:
	if not target: state = S.PATROL; return
	var dist = global_position.distance_to(target.global_position)
	if dist > detect_range * 1.8: state = S.PATROL; target = null; return
	nav.target_position = target.global_position
	var next = nav.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity.x = dir.x * speed_chase
	velocity.z = dir.z * speed_chase
	look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	if dist < attack_range: state = S.ATTACK; timer = 1.2
	elif dist < detect_range * 0.6 and target.has_method("reduce_sanity"):
		target.reduce_sanity(sanity_drain * delta)

func _attack(delta: float) -> void:
	velocity.x = 0; velocity.z = 0
	if timer <= 0:
		if ghost_type == 2:
			_jumpscare()
		else:
			state = S.CHASE

func _vanish(delta: float) -> void:
	alpha = lerp(alpha, 0.0, delta*2.5)
	if timer <= 0:
		if not patrol_pts.is_empty():
			global_position = patrol_pts[randi()%patrol_pts.size()].global_position
		alpha = 0.25; state = S.PATROL

func _jumpscare() -> void:
	if audio: audio.play()
	if target:
		target.reduce_sanity(45.0)
		if target.has_node("HUD"): target.get_node("HUD").flash_white()
	state = S.VANISH; timer = 4.0

func _set_alpha(a: float) -> void:
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat: mat.albedo_color.a = a

func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"): target = body; state = S.CHASE

func _on_exit(body: Node3D) -> void:
	if body == target and state != S.CHASE: target = null; state = S.PATROL
