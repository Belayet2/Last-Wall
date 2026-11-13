extends Node2D
# The wall behind the hero (brown box with an HP bar). Color changes with damage.

signal fallen

enum State { HELD, DAMAGED, FALLEN }

const D = preload("res://data.gd")

var number := 1
var hp := 1
var max_hp := 1


func setup(wall_number: int, start_hp: int, wall_max_hp: int) -> void:
	number = wall_number
	hp = start_hp
	max_hp = wall_max_hp


func get_state() -> State:
	if hp <= 0:
		return State.FALLEN
	return State.DAMAGED if hp < max_hp else State.HELD


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	queue_redraw()
	if hp == 0:
		fallen.emit()


func _draw() -> void:
	var frac := float(hp) / float(max_hp)
	var col := Color(0.55, 0.36, 0.2) # full
	if hp <= 0:
		col = Color(0.15, 0.1, 0.08) # broken
	elif frac <= 0.33:
		col = Color(0.45, 0.12, 0.08) # badly cracked
	elif frac <= 0.66:
		col = Color(0.62, 0.3, 0.12) # cracked
	var w := D.FIELD_RIGHT - D.FIELD_LEFT
	draw_rect(Rect2(D.FIELD_LEFT, D.WALL_TOP, w, D.SCREEN_H - D.WALL_TOP), col)
	var bar := Rect2(D.FIELD_LEFT + 20.0, D.WALL_TOP + 40.0, w - 40.0, 14.0)
	draw_rect(bar, Color.BLACK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color.GREEN.lerp(Color.RED, 1.0 - frac))
	var text := "WALL %d   %d / %d   %s" % [number, hp, max_hp, State.keys()[get_state()]]
	draw_string(ThemeDB.fallback_font, Vector2(D.FIELD_LEFT + 20.0, D.WALL_TOP + 30.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
