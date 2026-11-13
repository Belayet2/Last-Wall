extends Node2D
# One wave on one wall: builds hero, wall, enemies, obstacles, moves projectiles,
# does all collisions, and draws the HUD. Emits finished(held) when the wave ends.

signal finished(held: bool)

const D = preload("res://data.gd")
const Hero = preload("res://hero.gd")
const Enemy = preload("res://enemy.gd")
const Wall = preload("res://wall.gd")
const Projectile = preload("res://projectile.gd")

var hero: Hero
var wall: Wall
var enemies: Array[Enemy] = []
var projectiles: Array[Projectile] = []
var obstacles: Array[Polygon2D] = []
var hud: Label
var done := false


func _ready() -> void:
	var n: int = GameState.current_wall
	var level: Dictionary = D.LEVELS[n - 1]

	wall = Wall.new()
	wall.setup(n, GameState.wall_hp[n - 1], GameState.wall_max(n))
	wall.fallen.connect(_on_wall_fallen)
	add_child(wall)

	_spawn_obstacles(int(level["obstacles"]))
	_spawn_enemies(level["enemies"], bool(level["boss"]))

	hero = Hero.new()
	hero.position = Vector2((D.FIELD_LEFT + D.FIELD_RIGHT) / 2.0, D.HERO_Y)
	add_child(hero)

	hud = Label.new()
	hud.position = Vector2(20, 20)
	hud.add_theme_font_size_override("font_size", 20)
	add_child(hud)
	_update_hud()


func _draw() -> void:
	draw_rect(Rect2(D.FIELD_LEFT, 0.0, D.FIELD_RIGHT - D.FIELD_LEFT, D.SCREEN_H), Color(0.12, 0.25, 0.4))


func _spawn_obstacles(count: int) -> void:
	var half := D.OBSTACLE_SIZE / 2.0
	for i in count:
		var o := Polygon2D.new()
		o.polygon = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
		o.color = Color(0.55, 0.55, 0.6)
		var x := D.FIELD_LEFT + (D.FIELD_RIGHT - D.FIELD_LEFT) * (i + 1) / float(count + 1) + randf_range(-40.0, 40.0)
		o.position = Vector2(x, randf_range(D.OBSTACLE_MIN_Y, D.OBSTACLE_MAX_Y))
		o.rotation = deg_to_rad(randf_range(-D.OBSTACLE_MAX_TILT, D.OBSTACLE_MAX_TILT))
		add_child(o)
		obstacles.append(o)


func _spawn_enemies(kinds: Array, boss: bool) -> void:
	var row_y := D.ENEMY_ROW_Y_WITH_BOSS if boss else D.ENEMY_ROW_Y
	for i in kinds.size():
		var x := D.FIELD_LEFT + (D.FIELD_RIGHT - D.FIELD_LEFT) * (i + 1) / float(kinds.size() + 1)
		_add_enemy(kinds[i], Vector2(x, row_y))
	if boss:
		_add_enemy("boss", Vector2((D.FIELD_LEFT + D.FIELD_RIGHT) / 2.0, D.BOSS_Y))


func _add_enemy(kind: String, pos: Vector2) -> void:
	var e := Enemy.new()
	e.setup(kind, pos)
	e.threw.connect(_on_enemy_threw)
	e.died.connect(_on_enemy_died)
	add_child(e)
	enemies.append(e)


func _physics_process(delta: float) -> void:
	if done:
		return
	for p in projectiles.duplicate():
		p.step(delta)
		_collide(p)
		if p.dead:
			projectiles.erase(p)
			p.queue_free()
		if done:
			return
	_update_hud()


func _collide(p: Projectile) -> void:
	var r := p.radius
	# Side edges are solid.
	if p.position.x - r < D.FIELD_LEFT and p.vel.x < 0.0:
		p.position.x = D.FIELD_LEFT + r
		p.vel = p.vel.bounce(Vector2.RIGHT)
	elif p.position.x + r > D.FIELD_RIGHT and p.vel.x > 0.0:
		p.position.x = D.FIELD_RIGHT - r
		p.vel = p.vel.bounce(Vector2.LEFT)

	# Obstacles reflect both kinds.
	for o in obstacles:
		var push := _circle_rect(p.position, r, o.position, D.OBSTACLE_SIZE / 2.0, o.rotation)
		if push != Vector2.ZERO:
			p.position += push
			var n := push.normalized()
			if p.vel.dot(n) < 0.0:
				p.vel = p.vel.bounce(n)

	if p.returned:
		for e in enemies.duplicate():
			if _circle_rect(p.position, r, e.position, e.box_size / 2.0, 0.0) != Vector2.ZERO:
				p.dead = true
				e.hit(D.RETURN_DAMAGE_HEAVY if p.heavy else D.RETURN_DAMAGE)
				break
	else:
		var on_shield := _circle_rect(p.position, r, hero.shield_center(), hero.shield_half(), hero.shield_rotation()) != Vector2.ZERO
		if on_shield and p.vel.dot(hero.shield_dir) < 0.0:
			_shield_hit(p)
		elif p.position.y + r >= D.WALL_TOP:
			p.dead = true
			wall.take_damage(p.damage)

	if p.position.y < -40.0 or p.position.y > D.SCREEN_H + 40.0:
		p.dead = true


func _shield_hit(p: Projectile) -> void:
	if randf() < GameState.bounce_rate():
		# BOUNCE: reflect off the shield, speed up, nudge toward the nearest enemy.
		p.vel = p.vel.bounce(hero.shield_dir) * D.BOUNCE_SPEEDUP
		var aim: float = GameState.aim_accuracy()
		var target := _nearest_enemy(p.position)
		if target != null and aim > 0.0:
			var ang := lerp_angle(p.vel.angle(), (target.position - p.position).angle(), aim)
			p.vel = Vector2.from_angle(ang) * p.vel.length()
		p.make_returned()
		hero.flash(Color.WHITE)
	else:
		# FIZZLE: blocked, not returned, no wall damage.
		p.dead = true
		hero.flash(Color(0.5, 0.5, 0.5))
		_puff(p.position, Color(0.6, 0.6, 0.6), 14.0)


func _nearest_enemy(from: Vector2) -> Enemy:
	var best: Enemy = null
	for e in enemies:
		if best == null or from.distance_to(e.position) < from.distance_to(best.position):
			best = e
	return best


# Circle vs rotated rectangle. Returns the push-out vector (normal * depth), or ZERO if not touching.
func _circle_rect(c: Vector2, r: float, center: Vector2, half: Vector2, rot: float) -> Vector2:
	var local := (c - center).rotated(-rot)
	var d := local - local.clamp(-half, half)
	var dist := d.length()
	if dist >= r:
		return Vector2.ZERO
	if dist > 0.001:
		return (d / dist * (r - dist)).rotated(rot)
	# Centre is inside the rectangle: push out along the shallowest axis.
	var dx := half.x - absf(local.x)
	var dy := half.y - absf(local.y)
	var n := Vector2(1.0 if local.x >= 0.0 else -1.0, 0.0) * (dx + r)
	if dy < dx:
		n = Vector2(0.0, 1.0 if local.y >= 0.0 else -1.0) * (dy + r)
	return n.rotated(rot)


func _on_enemy_threw(e: Enemy, shot_kind: String) -> void:
	var d: Dictionary = D.ENEMIES[shot_kind]
	var from := e.position + Vector2(0.0, e.box_size.y / 2.0)
	var target := Vector2(randf_range(D.FIELD_LEFT + 20.0, D.FIELD_RIGHT - 20.0), D.WALL_TOP)
	var dir := (target - from).normalized().rotated(randf_range(-D.AIM_ERROR, D.AIM_ERROR))
	var p := Projectile.new()
	p.setup(from, dir * float(d["speed"]), int(d["damage"]), float(d["radius"]), bool(d["heavy"]))
	add_child(p)
	projectiles.append(p)


func _on_enemy_died(e: Enemy) -> void:
	GameState.add_coins(e.coins)
	_puff(e.position, e.color, e.box_size.x * 0.6)
	enemies.erase(e)
	e.queue_free()
	if enemies.is_empty():
		_finish(true)


func _on_wall_fallen() -> void:
	_finish(false)


func _finish(held: bool) -> void:
	if done:
		return
	done = true
	finished.emit(held)


func _puff(pos: Vector2, color: Color, radius: float) -> void:
	var puff := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(Vector2.from_angle(TAU * i / 12.0) * radius)
	puff.polygon = pts
	puff.color = color
	puff.position = pos
	add_child(puff)
	var tw := puff.create_tween()
	tw.tween_property(puff, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(puff, "scale", Vector2(1.8, 1.8), 0.3)
	tw.tween_callback(puff.queue_free)


func _update_hud() -> void:
	hud.text = "WALL %d / %d\nWall HP: %d / %d\nCoins: %d\nEnemies left: %d\n\nBounce rate: %d%%\nMove speed: %d\nAim accuracy: %.2f\n\nA / D or arrows: move\nMouse: aim shield\nEsc: pause" % [
		GameState.current_wall, D.LEVELS.size(), wall.hp, wall.max_hp, GameState.coins, enemies.size(),
		roundi(GameState.bounce_rate() * 100.0), roundi(GameState.move_speed()), GameState.aim_accuracy()]
