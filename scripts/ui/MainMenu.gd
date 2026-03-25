extends Control

func _ready() -> void:
	_build()
	if not GameManager.is_mobile:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build() -> void:
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03,0.02,0.04)
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "SHADOW WARD"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.85,0.2,0.2))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 120
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub = Label.new()
	sub.text = "Психологический хоррор"
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.5,0.5,0.55))
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.position.y = 200
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Buttons
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-140,40)
	vbox.size = Vector2(280,240)
	vbox.add_theme_constant_override("separation",16)
	add_child(vbox)

	_add_btn(vbox, "▶  НОВАЯ ИГРА", _new_game)
	if GameManager.has_save():
		_add_btn(vbox, "⟳  ПРОДОЛЖИТЬ", _continue)
	_add_btn(vbox, "⚙  НАСТРОЙКИ", _settings)
	if not GameManager.is_mobile:
		_add_btn(vbox, "✕  ВЫХОД", _quit)

	# Version
	var ver = Label.new()
	ver.text = "v1.0.0  |  Godot 4.2"
	ver.add_theme_font_size_override("font_size",13)
	ver.add_theme_color_override("font_color",Color(0.3,0.3,0.35))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-180,-40)
	add_child(ver)

	# Animate
	modulate.a = 0
	var t = create_tween()
	t.tween_property(self,"modulate:a",1.0,1.5)

func _add_btn(parent: Control, text: String, cb: Callable) -> void:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280,52)
	b.add_theme_font_size_override("font_size",20)
	b.pressed.connect(cb)
	parent.add_child(b)

func _new_game() -> void:
	GameManager.reset_game()
	_fade_to("res://scenes/levels/Ward_A.tscn")

func _continue() -> void:
	GameManager.load_settings()
	_fade_to("res://scenes/levels/Ward_A.tscn")

func _fade_to(path: String) -> void:
	var t = create_tween()
	t.tween_property(self,"modulate:a",0.0,1.0)
	t.tween_callback(func(): get_tree().change_scene_to_file(path))

func _settings() -> void:
	var s = _make_settings_overlay()
	add_child(s)

func _make_settings_overlay() -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(460,480); panel.position = Vector2(-230,-240)

	var close = Button.new(); close.text = "✕ Назад"
	close.position = Vector2(330,420); close.size = Vector2(110,42)
	close.pressed.connect(func(): panel.queue_free())
	panel.add_child(close)

	var title = Label.new(); title.text = "НАСТРОЙКИ"
	title.position = Vector2(0,16); title.size.x = 460
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",26)
	panel.add_child(title)

	var y = 70.0
	_slider_row(panel, "Громкость", GameManager.master_volume, y, func(v): GameManager.master_volume=v; GameManager.apply_audio())
	y += 70
	_slider_row(panel, "Музыка", GameManager.music_volume, y, func(v): GameManager.music_volume=v; GameManager.apply_audio())
	y += 70
	_slider_row(panel, "Звуки", GameManager.sfx_volume, y, func(v): GameManager.sfx_volume=v; GameManager.apply_audio())
	y += 70
	_slider_row(panel, "Чувствительность", GameManager.mouse_sensitivity/0.006, y, func(v): GameManager.mouse_sensitivity=v*0.006)

	return panel

func _slider_row(parent: Control, text: String, val: float, y: float, cb: Callable) -> void:
	var lbl = Label.new(); lbl.text = text
	lbl.position = Vector2(24,y+8); lbl.add_theme_font_size_override("font_size",18)
	parent.add_child(lbl)
	var sl = HSlider.new()
	sl.min_value = 0; sl.max_value = 1; sl.step = 0.05; sl.value = val
	sl.position = Vector2(200,y+10); sl.size = Vector2(220,24)
	sl.value_changed.connect(cb)
	parent.add_child(sl)

func _quit() -> void:
	GameManager.save_settings()
	get_tree().quit()
