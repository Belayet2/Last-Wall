extends Node2D
## The hero. Walks left/right on the path and carries the shield.

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const ShieldScript = preload("res://scripts/shield.gd")

var speed := 300.0
var shield: ShieldScript

var _sprite: Sprite2D


func _ready() -> void:
	z_index = 1
	position = Vector2(GameData.FIELD_CENTER_X, GameData.HERO_Y)
	_sprite = ArtData.make_sprite("hero")
	add_child(_sprite)
	shield = ShieldScript.new()
	shield.position = Vector2(0, GameData.SHIELD_OFFSET_Y)
	add_child(shield)
	speed = GameState.get_value("move_speed")


func _process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	position.x += dir * speed * delta
	var half: float = shield.width * 0.5
	position.x = clampf(position.x, GameData.FIELD_LEFT + half, GameData.FIELD_RIGHT - half)
	_sprite.rotation = lerpf(_sprite.rotation, dir * GameData.HERO_LEAN, 0.2)
