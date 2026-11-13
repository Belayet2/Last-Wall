extends Area2D
## The wall behind the hero. Hostile stones damage it.
## Looks: whole -> cracked -> broken. The door is part of the picture (decoration).

signal hp_changed(hp: int, max_hp: int)
signal wall_fallen

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")

var max_hp := 300
var hp := 300

var _sprite: Sprite2D
var _look := ""
var _flash: Tween
var _jiggle: Tween


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


func take_damage(amount: int, hit_pos: Vector2) -> void:
	if hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	var changed := _update_look()

	if _flash:
		_flash.kill()
	_sprite.modulate = FxData.WALL_HIT_FLASH
	_flash = create_tween()
	_flash.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if _jiggle:
		_jiggle.kill()
	_jiggle = create_tween()
	_jiggle.tween_property(_sprite, "position:x", FxData.WALL_JIGGLE, 0.04)
	_jiggle.tween_property(_sprite, "position:x", -FxData.WALL_JIGGLE, 0.06)
	_jiggle.tween_property(_sprite, "position:x", 0.0, 0.05)

	var fx := get_tree().get_first_node_in_group("fx")
	if fx:
		fx.float_text(hit_pos + Vector2(0, -20), "-%d" % amount, FxData.DAMAGE_COLOR)
		if changed:
			fx.shake(FxData.SHAKE_WALL_CRACK)
			fx.burst(Vector2(GameData.FIELD_CENTER_X, GameData.WALL_TOP), FxData.WALL_RUBBLE)
		else:
			fx.shake(FxData.SHAKE_WALL_HIT)
	if hp == 0:
		wall_fallen.emit()


## Picks whole / cracked / broken. Returns true if the look changed.
func _update_look() -> bool:
	var ratio := float(hp) / float(max_hp)
	var key := "wall_whole"
	if hp <= 0:
		key = "wall_broken"
	elif ratio < GameData.WALL_CRACKED_BELOW:
		key = "wall_cracked"
	if key == _look:
		return false
	var first := _look == ""
	_look = key
	ArtData.apply(_sprite, key)
	return not first
