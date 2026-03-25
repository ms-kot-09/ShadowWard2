extends CanvasLayer

var player : Node = null
var _note_open : bool = false

# UI refs (created in _ready procedurally)
var sanity_bar    : ProgressBar
var stamina_bar   : ProgressBar
var interact_lbl  : Label
var objective_lbl : Label
var overlay       : ColorRect
var crosshair     : Control
var note_panel    : Panel
var note_title    : Label
var note_body     : RichTextLabel
var pause_panel   : Panel
var mobile_ui     : Control
var joy_base      : ColorRect
var joy_knob      : ColorRect
var btn_interact  : Button
var btn_light     : Button

func _ready() -> void:
	_build_ui()
	GameManager.objective_updated.connect(_on_objective)
	GameManager.game_paused.connect(_on_pause)

func init_player(p: Node) -> void:
	player = p
	p.sanity_changed.connect(_on_sanity)

func _build_ui() -> void:
	# Sanity bar
	sanity_bar = ProgressBar.new()
	sanity_bar.max_value = 100; sanity_bar.value = 100
	sanity_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sanity_bar.position = Vector2(20, 20); sanity_bar.size = Vector2(200, 18)
	sanity_bar.show_percentage = false
	add_child(sanity_bar)

	var sl = Label.new(); sl.text = "РАССУДОК"
	sl.position = Vector2(20, 6); sl.add_theme_color_override("font_color", Color(0.8,0.3,0.3))
	sl.add_theme_font_size_override("font_size", 12)
	add_child(sl)

	# Stamina bar
	stamina_bar = ProgressBar.new()
	stamina_bar.max_value = 100; stamina_bar.value = 100
	stamina_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stamina_bar.position = Vector2(20, 52); stamina_bar.size = Vector2(200, 12)
	stamina_bar.show_percentage = false; stamina_bar.modulate = Color(0.3,0.6,1)
	add_child(stamina_bar)

	# Crosshair
	crosshair = Control.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	add_child(crosshair)
	var ch = ColorRect.new(); ch.size = Vector2(2,14); ch.position = Vector2(-1,-7)
	ch.color = Color(1,1,1,0.7); crosshair.add_child(ch)
	var ch2 = ColorRect.new(); ch2.size = Vector2(14,2); ch2.position = Vector2(-7,-1)
	ch2.color = Color(1,1,1,0.7); crosshair.add_child(ch2)
	crosshair.visible = not GameManager.is_mobile

	# Interact label
	interact_lbl = Label.new()
	interact_lbl.set_anchors_preset(Control.PRESET_CENTER)
	interact_lbl.position.y = 40
	interact_lbl.add_theme_color_override("font_color", Color(1,0.9,0.6))
	interact_lbl.add_theme_font_size_override("font_size", 20)
	interact_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_lbl.visible = false
	add_child(interact_lbl)

	# Objective label
	objective_lbl = Label.new()
	objective_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	objective_lbl.position = Vector2(-320, 20); objective_lbl.size.x = 300
	objective_lbl.add_theme_color_override("font_color", Color(0.8,0.8,0.8,0.7))
	objective_lbl.add_theme_font_size_override("font_size", 16)
	objective_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(objective_lbl)

	# Sanity overlay (red vignette)
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.3,0,0,0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Note panel
	note_panel = Panel.new()
	note_panel.set_anchors_preset(Control.PRESET_CENTER)
	note_panel.size = Vector2(600, 500)
	note_panel.position = Vector2(-300, -250)
	note_panel.visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08,0.06,0.05,0.97)
	style.border_color = Color(0.5,0.4,0.3); style.border_width_left = 2
	style.border_width_right = 2; style.border_width_top = 2; style.border_width_bottom = 2
	note_panel.add_theme_stylebox_override("panel", style)
	add_child(note_panel)

	note_title = Label.new()
	note_title.position = Vector2(20,16); note_title.size = Vector2(560,36)
	note_title.add_theme_font_size_override("font_size", 22)
	note_title.add_theme_color_override("font_color", Color(0.9,0.7,0.4))
	note_panel.add_child(note_title)

	note_body = RichTextLabel.new()
	note_body.position = Vector2(20,60); note_body.size = Vector2(560,380)
	note_body.add_theme_font_size_override("normal_font_size", 17)
	note_body.add_theme_color_override("default_color", Color(0.85,0.82,0.78))
	note_body.bbcode_enabled = true; note_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_panel.add_child(note_body)

	var close_btn = Button.new()
	close_btn.text = "✕ Закрыть"; close_btn.position = Vector2(460,452)
	close_btn.size = Vector2(120,36)
	close_btn.pressed.connect(hide_note)
	note_panel.add_child(close_btn)

	# Pause panel
	pause_panel = Panel.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.size = Vector2(340,320); pause_panel.position = Vector2(-170,-160)
	pause_panel.visible = false
	var ps = StyleBoxFlat.new(); ps.bg_color = Color(0,0,0,0.88)
	pause_panel.add_theme_stylebox_override("panel",ps)
	add_child(pause_panel)

	var ptitle = Label.new(); ptitle.text = "ПАУЗА"
	ptitle.add_theme_font_size_override("font_size",32); ptitle.position = Vector2(0,24)
	ptitle.size.x = 340; ptitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptitle.add_theme_color_override("font_color",Color(1,0.4,0.4))
	pause_panel.add_child(ptitle)

	var resume = Button.new(); resume.text = "Продолжить"
	resume.position = Vector2(70,100); resume.size = Vector2(200,52)
	resume.pressed.connect(GameManager.toggle_pause)
	pause_panel.add_child(resume)

	var quit_btn = Button.new(); quit_btn.text = "Главное меню"
	quit_btn.position = Vector2(70,170); quit_btn.size = Vector2(200,52)
	quit_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	pause_panel.add_child(quit_btn)

	# Mobile UI
	if GameManager.is_mobile:
		_build_mobile_ui()

func _build_mobile_ui() -> void:
	mobile_ui = Control.new()
	mobile_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	mobile_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mobile_ui)

	# Joystick base
	joy_base = ColorRect.new()
	joy_base.size = Vector2(120,120); joy_base.color = Color(1,1,1,0.12)
	joy_base.position = Vector2(40, 500)
	var jb_style = StyleBoxFlat.new(); jb_style.corner_radius_top_left = 60
	jb_style.corner_radius_top_right = 60; jb_style.corner_radius_bottom_left = 60
	jb_style.corner_radius_bottom_right = 60
	mobile_ui.add_child(joy_base)

	joy_knob = ColorRect.new()
	joy_knob.size = Vector2(48,48); joy_knob.color = Color(1,0.4,0.2,0.7)
	joy_knob.position = joy_base.position + Vector2(36,36)
	mobile_ui.add_child(joy_knob)

	# Interact button
	btn_interact = Button.new()
	btn_interact.text = "E"; btn_interact.position = Vector2(900,540)
	btn_interact.size = Vector2(90,90)
	btn_interact.add_theme_font_size_override("font_size",28)
	btn_interact.pressed.connect(_mobile_interact)
	add_child(btn_interact)

	# Flashlight button
	btn_light = Button.new()
	btn_light.text = "🔦"; btn_light.position = Vector2(800,560)
	btn_light.size = Vector2(70,70)
	btn_light.pressed.connect(_mobile_light)
	add_child(btn_light)

	# Pause button
	var pbtn = Button.new(); pbtn.text = "II"
	pbtn.position = Vector2(1160,20); pbtn.size = Vector2(70,50)
	pbtn.pressed.connect(GameManager.toggle_pause)
	add_child(pbtn)

func _process(_delta: float) -> void:
	if player and GameManager.is_mobile and joy_base:
		var d = player.get_joy_data()
		if d.active:
			var delta_joy = (d.pos - d.origin).limit_length(d.r)
			joy_knob.position = d.origin - joy_base.position + delta_joy + Vector2(36,36)
		else:
			joy_knob.position = Vector2(36,36)
	if player and stamina_bar:
		stamina_bar.value = player.stamina
		stamina_bar.visible = player.stamina < 95

func _on_sanity(v: float) -> void:
	if sanity_bar: sanity_bar.value = v
	if overlay:
		var alpha = (1.0 - v/100.0) * 0.75
		overlay.color = Color(0.25,0,0.05,alpha)

func show_interact(text: String) -> void:
	if interact_lbl:
		interact_lbl.text = "[E] " + text
		interact_lbl.visible = true

func hide_interact() -> void:
	if interact_lbl: interact_lbl.visible = false

func show_note(title: String, body: String) -> void:
	if note_panel:
		note_title.text = title; note_body.text = body
		note_panel.visible = true; _note_open = true
		get_tree().paused = true
		if not GameManager.is_mobile:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_note() -> void:
	if note_panel:
		note_panel.visible = false; _note_open = false
		get_tree().paused = false
		if not GameManager.is_mobile:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_objective(text: String) -> void:
	if objective_lbl:
		objective_lbl.text = "▶ " + text
		var t = create_tween()
		t.tween_property(objective_lbl,"modulate:a",1.0,0.5)
		t.tween_interval(5.0)
		t.tween_property(objective_lbl,"modulate:a",0.3,1.5)

func _on_pause(state: bool) -> void:
	if pause_panel: pause_panel.visible = state

func _mobile_interact() -> void:
	if player: player._interact()

func _mobile_light() -> void:
	if player: player._toggle_light()

func flash_white() -> void:
	var f = ColorRect.new(); f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.color = Color(1,1,1,1); f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	var t = create_tween()
	t.tween_property(f,"modulate:a",0.0,0.5)
	t.tween_callback(f.queue_free)
