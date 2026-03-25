extends Node3D
## Ward A — Первое крыло психбольницы
## Задача: найти ключ от подвала, прочитать 3 записки, выжить

@onready var player      : CharacterBody3D = $Player
@onready var hud         : CanvasLayer     = $HUD
@onready var ambient     : AudioStreamPlayer3D = $AmbientAudio
@onready var world_env   : WorldEnvironment = $WorldEnvironment
@onready var spawn_timer : Timer           = $SpawnTimer

# Level state
var notes_collected : int = 0
var required_notes  : int = 3
var key_found       : bool = false
var basement_open   : bool = false

func _ready() -> void:
	# Set objective
	GameManager.set_objective("Find a way to the basement")
	
	# Connect player signals
	player.sanity_changed.connect(hud.update_sanity)
	player.died.connect(_on_player_died)
	hud.player = player
	
	# Connect GameManager
	GameManager.note_found.connect(_on_note_found)
	GameManager.item_collected.connect(_on_item_collected)
	
	# Atmospheric setup
	_setup_atmosphere()
	
	# Restore state if loading save
	_restore_state()
	
	# Start ambient horror audio
	ambient.play()
	
	# Random ghost spawning
	spawn_timer.timeout.connect(_spawn_event)
	spawn_timer.start(randf_range(30.0, 90.0))

func _setup_atmosphere() -> void:
	# Dark environment settings
	world_env.environment.ambient_light_color  = Color(0.02, 0.02, 0.05)
	world_env.environment.ambient_light_energy = 0.1
	world_env.environment.fog_enabled          = true
	world_env.environment.fog_density          = 0.015
	world_env.environment.fog_light_color      = Color(0.05, 0.05, 0.1)
	world_env.environment.glow_enabled         = true
	world_env.environment.glow_intensity       = 0.3
	world_env.environment.adjustment_brightness = 0.8
	world_env.environment.adjustment_contrast   = 1.2

func _restore_state() -> void:
	# Hide already-collected items
	for note_id in GameManager.notes_found:
		var node = get_node_or_null("Notes/" + note_id)
		if node: node.queue_free()
	
	for item in GameManager.items_collected:
		var node = get_node_or_null("Items/" + item)
		if node: node.queue_free()
	
	# Unlock doors already opened
	for door_id in GameManager.doors_unlocked:
		var door = get_node_or_null("Doors/" + door_id)
		if door and door.has_method("unlock"):
			door.unlock(true)  # silent unlock

func _on_note_found(note_id: String, _content: String) -> void:
	notes_collected += 1
	if notes_collected >= required_notes:
		GameManager.set_objective("Find the basement key")

func _on_item_collected(item_name: String) -> void:
	if item_name == "basement_key":
		key_found = true
		GameManager.set_objective("Go to the basement door")

func _on_player_died() -> void:
	hud.jumpscare_flash()

# ── Random horror events ───────────────────────────────────────────────
func _spawn_event() -> void:
	var events = ["lights_flicker", "shadow_appear", "sound_event", "door_slam"]
	var event = events[randi() % events.size()]
	
	match event:
		"lights_flicker": _lights_flicker()
		"shadow_appear":  _shadow_appear()
		"sound_event":    _play_random_sound()
		"door_slam":      _door_slam()
	
	# Schedule next event
	spawn_timer.start(randf_range(20.0, 60.0))

func _lights_flicker() -> void:
	var lights = get_tree().get_nodes_in_group("flickerable_lights")
	if lights.is_empty(): return
	var light = lights[randi() % lights.size()]
	
	var t = create_tween()
	for i in range(randi_range(3, 8)):
		t.tween_property(light, "light_energy", 0.0, 0.05)
		t.tween_property(light, "light_energy", light.light_energy, 0.05)

func _shadow_appear() -> void:
	# Flash a shadow figure at the end of a corridor
	var shadow = get_node_or_null("Events/ShadowFigure")
	if shadow:
		shadow.visible = true
		await get_tree().create_timer(0.3).timeout
		shadow.visible = false

func _play_random_sound() -> void:
	var sounds = get_tree().get_nodes_in_group("ambient_sound_points")
	if sounds.is_empty(): return
	var s = sounds[randi() % sounds.size()]
	if s.has_method("play"): s.play()

func _door_slam() -> void:
	var doors = get_tree().get_nodes_in_group("slamable_doors")
	if doors.is_empty(): return
	var d = doors[randi() % doors.size()]
	if d.has_method("slam"): d.slam()

func _process(delta: float) -> void:
	# Check basement door interaction
	var basement_door = get_node_or_null("Doors/BasementDoor")
	if basement_door and key_found and not basement_open:
		if player.global_position.distance_to(basement_door.global_position) < 2.5:
			basement_open = true
			GameManager.unlock_door("basement_door")
			GameManager.complete_level()
