extends Area2D
## An enemy standing on the ruins. Never moves.
## Winds up (raises its arm / loads its cannon), then throws or fires from its "hand" (muzzle).
##
## Two kinds of pictures (see enemy_data.gd):
##   pose swap  = "sprite" + "windup_sprite" (slinger, catapult)
##   animation  = "anim" frames on one strip picture (the cannon: idle, loading, fire + smoke)

signal died(enemy: Node)

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const StoneScript = preload("res://scripts/stone.gd")
const FxData = preload("res://scripts/data/fx_data.gd")

var type_key := "cannon"
var index := 0
var data: Dictionary = {}
var hp := 1
var max_stones := 2
var dead := false

var _stones_parent: Node
var _sprite: Sprite2D
var _body_size := Vector2.ZERO
var _timer := 0.0
var _winding := false
var _target := Vector2.ZERO
var _windup: Tween
var _flash: Tween
var _knock: Tween
var _home := Vector2.ZERO
var _anim: Dictionary = {}      # cannon: frame numbers
var _facing := 1.0              # cannon: 1 = barrel points right, -1 = left
var _aim_rotation := 0.0        # cannon: barrel tilt for the current shot
var _sprite_home := Vector2.ZERO # cannon: where the sprite sits (the wheel axle)


func setup(key: String, enemy_index: int, stone_cap: int, stones_parent: Node) -> void:
	type_key = key
	index = enemy_index
	max_stones = stone_cap
	_stones_parent = stones_parent


func _ready() -> void:
	data = EnemyData.TYPES[type_key]
	hp = data["hp"]
	_body_size = data["size"]
	_anim = data.get("anim", {})
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
	if _anim.is_empty():
		_sprite = ArtData.make_sprite(data["sprite"], _body_size)
	else:
		_sprite = ArtData.make_sprite(data["sprite"])
		_sprite.frame = _anim["idle"]
	add_child(_sprite)
	_home = position
	if not _anim.is_empty():
		_set_facing(1.0 if _home.x < GameData.FIELD_CENTER_X else -1.0)
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


## Where the stone leaves from (the hand, or the cannon's muzzle).
func _throw_origin() -> Vector2:
	if not _anim.is_empty():
		return _muzzle(_sprite.rotation)
	var hand: Vector2 = data["hand"]
	return global_position + hand


## Cannon: the muzzle on screen for a barrel tilt of `tilt`.
func _muzzle(tilt: float) -> Vector2:
	var m: Vector2 = _anim["muzzle"] - _anim["axle"]
	m = Vector2(m.x * _facing, m.y) * _sprite.scale
	return global_position + _sprite_home + m.rotated(tilt)


func _start_windup() -> void:
	var windup_time: float = data.get("windup_time", EnemyData.WINDUP_TIME)
	_winding = true
	add_to_group("threat")
	var margin := EnemyData.TARGET_EDGE_MARGIN
	var spread: float = data["aim_spread"]
	var lo := maxf(_home.x - spread, GameData.FIELD_LEFT + margin)
	var hi := minf(_home.x + spread, GameData.FIELD_RIGHT - margin)
	_target = Vector2(randf_range(lo, hi), GameData.WALL_TOP + 10.0)

	if not _anim.is_empty():
		_aim_cannon(windup_time)

	_windup = create_tween()
	_windup.set_parallel(true)
	if _anim.is_empty():
		ArtData.apply(_sprite, data["windup_sprite"], _body_size)
		_windup.tween_property(_sprite, "position", Vector2(0, -3), windup_time)
	_windup.tween_property(_sprite, "modulate", Color(1.3, 1.15, 1.05), windup_time)
	_windup.chain().tween_callback(_throw)


## Cannon: turn toward the target side, tilt the barrel down (a little), and load (squash frame).
func _aim_cannon(windup_time: float) -> void:
	var dx := _target.x - _home.x
	if absf(dx) > 40.0:
		_set_facing(signf(dx))
	var dir := _target - global_position
	var below := absf(atan2(dir.y, absf(dir.x)))           # angle under the horizon
	var max_tilt: float = data["max_tilt"]
	_aim_rotation = minf(below, max_tilt) * _facing
	_sprite.frame = _anim["windup"]
	var turn := create_tween()
	turn.tween_property(_sprite, "rotation", _aim_rotation, minf(0.25, windup_time * 0.5)).set_trans(Tween.TRANS_SINE)
	var fx := get_tree().get_first_node_in_group("fx")
	if fx:   # the fuse is lit
		fx.burst(global_position + Vector2(-20.0 * _facing, -12.0).rotated(_aim_rotation), FxData.FUSE_SPARK)



func _throw() -> void:
	if dead:
		return
	_winding = false
	remove_from_group("threat")
	var start := _throw_origin()
	var speed: float = data["stone_speed"]
	var stone := StoneScript.new()
	stone.art = data.get("stone_art", "stone")
	stone.setup(start, (_target - start).normalized() * speed, data["stone_size"], data["wall_damage"], data["return_damage"])
	_stones_parent.add_child(stone)
	GameState.audio.play(data.get("sound", "throw"))

	var back := create_tween()
	back.set_parallel(true)
	back.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	if _anim.is_empty():
		ArtData.apply(_sprite, data["sprite"], _body_size)
		back.tween_property(_sprite, "position", Vector2.ZERO, 0.12)
	else:
		_fire_animation(start)
	var interval: float = data["throw_interval"]
	_timer = interval * randf_range(1.0 - EnemyData.INTERVAL_JITTER, 1.0 + EnemyData.INTERVAL_JITTER)


## Cannon: blast frames + smoke, a kick backwards, then back to idle.
func _fire_animation(muzzle: Vector2) -> void:
	var frames: Array = _anim["fire"]
	var fps: float = _anim["fps"]
	var anim := create_tween()
	for f in frames:
		anim.tween_callback(func() -> void: _sprite.frame = f)
		anim.tween_interval(1.0 / fps)
	anim.tween_callback(func() -> void: _sprite.frame = _anim["idle"])
	anim.tween_property(_sprite, "rotation", 0.0, 0.35).set_trans(Tween.TRANS_SINE)   # level the barrel again
	_sprite.position = _sprite_home + Vector2(-6.0 * _facing, 0).rotated(_aim_rotation)
	create_tween().tween_property(_sprite, "position", _sprite_home, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var fx := get_tree().get_first_node_in_group("fx")
	if fx:
		fx.burst(muzzle, FxData.SMALL_MUZZLE_FLASH, (_target - muzzle).normalized())
		fx.shake(FxData.SHAKE_SMALL_CANNON)


func _set_facing(direction: float) -> void:
	_facing = direction
	_sprite.flip_h = direction < 0.0
	# the sprite turns around the wheel axle, and the cannon's middle sits on the enemy's position
	var cell := _sprite.texture.get_size() / Vector2(_sprite.hframes, 1)
	var axle: Vector2 = _anim["axle"]
	var center: Vector2 = _anim["center"]
	var axle_x := axle.x if direction > 0.0 else cell.x - axle.x
	_sprite.offset = cell * 0.5 - Vector2(axle_x, axle.y)
	_sprite_home = Vector2((axle.x - center.x) * direction, axle.y - center.y) * _sprite.scale
	_sprite.position = _sprite_home


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
	else:
		GameState.audio.play("enemy_hit")


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	remove_from_group("threat")
	if _windup:
		_windup.kill()
	set_deferred("monitorable", false)
	var fx := get_tree().get_first_node_in_group("fx")
	if not _anim.is_empty():
		GameState.audio.play("explosion")
		if fx:
			fx.burst(global_position, FxData.EXPLOSION)
			fx.burst(global_position, FxData.CANNON_SMOKE)
			fx.burst(global_position, FxData.WOOD_CHIPS)
			fx.shake(FxData.SHAKE_ENEMY_DOWN * 1.5)
	else:
		GameState.audio.play("enemy_down")
		if fx:
			fx.burst(global_position, FxData.ENEMY_BURST)
			fx.burst(global_position, FxData.DUST)
			fx.shake(FxData.SHAKE_ENEMY_DOWN)
	died.emit(self)
	var pop := create_tween()
	pop.set_parallel(true)
	pop.tween_property(self, "scale", Vector2(1.5, 1.5), 0.25)
	pop.tween_property(self, "modulate:a", 0.0, 0.25)
	if not _anim.is_empty():
		pop.tween_property(_sprite, "rotation", _sprite.rotation + 0.6 * _facing, 0.25)
	pop.chain().tween_callback(queue_free)
