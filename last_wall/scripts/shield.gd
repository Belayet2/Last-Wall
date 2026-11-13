extends Area2D
## Fixed flat paddle above the hero. Never rotates, never aims.
## Where the shot lands on the paddle decides the bounce direction.

const BOUNCE_FLASH := Color(1.6, 1.5, 0.7)
const FIZZLE_FLASH := Color(0.45, 0.45, 0.5)
const FIZZLE_PUFF := Color(0.7, 0.7, 0.72)
const BOUNCE_PUFF := Color(1.0, 0.95, 0.6)

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("shield")
	var size := Vector2(GameConfig.SHIELD_WIDTH, GameConfig.SHIELD_THICKNESS)
	(shape.shape as RectangleShape2D).size = size
	Fx.fit_sprite(sprite, size)


func handle_projectile(p: Projectile) -> void:
	p.spent = true  # can't be handled twice in one frame
	if randf() < GameState.bounce_rate:
		_bounce(p)
	else:
		_fizzle(p)


func _bounce(p: Projectile) -> void:
	var half := GameConfig.SHIELD_WIDTH * 0.5
	var offset := clampf((p.global_position.x - global_position.x) / half, -1.0, 1.0)
	var normal := Vector2.UP.rotated(deg_to_rad(offset * GameConfig.SHIELD_MAX_TILT_DEG))
	var dir: Vector2 = p.velocity.bounce(normal).normalized()

	# Keep the returned shot going up and not too flat.
	var max_angle := deg_to_rad(GameConfig.RETURN_MAX_ANGLE_DEG)
	var from_up := clampf(Vector2.UP.angle_to(dir), -max_angle, max_angle)
	dir = Vector2.UP.rotated(from_up)

	# Aim assist toward the nearest living enemy.
	var target := _nearest_enemy(p.global_position)
	if target and GameState.aim_accuracy > 0.0:
		var to_enemy := (target.global_position - p.global_position).angle()
		dir = Vector2.from_angle(lerp_angle(dir.angle(), to_enemy, GameState.aim_accuracy))

	var speed: float = p.velocity.length() * GameConfig.BOUNCE_SPEED_MULT
	p.global_position.y = global_position.y - GameConfig.SHIELD_THICKNESS * 0.5 - GameConfig.PROJECTILE_RADIUS
	p.become_returned(dir * speed)
	p.spent = false
	Fx.flash(sprite, BOUNCE_FLASH, 0.2)
	Fx.puff(p.get_parent(), p.global_position, BOUNCE_PUFF, 34.0, 0.25)


func _fizzle(p: Projectile) -> void:
	Fx.flash(sprite, FIZZLE_FLASH, 0.3)
	Fx.puff(p.get_parent(), p.global_position, FIZZLE_PUFF, 30.0, 0.35)
	p.queue_free()


func _nearest_enemy(from: Vector2) -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in get_tree().get_nodes_in_group("enemy"):
		if not e.is_alive():
			continue
		var d := from.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
