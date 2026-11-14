extends Area2D
## The boss on Wall 5: the enemy flagship on the sea.
## It sails in, then roams left/right and fires volleys of cannonballs from its gun ports.
## Every volley is announced: the ship glows and red marks appear for every ball first.
## Volley patterns: a "sweep" (balls land one after another, stepping sideways)
## or a "cluster" (balls land close together: one block can bounce them all).
## Below 2/3 and 1/3 HP it gets angrier (more balls, faster sailing, smoke and fire).

signal died(enemy: Node)
signal hp_changed(hp: int, max_hp: int)
signal phase_changed(phase: int)

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const StoneScript = preload("res://scripts/stone.gd")
const FxScript = preload("res://scripts/fx.gd")

var index := 0
var data: Dictionary = {}
var hp := 1
var max_hp := 1
var dead := false

var _stones_parent: Node
var _markers_parent: Node
var _sprite: Sprite2D
var _smoke: CPUParticles2D
var _fire: CPUParticles2D
var _phase := 0
var _dir := -1.0
var _entering := true
var _time := 0.0
var _state := "idle"          # idle -> windup -> firing -> idle
var _timer := 0.0
var _shots: Array = []        # [{port, target, marker}] for the current volley
var _flash: Tween
var _rock: Tween
var _draw_scale := Vector2.ONE
var _explosions_left := 0


func setup(stones_parent: Node, markers_parent: Node) -> void:
	_stones_parent = stones_parent
	_markers_parent = markers_parent


func _ready() -> void:
	data = EnemyData.BOSS.duplicate()
	max_hp = data["hp"]
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var rect := RectangleShape2D.new()
	rect.size = data["hitbox"]
	var cs := CollisionShape2D.new()
	cs.shape = rect
	cs.position = Vector2(0, 10)
	add_child(cs)

	_smoke = _make_emitter(FxData.SHIP_SMOKE)
	_fire = _make_emitter(FxData.SHIP_FIRE)
	_sprite = ArtData.make_sprite("ship")
	add_child(_sprite)
	var image_size: Vector2 = data["image_size"]
	_draw_scale = ArtData.size_of("ship") / image_size
	_set_facing(-1.0)

	position = Vector2(GameData.SCREEN_WIDTH + 220.0, data["y"])
	var enter := create_tween()
	enter.tween_property(self, "position:x", 820.0, data["enter_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter.tween_callback(func() -> void: _entering = false)
	_timer = float(data["enter_time"]) + float(data["first_shot_delay"])


func _process(delta: float) -> void:
	_time += delta
	_sprite.rotation = sin(_time * 1.6) * 0.03           # rocking on the waves
	_sprite.position.y = sin(_time * 1.1) * 2.0
	if dead:
		_dying(delta)
		return
	if not _entering and _state == "idle":     # it stops sailing while it aims and fires
		var speed: float = _phase_info()["sail_speed"]
		position.x += _dir * speed * delta
		if position.x < data["roam_left"]:
			position.x = data["roam_left"]
			_set_facing(1.0)
		elif position.x > data["roam_right"]:
			position.x = data["roam_right"]
			_set_facing(-1.0)
	_timer -= delta
	if _timer > 0.0:
		return
	match _state:
		"idle":
			_start_volley()
		"windup":
			_state = "firing"
			_timer = 0.0
		"firing":
			_fire_next()


# ---------------------------------------------------------------- attacks

func _start_volley() -> void:
	var count: int = _phase_info()["volley"]
	var cluster := count > 1 and randf() < 0.4
	var margin := EnemyData.TARGET_EDGE_MARGIN + 30.0
	var lo := GameData.FIELD_LEFT + margin
	var hi := GameData.FIELD_RIGHT - margin
	var step: float = EnemyData.BOSS_SWEEP_STEP
	if cluster:
		step = EnemyData.BOSS_CLUSTER_STEP
	var span := step * (count - 1)
	var first := randf_range(lo, hi - span)
	if randf() < 0.5:                                   # sweep left-to-right or right-to-left
		first = first + span
		step = -step
	var ports: Array = data["ports"]
	var start_port := randi() % ports.size()
	_shots.clear()
	for i in range(count):
		var port_index := (start_port + i) % ports.size()
		var target := Vector2(first + step * i, GameData.WALL_TOP + 10.0)
		_shots.append({"port": port_index, "target": target, "marker": _make_marker(port_index, target)})
	# the ship glows: "here it comes"
	if _flash:
		_flash.kill()
	_sprite.modulate = Color(1.5, 1.15, 0.9)
	_flash = create_tween()
	_flash.tween_property(_sprite, "modulate", Color.WHITE, data["windup"])
	var fx := _fx()
	if fx:
		for shot in _shots:
			fx.burst(_port_position(shot["port"]), FxData.PORT_GLOW)
	_state = "windup"
	_timer = data["windup"]


func _fire_next() -> void:
	if _shots.is_empty():
		_state = "idle"
		_timer = _phase_info()["interval"]
		return
	var shot: Dictionary = _shots.pop_front()
	var start := _port_position(shot["port"])
	var target: Vector2 = shot["target"]
	var ball := StoneScript.new()
	ball.art = data["ball_art"]
	var speed: float = data["ball_speed"]
	ball.setup(start, (target - start).normalized() * speed, data["ball_size"], data["wall_damage"], data["return_damage"])
	ball.marker = shot["marker"]
	_stones_parent.add_child(ball)
	GameState.audio.play("cannon")
	var fx := _fx()
	if fx:
		fx.burst(start, FxData.MUZZLE_FLASH)
		fx.burst(start, FxData.CANNON_SMOKE)
		fx.shake(FxData.SHAKE_CANNON)
	_kick(0.04)
	_timer = data["volley_gap"]


func _make_marker(port_index: int, target: Vector2) -> Node2D:
	var start := _port_position(port_index)
	var t := (GameData.CATCH_Y - start.y) / (target.y - start.y)
	var stone_size: float = data["ball_size"]
	var mark_scale := clampf(stone_size / EnemyData.MARKER_BASE_STONE, EnemyData.MARKER_SCALE_MIN, EnemyData.MARKER_SCALE_MAX)
	var marker := ArtData.make_sprite("marker", ArtData.size_of("marker") * mark_scale)
	marker.position = Vector2(lerpf(start.x, target.x, t), GameData.MARKER_Y)
	marker.modulate.a = 0.0
	_markers_parent.add_child(marker)
	marker.create_tween().tween_property(marker, "modulate:a", 1.0, 0.3)
	var base := marker.scale
	var pulse := marker.create_tween().set_loops()
	pulse.tween_property(marker, "scale", base * FxData.MARKER_PULSE, FxData.MARKER_PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(marker, "scale", base, FxData.MARKER_PULSE_TIME).set_trans(Tween.TRANS_SINE)
	return marker


func _port_position(port_index: int) -> Vector2:
	var ports: Array = data["ports"]
	var image_size: Vector2 = data["image_size"]
	var p: Vector2 = ports[port_index]
	if _sprite.flip_h:
		p.x = image_size.x - p.x
	return global_position + _sprite.position + (p - image_size * 0.5) * _draw_scale


# ---------------------------------------------------------------- getting hit

func take_damage(amount: int) -> void:
	if dead:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	GameState.audio.play("ship_hit")
	_sprite.self_modulate = Color(3, 3, 3)
	create_tween().tween_property(_sprite, "self_modulate", Color.WHITE, 0.15)
	_kick(0.08)
	var fx := _fx()
	if fx:
		fx.burst(global_position + Vector2(randf_range(-80, 80), 20), FxData.WOOD_CHIPS)
	var ratio := float(hp) / float(max_hp)
	var phases: Array = data["phases"]
	var new_phase := _phase
	for i in range(phases.size()):
		if ratio < float(phases[i]["below"]):
			new_phase = i
	if new_phase > _phase:
		_phase = new_phase
		_smoke.emitting = true
		if _phase >= 2:
			_fire.emitting = true
		phase_changed.emit(_phase)
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	process_mode = Node.PROCESS_MODE_ALWAYS     # keep exploding and sinking behind the Victory title
	remove_from_group("enemies")
	set_deferred("monitorable", false)
	for shot in _shots:
		if is_instance_valid(shot["marker"]):
			shot["marker"].queue_free()
	_shots.clear()
	_explosions_left = FxData.BOSS_EXPLOSIONS
	_state = "dying"
	_timer = 0.0


## Called every frame while dying: a chain of explosions, then the ship sinks.
func _dying(delta: float) -> void:
	if _state != "dying":
		return
	_timer -= delta
	if _timer > 0.0:
		return
	if _explosions_left > 0:
		_explosions_left -= 1
		_timer = FxData.BOSS_EXPLOSION_GAP
		GameState.audio.play("explosion")
		var fx := _fx()
		if fx:
			var p := global_position + Vector2(randf_range(-100, 100), randf_range(-30, 30))
			fx.burst(p, FxData.EXPLOSION)
			fx.burst(p, FxData.CANNON_SMOKE)
			fx.shake(FxData.SHAKE_BOSS_BOOM)
		return
	_state = "sinking"
	var fx := _fx()
	if fx:
		fx.burst(global_position + Vector2(0, 40), FxData.SPLASH)
	var sink := create_tween().set_parallel(true)
	sink.tween_property(self, "position:y", position.y + 120.0, FxData.BOSS_SINK_TIME).set_ease(Tween.EASE_IN)
	sink.tween_property(self, "rotation", 0.25, FxData.BOSS_SINK_TIME)
	sink.tween_property(self, "modulate:a", 0.0, FxData.BOSS_SINK_TIME)
	died.emit(self)

# ---------------------------------------------------------------- helpers

func _phase_info() -> Dictionary:
	var phases: Array = data["phases"]
	return phases[_phase]


func _set_facing(direction: float) -> void:
	_dir = direction
	_sprite.flip_h = direction < 0.0     # the picture's bow points right


func _kick(amount: float) -> void:
	if _rock:
		_rock.kill()
	_sprite.skew = amount * -_dir
	_rock = create_tween()
	_rock.tween_property(_sprite, "skew", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _make_emitter(preset: Dictionary) -> CPUParticles2D:
	var p := FxScript.make_trail(preset)
	p.emitting = false
	p.local_coords = false
	p.position = Vector2(0, -10)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(70, 10)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.initial_velocity_min = preset["speed_min"]
	p.initial_velocity_max = preset["speed_max"]
	p.z_index = 1
	add_child(p)
	return p


func _fx() -> Node:
	return get_tree().get_first_node_in_group("fx")
