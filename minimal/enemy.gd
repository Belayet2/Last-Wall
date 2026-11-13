extends Node2D
# One enemy (thrower, fast, heavy or boss). Stands still and throws. The boss slides left/right.

signal threw(enemy: Node2D, shot_kind: String)
signal died(enemy: Node2D)

const D = preload("res://data.gd")

var kind := "thrower"
var hp := 1
var max_hp := 1
var coins := 0
var interval := 1.0
var box_size := Vector2(40, 40)
var color := Color.RED
var timer := 0.0
var move_dir := 1.0
var hurt_time := 0.0


func setup(enemy_kind: String, pos: Vector2) -> void:
	var d: Dictionary = D.ENEMIES[enemy_kind]
	kind = enemy_kind
	hp = d["hp"]
	max_hp = hp
	coins = d["coins"]
	interval = d["interval"]
	box_size = d["size"]
	color = d["color"]
	position = pos
	timer = D.FIRST_THROW_DELAY + randf() * interval # random offset so they don't all throw together


func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = interval + randf_range(-D.THROW_JITTER, D.THROW_JITTER)
		var shot := kind
		if kind == "boss":
			shot = D.BOSS_SHOTS.pick_random()
		threw.emit(self, shot)

	if kind == "boss":
		var half := box_size.x / 2.0
		position.x += move_dir * D.BOSS_MOVE_SPEED * delta
		if position.x < D.FIELD_LEFT + half:
			move_dir = 1.0
		elif position.x > D.FIELD_RIGHT - half:
			move_dir = -1.0

	if hurt_time > 0.0:
		hurt_time -= delta
		queue_redraw()


func hit(damage: int) -> void:
	if hp <= 0:
		return
	hp -= damage
	hurt_time = 0.1
	queue_redraw()
	if hp <= 0:
		died.emit(self)


func _draw() -> void:
	draw_rect(Rect2(-box_size / 2.0, box_size), Color.WHITE if hurt_time > 0.0 else color)
	var bar := Rect2(-box_size.x / 2.0, -box_size.y / 2.0 - 10.0, box_size.x, 5.0)
	draw_rect(bar, Color.BLACK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * maxi(hp, 0) / float(max_hp), bar.size.y)), Color.GREEN)
