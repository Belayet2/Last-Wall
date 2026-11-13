class_name Enemy
extends Area2D
## Shared by all enemy types. Stands still at the top and throws at the wall.
## Stats come from EnemyData.TYPES[enemy_type]; the look comes from the scene's Sprite2D.

signal threw(from: Vector2, dir: Vector2, speed: float, damage: int, return_damage: int)
signal died(enemy: Area2D, coin_reward: int)

@export var enemy_type := "thrower"

var data: Dictionary
var hp := 1
var _alive := true
var _throw_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var hp_back: ColorRect = $HpBack
@onready var hp_fill: ColorRect = $HpBack/HpFill


func _ready() -> void:
	add_to_group("enemy")
	data = EnemyData.TYPES[enemy_type]
	hp = data["max_hp"]
	var size: Vector2 = data["size"]
	Fx.fit_sprite(sprite, size)
	(shape.shape as CircleShape2D).radius = size.x * 0.42
	hp_back.size = Vector2(size.x * 0.8, 5)
	hp_back.position = Vector2(-hp_back.size.x * 0.5, size.y * 0.5 + 2)
	_update_hp_bar()
	var d: Vector2 = GameConfig.ENEMY_FIRST_THROW_DELAY
	_throw_timer = randf_range(d.x, d.y)


func is_alive() -> bool:
	return _alive


func _process(delta: float) -> void:
	if not _alive:
		return
	_throw_timer -= delta
	if _throw_timer <= 0.0:
		_throw()
		var j := GameConfig.ENEMY_THROW_JITTER
		_throw_timer = data["throw_interval"] + randf_range(-j, j)


func _throw() -> void:
	var from := global_position + Vector2(0, data["size"].y * 0.3)
	var margin := 20.0
	var target := Vector2(
		randf_range(GameConfig.FIELD_LEFT + margin, GameConfig.FIELD_RIGHT - margin),
		GameConfig.FIELD_BOTTOM - GameConfig.WALL_HEIGHT)
	var err := deg_to_rad(GameConfig.THROW_ANGLE_ERROR_DEG)
	var dir := (target - from).normalized().rotated(randf_range(-err, err))
	threw.emit(from, dir, data["projectile_speed"], data["damage"], data["return_damage"])
	# Little throw "hop" so you can see who threw.
	var tw := create_tween()
	tw.tween_property(sprite, "position:y", -6.0, 0.08)
	tw.tween_property(sprite, "position:y", 0.0, 0.12)


func take_hit(amount: int) -> void:
	if not _alive:
		return
	hp -= amount
	_update_hp_bar()
	Fx.flash(sprite, Color(1.0, 0.35, 0.35), 0.2)
	if hp <= 0:
		_die()


func _die() -> void:
	_alive = false
	remove_from_group("enemy")
	set_deferred("monitorable", false)
	hp_back.visible = false
	Fx.puff(get_parent(), global_position, Color(1.0, 0.5, 0.35), 70.0, 0.4)
	died.emit(self, data["coin_reward"])
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)


func _update_hp_bar() -> void:
	hp_fill.size = Vector2(hp_back.size.x * clampf(float(hp) / data["max_hp"], 0.0, 1.0), hp_back.size.y)
