extends Area2D
## An enemy standing on the ruins, facing the hero. Never moves.
## Raises its arm (windup pose), then throws a stone from its hand.
## A red landing marker on the path shows where to stand to block it.

signal died(enemy: Node)

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const StoneScript = preload("res://scripts/stone.gd")
const FxData = preload("res://scripts/data/fx_data.gd")

var type_key := "thrower"
var index := 0
var data: Dictionary = {}
var hp := 1
var max_stones := 2
var dead := false

var _stones_parent: Node
var _markers_parent: Node
var _sprite: Sprite2D
var _body_size := Vector2.ZERO
var _timer := 0.0
var _winding := false
var _target := Vector2.ZERO
var _marker: Node2D = null
var _windup: Tween
var _flash: Tween
var _knock: Tween
var _home := Vector2.ZERO


func setup(key: String, enemy_index: int, stone_cap: int, stones_parent: Node, markers_parent: Node) -> void:
	type_key = key
	index = enemy_index
	max_stones = stone_cap
	_stones_parent = stones_parent
	_markers_parent = markers_parent


func _ready() -> void:
	data = EnemyData.TYPES[type_key]
	hp = data["hp"]
	_body_size = data["size"]
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var rect := RectangleShape2D.new()
	rect.size = _body_size * EnemyData.HITBOX_SCALE
	var cs := CollisionShape2D.new()
	cs.shape = rect
	add_child(cs)
	var shadow := ArtData.make_sprite("shadow", Vector2(_body_size.x * 1.1, 12))
	shadow.position = Vector2(0, _body_size.y * 0.5 - 2)
	add_child(shadow)
	_sprite = ArtData.make_sprite(data["sprite"], _body_size)
	add_child(_sprite)
	_home = position
	_timer = randf_range(EnemyData.FIRST_THROW_DELAY_MIN, data["throw_interval"])


func _process(delta: float) -> void:
	if dead or _winding:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	if get_tree().get_nodes_in_group("threat").size() >= max_stones:
		_timer = EnemyData.RETRY_WAIT
		return
	_start_windup()


func _throw_origin() -> Vector2:
	var hand: Vector2 = data["hand"]
	return global_position + hand


func _start_windup() -> void:
	var windup_time: float = data.get("windup_time", EnemyData.WINDUP_TIME)
	_winding = true
	add_to_group("threat")
	var margin := EnemyData.TARGET_EDGE_MARGIN
	_target = Vector2(randf_range(GameData.FIELD_LEFT + margin, GameData.FIELD_RIGHT - margin), GameData.WALL_TOP + 10.0)
	var start := _throw_origin()
	var t := (GameData.CATCH_Y - start.y) / (_target.y - start.y)
	var stone_size: float = data["stone_size"]
	var mark_scale := clampf(stone_size / EnemyData.MARKER_BASE_STONE, EnemyData.MARKER_SCALE_MIN, EnemyData.MARKER_SCALE_MAX)
	_marker = ArtData.make_sprite("marker", ArtData.size_of("marker") * mark_scale)
	_marker.position = Vector2(lerpf(start.x, _target.x, t), GameData.MARKER_Y)
	_marker.modulate.a = 0.0
	_markers_parent.add_child(_marker)
	var marker_tween := _marker.create_tween()
	marker_tween.tween_property(_marker, "modulate:a", 1.0, windup_time * 0.5)
	var base_scale := _marker.scale
	var pulse := _marker.create_tween().set_loops()
	pulse.tween_property(_marker, "scale", base_scale * FxData.MARKER_PULSE, FxData.MARKER_PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_marker, "scale", base_scale, FxData.MARKER_PULSE_TIME).set_trans(Tween.TRANS_SINE)

	ArtData.apply(_sprite, data["windup_sprite"], _body_size)
	_windup = create_tween()
	_windup.set_parallel(true)
	_windup.tween_property(_sprite, "position", Vector2(0, -3), windup_time)
	_windup.tween_property(_sprite, "modulate", Color(1.3, 1.15, 1.05), windup_time)
	_windup.chain().tween_callback(_throw)


func _throw() -> void:
	if dead:
		return
	_winding = false
	remove_from_group("threat")
	var start := _throw_origin()
	var speed: float = data["stone_speed"]
	var stone := StoneScript.new()
	stone.setup(start, (_target - start).normalized() * speed, data["stone_size"], data["wall_damage"], data["return_damage"])
	stone.marker = _marker
	_marker = null
	_stones_parent.add_child(stone)

	ArtData.apply(_sprite, data["sprite"], _body_size)
	var back := create_tween()
	back.set_parallel(true)
	back.tween_property(_sprite, "position", Vector2.ZERO, 0.12)
	back.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	var interval: float = data["throw_interval"]
	_timer = interval * randf_range(1.0 - EnemyData.INTERVAL_JITTER, 1.0 + EnemyData.INTERVAL_JITTER)


func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	if _flash:
		_flash.kill()
	_sprite.self_modulate = Color(3, 3, 3)
	_flash = create_tween()
	_flash.tween_property(_sprite, "self_modulate", Color.WHITE, 0.15)
	if _knock:
		_knock.kill()
	position = _home + Vector2(0, -FxData.KNOCKBACK)
	_knock = create_tween()
	_knock.tween_property(self, "position", _home, FxData.KNOCKBACK_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	remove_from_group("threat")
	if _windup:
		_windup.kill()
	if is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null
	set_deferred("monitorable", false)
	var fx := get_tree().get_first_node_in_group("fx")
	if fx:
		fx.burst(global_position, FxData.ENEMY_BURST)
		fx.burst(global_position, FxData.DUST)
		fx.shake(FxData.SHAKE_ENEMY_DOWN)
	died.emit(self)
	var pop := create_tween()
	pop.set_parallel(true)
	pop.tween_property(self, "scale", Vector2(1.5, 1.5), 0.25)
	pop.tween_property(self, "modulate:a", 0.0, 0.25)
	pop.chain().tween_callback(queue_free)
