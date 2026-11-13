extends Node2D
## Effects: particle bursts, floating text, screen shake (camera) and hit-stop.
## Other nodes find it with get_tree().get_first_node_in_group("fx").

const FxData = preload("res://scripts/data/fx_data.gd")
const GameData = preload("res://scripts/data/game_data.gd")

var _camera: Camera2D
var _shake := 0.0


func _ready() -> void:
	add_to_group("fx")
	z_index = 5
	_camera = Camera2D.new()
	_camera.position = Vector2(GameData.SCREEN_WIDTH * 0.5, 360)
	add_child(_camera)
	_camera.make_current()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - FxData.SHAKE_DECAY * delta, 0.0)
		_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## The game nearly freezes for a moment (makes a kill feel strong).
func hit_stop() -> void:
	if FxData.HIT_STOP_TIME <= 0.0:
		return
	Engine.time_scale = FxData.HIT_STOP_SCALE
	var timer := get_tree().create_timer(FxData.HIT_STOP_TIME, true, false, true)
	timer.timeout.connect(Engine.set_time_scale.bind(1.0))


## One-shot burst of pixel squares. `preset` is a dictionary from fx_data.gd.
func burst(pos: Vector2, preset: Dictionary, direction: Vector2 = Vector2.ZERO) -> void:
	var amount: int = preset["amount"]
	if amount <= 0:
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = preset["lifetime"]
	p.direction = direction if direction != Vector2.ZERO else preset["direction"]
	p.spread = preset["spread"]
	p.initial_velocity_min = preset["speed_min"]
	p.initial_velocity_max = preset["speed_max"]
	p.gravity = preset["gravity"]
	p.damping_min = preset["damping"]
	p.damping_max = preset["damping"]
	p.scale_amount_min = preset["size_min"]
	p.scale_amount_max = preset["size_max"]
	p.color_ramp = _fade(preset["color"])
	if preset.has("rect"):
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = preset["rect"]
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Continuous trail; add it as a child of a moving node (used for gold stones).
static func make_trail(preset: Dictionary) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = preset["amount"]
	p.lifetime = preset["lifetime"]
	p.local_coords = false
	p.spread = 180.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 10.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = preset["size_min"]
	p.scale_amount_max = preset["size_max"]
	p.color_ramp = _fade(preset["color"])
	p.z_index = -1
	return p


## Text that rises and fades (e.g. "+5" or "-8").
func float_text(pos: Vector2, text: String, color: Color) -> void:
	var holder := Node2D.new()
	holder.position = pos
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FxData.FLOAT_TEXT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.07))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(80, 30)
	label.position = Vector2(-40, -15)
	holder.add_child(label)
	add_child(holder)
	var t := holder.create_tween().set_parallel(true)
	t.tween_property(holder, "position:y", pos.y - FxData.FLOAT_TEXT_RISE, FxData.FLOAT_TEXT_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(holder, "modulate:a", 0.0, FxData.FLOAT_TEXT_TIME * 0.5).set_delay(FxData.FLOAT_TEXT_TIME * 0.5)
	t.chain().tween_callback(holder.queue_free)


static func _fade(color: Color) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([color, color, Color(color, 0.0)])
	return g
