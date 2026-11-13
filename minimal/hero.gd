extends Node2D
# Hero (blue box) that moves left/right, plus the shield (yellow bar) that faces the mouse.

const D = preload("res://data.gd")

var shield_dir := Vector2.UP
var flash_color := Color.WHITE
var flash_time := 0.0


func _process(delta: float) -> void:
	var input := Input.get_axis("move_left", "move_right")
	var half := D.HERO_SIZE.x / 2.0
	position.x = clampf(position.x + input * GameState.move_speed() * delta,
		D.FIELD_LEFT + half, D.FIELD_RIGHT - half)

	# Face the mouse, but only in the upper half (10..170 degrees above horizontal).
	var ang := (get_global_mouse_position() - global_position).angle()
	var lo := -deg_to_rad(D.SHIELD_MAX_DEG)
	var hi := -deg_to_rad(D.SHIELD_MIN_DEG)
	if ang > 0.0: # mouse is below the hero
		ang = lo if ang > PI / 2.0 else hi
	shield_dir = Vector2.from_angle(clampf(ang, lo, hi))

	flash_time = maxf(flash_time - delta, 0.0)
	queue_redraw()


func shield_center() -> Vector2:
	return position + shield_dir * D.SHIELD_DISTANCE


func shield_rotation() -> float:
	return shield_dir.angle() + PI / 2.0


func shield_half() -> Vector2:
	return Vector2(D.SHIELD_WIDTH, D.SHIELD_THICKNESS) / 2.0


func flash(color: Color) -> void:
	flash_color = color
	flash_time = D.SHIELD_FLASH_TIME


func _draw() -> void:
	draw_rect(Rect2(-D.HERO_SIZE / 2.0, D.HERO_SIZE), Color(0.2, 0.45, 1.0))
	var col := flash_color if flash_time > 0.0 else Color(1.0, 0.85, 0.1)
	var h := shield_half()
	draw_set_transform(shield_dir * D.SHIELD_DISTANCE, shield_rotation())
	draw_rect(Rect2(-h, h * 2.0), col)
	draw_set_transform(Vector2.ZERO, 0.0)
