extends Node2D
## The hero, seen from behind (he faces the enemies).
## Walks left/right on the path and holds the round shield up in front of him.

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const ShieldScript = preload("res://scripts/shield.gd")

var speed := 360.0
var shield: ShieldScript

var _body: Sprite2D
var _walk := 0.0


func _ready() -> void:
	z_index = 1
	position = Vector2(GameData.FIELD_CENTER_X, GameData.HERO_Y)
	var shadow := ArtData.make_sprite("shadow", Vector2(70, 16))
	shadow.position = Vector2(0, GameData.HERO_SHADOW_Y)
	shadow.z_index = -1
	add_child(shadow)
	shield = ShieldScript.new()
	add_child(shield)
	_body = ArtData.make_sprite("hero")
	add_child(_body)
	speed = GameState.get_value("move_speed")


func _process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	position.x += dir * speed * delta
	var half := shield.catch_width * 0.5
	position.x = clampf(position.x, GameData.FIELD_LEFT + half, GameData.FIELD_RIGHT - half)
	_body.rotation = lerpf(_body.rotation, dir * GameData.HERO_LEAN, 0.2)
	if dir != 0.0:
		_walk += delta * GameData.HERO_BOB_SPEED
	else:
		_walk = 0.0
	_body.position.y = -absf(sin(_walk)) * GameData.HERO_BOB
