extends Area2D
## Flat shield above the hero. Every stone that touches it bounces (100%).
## Where the stone hits decides the angle; aim assist nudges it toward an enemy.

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")

var width := 150.0

var _sprite: Sprite2D
var _shape: RectangleShape2D
var _flash: Tween


func _ready() -> void:
	add_to_group("shield")
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	_shape = RectangleShape2D.new()
	var cs := CollisionShape2D.new()
	cs.shape = _shape
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	set_width(GameState.get_value("shield_width"))


func set_width(new_width: float) -> void:
	width = new_width
	_shape.size = Vector2(width, GameData.SHIELD_HEIGHT)
	ArtData.apply(_sprite, "shield", Vector2(width, GameData.SHIELD_SPRITE_HEIGHT))


func bounce_stone(stone) -> void:
	var stone_pos: Vector2 = stone.global_position
	var offset := clampf((stone_pos.x - global_position.x) / (width * 0.5), -1.0, 1.0)
	var dir := Vector2.UP.rotated(deg_to_rad(offset * GameData.MAX_BOUNCE_ANGLE_DEG))
	var target := _nearest_enemy(stone_pos)
	if target != null:
		var to_enemy := (target.global_position - stone_pos).angle()
		dir = Vector2.from_angle(lerp_angle(dir.angle(), to_enemy, GameState.get_value("aim_assist")))
	var speed: float = stone.velocity.length() * GameData.RETURN_SPEED_MULT
	var top := global_position.y - GameData.SHIELD_HEIGHT * 0.5 - float(stone.diameter) * 0.5
	stone.global_position.y = minf(stone.global_position.y, top)
	stone.make_returned(dir * speed)
	_flash_shield()


func _nearest_enemy(from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d := from.distance_squared_to((enemy as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _flash_shield() -> void:
	if _flash:
		_flash.kill()
	_sprite.modulate = Color(2.2, 2.0, 1.4)
	_flash = create_tween()
	_flash.tween_property(_sprite, "modulate", Color.WHITE, 0.15)
