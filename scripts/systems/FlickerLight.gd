extends OmniLight3D

var base_energy : float = 1.8
var t : float = 0.0
var flicker_chance : float = 0.005

func _ready() -> void:
	base_energy = light_energy
	t = randf() * 100.0

func _process(delta: float) -> void:
	t += delta
	# Normal subtle flicker
	light_energy = base_energy + sin(t * 7.3) * 0.06 + sin(t * 13.7) * 0.03
	# Random hard flicker
	if randf() < flicker_chance:
		_do_flicker()

func _do_flicker() -> void:
	var tween = create_tween()
	var flickers = randi_range(2,6)
	for i in flickers:
		tween.tween_property(self,"light_energy",0.0,0.04)
		tween.tween_property(self,"light_energy",base_energy,0.04)
