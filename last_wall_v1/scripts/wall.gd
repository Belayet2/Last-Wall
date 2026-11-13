extends Area2D
## The wall behind the hero. Hostile stones damage it.
## Looks: whole -> cracked -> broken. The door is part of the picture (decoration).

signal hp_changed(hp: int, max_hp: int)
signal wall_fallen

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")

var max_hp := 300
var hp := 300

var _sprite: Sprite2D
var _flash: Tween


func setup(new_max_hp: int, start_hp: int) -> void:
	max_hp = new_max_hp
	hp = start_hp


func _ready() -> void:
	add_to_group("wall")
	collision_layer = 16
	collision_mask = 0
	monitoring = false
	position = Vector2(GameData.FIELD_CENTER_X, GameData.WALL_TOP + GameData.WALL_HEIGHT * 0.5)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(GameData.FIELD_RIGHT - GameData.FIELD_LEFT, GameData.WALL_HEIGHT)
	var cs := CollisionShape2D.new()
	cs.shape = rect
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_update_look()


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	_update_look()
	if _flash:
		_flash.kill()
	_sprite.modulate = Color(1.6, 0.7, 0.6)
	_flash = create_tween()
	_flash.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if hp == 0:
		wall_fallen.emit()


func _update_look() -> void:
	var ratio := float(hp) / float(max_hp)
	var key := "wall_whole"
	if hp <= 0:
		key = "wall_broken"
	elif ratio < GameData.WALL_CRACKED_BELOW:
		key = "wall_cracked"
	ArtData.apply(_sprite, key)
