extends Area2D
## An enemy standing on the ruins. Never moves. Winds up, then throws a stone.
## A red landing marker shows where the stone will cross the shield line.

signal died(enemy: Node)

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const StoneScript = preload("res://scripts/stone.gd")

var type_key := "thrower"
var data: Dictionary = {}
var hp := 1
var max_stones := 2
var dead := false

var _stones_parent: Node
var _markers_parent: Node
var _sprite: Sprite2D
var _timer := 0.0
var _winding := false
var _target := Vector2.ZERO
var _marker: Node2D = null
var _windup: Tween
var _flash: Tween


func setup(key: String, stone_cap: int, stones_parent: Node, markers_parent: Node) -> void:
	type_key = key
	max_stones = stone_cap
	_stones_parent = stones_parent
	_markers_parent = markers_parent


func _ready() -> void:
	data = EnemyData.TYPES[type_key]
	hp = data["hp"]
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var rect := RectangleShape2D.new()
	var body_size: Vector2 = data["size"]
	rect.size = body_size * EnemyData.HITBOX_SCALE
	var cs := CollisionShape2D.new()
	cs.shape = rect
	add_child(cs)
	_sprite = ArtData.make_sprite(data["sprite"], data["size"])
	add_child(_sprite)
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
	var size: Vector2 = data["size"]
	return global_position + Vector2(0, size.y * 0.3)


func _start_windup() -> void:
	_winding = true
	add_to_group("threat")
	var margin := EnemyData.TARGET_EDGE_MARGIN
	_target = Vector2(randf_range(GameData.FIELD_LEFT + margin, GameData.FIELD_RIGHT - margin), GameData.WALL_TOP + 10.0)
	var start := _throw_origin()
	var t := (GameData.SHIELD_Y - start.y) / (_target.y - start.y)
	_marker = ArtData.make_sprite("marker")
	_marker.position = Vector2(lerpf(start.x, _target.x, t), GameData.SHIELD_Y)
	_marker.modulate.a = 0.0
	_markers_parent.add_child(_marker)
	var marker_tween := _marker.create_tween()
	marker_tween.tween_property(_marker, "modulate:a", 1.0, EnemyData.WINDUP_TIME * 0.5)

	_windup = create_tween()
	_windup.set_parallel(true)
	_windup.tween_property(_sprite, "position", Vector2(0, -6), EnemyData.WINDUP_TIME)
	_windup.tween_property(_sprite, "modulate", Color(1.5, 1.25, 1.1), EnemyData.WINDUP_TIME)
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
	died.emit(self)
	var pop := create_tween()
	pop.set_parallel(true)
	pop.tween_property(self, "scale", Vector2(1.5, 1.5), 0.25)
	pop.tween_property(self, "modulate:a", 0.0, 0.25)
	pop.chain().tween_callback(queue_free)
