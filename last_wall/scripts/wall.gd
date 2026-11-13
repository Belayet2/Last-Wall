extends Area2D
## The castle wall behind the hero. Only the wall has health.

signal hp_changed(hp: int, max_hp: int)
signal wall_fallen

enum WallState { HELD, DAMAGED, FALLEN }

@export var texture_full: Texture2D
@export var texture_cracked: Texture2D
@export var texture_broken: Texture2D

var max_hp := 100
var hp := 100
var state := WallState.HELD

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("wall")
	var width := GameConfig.FIELD_RIGHT - GameConfig.FIELD_LEFT
	var size := Vector2(width, GameConfig.WALL_HEIGHT)
	position = Vector2(GameConfig.FIELD_LEFT + width * 0.5, GameConfig.FIELD_BOTTOM - size.y * 0.5)
	(shape.shape as RectangleShape2D).size = size
	sprite.texture = texture_full
	Fx.fit_sprite(sprite, size)


func setup(new_max_hp: int, start_hp: int) -> void:
	max_hp = new_max_hp
	hp = clampi(start_hp, 0, max_hp)
	_update_look()
	hp_changed.emit(hp, max_hp)


func take_damage(amount: int, hit_pos: Vector2) -> void:
	if state == WallState.FALLEN:
		return
	hp = maxi(hp - amount, 0)
	Fx.flash(sprite, Color(1.0, 0.5, 0.45), 0.2)
	Fx.puff(get_parent(), hit_pos, Color(0.85, 0.75, 0.6), 40.0, 0.35)
	_update_look()
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		wall_fallen.emit()


func _update_look() -> void:
	var frac := float(hp) / float(max_hp)
	if hp <= 0:
		state = WallState.FALLEN
	elif frac < GameConfig.WALL_CRACKED_AT:
		state = WallState.DAMAGED
	else:
		state = WallState.HELD

	if frac >= GameConfig.WALL_CRACKED_AT:
		sprite.texture = texture_full
	elif frac >= GameConfig.WALL_BROKEN_AT:
		sprite.texture = texture_cracked
	else:
		sprite.texture = texture_broken
