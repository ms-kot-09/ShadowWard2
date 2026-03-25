extends CharacterBody3D

# Movement
@export var walk_speed : float = 3.5
@export var run_speed  : float = 6.5
@export var gravity    : float = 9.8
@export var stamina_max: float = 100.0

# Nodes
@onready var head      : Node3D       = $Head
@onready var camera    : Camera3D     = $Head/Camera3D
@onready var flashlight: SpotLight3D  = $Head/Camera3D/Flashlight
@onready var ray       : RayCast3D    = $Head/Camera3D/Ray
@onready var hud       : CanvasLayer  = $HUD

# State
var stamina      : float = 100.0
var sanity       : float = 100.0
var is_running   : bool  = false
var flashlight_on: bool  = true
var cam_shake    : float = 0.0
var bob_t        : float = 0.0
var is_dead      : bool  = false

# Touch
var joy_id    : int     = -1
var joy_origin: Vector2 = Vector2.ZERO
var joy_pos   : Vector2 = Vector2.ZERO
var look_active: bool   = false

signal sanity_changed(v)
signal died

func _ready() -> void:
	if not GameManager.is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	flashlight.light_energy = 3.0
	flashlight.spot_range   = 18.0
	flashlight.spot_angle   = 28.0
	if hud and hud.has_method("init_player"):
		hud.init_player(self)

func _input(event: InputEvent) -> void:
	if is_dead: return
	if event is InputEventMouseMotion and not GameManager.is_mobile:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			head.rotate_y(-event.relative.x * GameManager.mouse_sensitivity)
			camera.rotate_x(-event.relative.y * GameManager.mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -1.3, 1.3)
	if event is InputEventScreenTouch:   _on_touch(event)
	if event is InputEventScreenDrag:    _on_drag(event)
	if event.is_action_pressed("flashlight"): _toggle_light()
	if event.is_action_pressed("interact"):   _interact()
	if event.is_action_pressed("pause"):      GameManager.toggle_pause()

func _on_touch(e: InputEventScreenTouch) -> void:
	var sw = DisplayServer.window_get_size().x
	if e.pressed:
		if e.position.x < sw * 0.45 and joy_id == -1:
			joy_id = e.index; joy_origin = e.position; joy_pos = e.position
		elif e.position.x >= sw * 0.45:
			look_active = true
	else:
		if e.index == joy_id: joy_id = -1; joy_pos = joy_origin
		else: look_active = false

func _on_drag(e: InputEventScreenDrag) -> void:
	var sw = DisplayServer.window_get_size().x
	if e.index == joy_id:
		joy_pos = e.position
	elif e.position.x >= sw * 0.45:
		head.rotate_y(-e.relative.x * 0.006)
		camera.rotate_x(-e.relative.y * 0.006)
		camera.rotation.x = clamp(camera.rotation.x, -1.3, 1.3)

func _physics_process(delta: float) -> void:
	if is_dead: return
	if not is_on_floor(): velocity.y -= gravity * delta
	_move(delta)
	_bob(delta)
	_shake(delta)
	_sanity(delta)
	_stamina_regen(delta)
	_check_interact()
	move_and_slide()

func _move(delta: float) -> void:
	var dir := Vector2.ZERO
	if GameManager.is_mobile:
		if joy_id != -1:
			var d = (joy_pos - joy_origin).limit_length(55.0) / 55.0
			dir = d
	else:
		dir = Input.get_vector("move_left","move_right","move_forward","move_back")
	is_running = Input.is_action_pressed("run") and stamina > 5 and not GameManager.is_mobile
	var spd = run_speed if is_running else walk_speed
	var move = (head.transform.basis * Vector3(dir.x, 0, dir.y)).normalized()
	velocity.x = move.x * spd
	velocity.z = move.z * spd

func _bob(delta: float) -> void:
	if velocity.length() > 0.5 and is_on_floor():
		bob_t += delta * (14.0 if is_running else 9.0)
		camera.transform.origin.y = sin(bob_t) * (0.05 if is_running else 0.02)
	else:
		camera.transform.origin.y = lerp(camera.transform.origin.y, 0.0, delta * 10)

func _shake(delta: float) -> void:
	if cam_shake > 0:
		cam_shake = max(0, cam_shake - delta * 2)
		camera.rotation.z = randf_range(-1,1) * cam_shake * 0.04

func _sanity(delta: float) -> void:
	if not flashlight_on:
		sanity = max(0, sanity - 3 * delta)
	else:
		sanity = min(100, sanity + 0.8 * delta)
	sanity_changed.emit(sanity)
	if sanity <= 0: _die()

func _stamina_regen(delta: float) -> void:
	if is_running and velocity.length() > 0.5:
		stamina = max(0, stamina - 20 * delta)
	else:
		stamina = min(stamina_max, stamina + 12 * delta)

func _check_interact() -> void:
	if hud == null: return
	if ray.is_colliding():
		var col = ray.get_collider()
		if col and col.has_method("interact"):
			hud.show_interact(col.get("interact_text") if col.get("interact_text") else "Examine")
			return
	hud.hide_interact()

func _interact() -> void:
	if ray.is_colliding():
		var col = ray.get_collider()
		if col and col.has_method("interact"): col.interact(self)

func _toggle_light() -> void:
	flashlight_on = !flashlight_on
	flashlight.visible = flashlight_on

func reduce_sanity(amount: float) -> void:
	sanity = max(0, sanity - amount)
	cam_shake = min(1.0, cam_shake + 0.4)

func restore_sanity(amount: float) -> void:
	sanity = min(100, sanity + amount)

func _die() -> void:
	if is_dead: return
	is_dead = true
	died.emit()
	GameManager.game_over()

func get_joy_data() -> Dictionary:
	return {"active": joy_id != -1, "origin": joy_origin, "pos": joy_pos, "r": 55.0}
