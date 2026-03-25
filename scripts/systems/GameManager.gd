extends Node

var is_mobile : bool = false
var is_paused : bool = false
var current_level : int = 1
var notes_found : Array = []
var items_collected : Array = []
var player_sanity : float = 100.0
var best_time : float = 0.0

# Settings
var master_volume : float = 1.0
var sfx_volume : float = 1.0
var music_volume : float = 0.6
var mouse_sensitivity : float = 0.002
var graphics_quality : int = 1

const SAVE_PATH = "user://save.dat"

signal note_found(id, content)
signal item_collected(name)
signal game_paused(state)
signal objective_updated(text)
signal game_over_signal

func _ready() -> void:
	is_mobile = DisplayServer.is_touchscreen_available() or OS.get_name() in ["Android","iOS"]
	load_settings()

func save_settings() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_var({
		"notes": notes_found, "items": items_collected,
		"master": master_volume, "sfx": sfx_volume,
		"music": music_volume, "sens": mouse_sensitivity,
		"gfx": graphics_quality, "best": best_time
	})
	f.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = f.get_var(); f.close()
	if not d: return
	notes_found = d.get("notes", [])
	items_collected = d.get("items", [])
	master_volume = d.get("master", 1.0)
	sfx_volume = d.get("sfx", 1.0)
	music_volume = d.get("music", 0.6)
	mouse_sensitivity = d.get("sens", 0.002)
	graphics_quality = d.get("gfx", 1)
	best_time = d.get("best", 0.0)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func reset_game() -> void:
	notes_found.clear(); items_collected.clear()
	player_sanity = 100.0

func set_objective(text: String) -> void:
	objective_updated.emit(text)

func find_note(id: String, content: String) -> void:
	if id not in notes_found:
		notes_found.append(id)
		note_found.emit(id, content)
		save_settings()

func collect_item(item: String) -> void:
	if item not in items_collected:
		items_collected.append(item)
		item_collected.emit(item)
		save_settings()

func has_item(item: String) -> bool:
	return item in items_collected

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)
	if not is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED)

func game_over() -> void:
	game_over_signal.emit()
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func load_level(id: int) -> void:
	current_level = id
	var map = {1: "res://scenes/levels/Ward_A.tscn"}
	if id in map:
		get_tree().change_scene_to_file(map[id])

func apply_audio() -> void:
	for bus in ["Master","SFX","Music"]:
		var idx = AudioServer.get_bus_index(bus)
		if idx >= 0:
			var vol = master_volume if bus == "Master" else (sfx_volume if bus == "SFX" else music_volume)
			AudioServer.set_bus_volume_db(idx, linear_to_db(vol))
