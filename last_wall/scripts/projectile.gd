class_name Projectile
extends Area2D
## A thrown rock. HOSTILE: flies at the wall. RETURNED: bounced by the shield, hurts enemies.
## Moved manually with a velocity vector (no RigidBody2D).

enum State { HOSTILE, RETURNED }

# Collision layer bits (see Project Settings > Layer Names > 2D Physics).
const L_SHIELD := 1
const L_HOSTILE := 2
const L_RETURNED := 4
const L_ENEMY := 8
const L_WALL := 16
const L_OBSTACLE := 32

@export var hostile_texture: Texture2D
@export var returned_texture: Texture2D

var state := State.HOSTILE
var velocity := Vector2.ZERO
var damage := 10          # damage to the wall while hostile
var return_damage := 1    # damage to an enemy once returned
var spent := false        # true once it hit something (stops double hits)
var _age := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	(shape.shape as CircleShape2D).radius = GameConfig.PROJECTILE_RADIUS
	_apply_state_look()
	area_entered.connect(_on_area_entered)


func setup(from: Vector2, dir: Vector2, speed: float, wall_damage: int, enemy_damage: int) -> void:
	global_position = from
	velocity = dir.normalized() * speed
	damage = wall_damage
	return_damage = enemy_damage


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_bounce_off_side_edges()

	_age += delta
	var off_screen := global_position.y < GameConfig.FIELD_TOP - 40.0 \
		or global_position.y > GameConfig.FIELD_BOTTOM + 40.0
	if _age > GameConfig.PROJECTILE_LIFETIME or off_screen:
		queue_free()


func _bounce_off_side_edges() -> void:
	var r := GameConfig.PROJECTILE_RADIUS
	if global_position.x - r < GameConfig.FIELD_LEFT and velocity.x < 0.0:
		velocity = velocity.bounce(Vector2.RIGHT)
		global_position.x = GameConfig.FIELD_LEFT + r
	elif global_position.x + r > GameConfig.FIELD_RIGHT and velocity.x > 0.0:
		velocity = velocity.bounce(Vector2.LEFT)
		global_position.x = GameConfig.FIELD_RIGHT - r


## Called by the shield after a successful bounce.
func become_returned(new_velocity: Vector2) -> void:
	state = State.RETURNED
	velocity = new_velocity
	_age = 0.0
	set_deferred("collision_layer", L_RETURNED)
	set_deferred("collision_mask", L_ENEMY | L_OBSTACLE)
	_apply_state_look()


func _apply_state_look() -> void:
	if state == State.HOSTILE:
		collision_layer = L_HOSTILE
		collision_mask = L_SHIELD | L_WALL | L_OBSTACLE
		sprite.texture = hostile_texture
	else:
		sprite.texture = returned_texture
	var d := GameConfig.PROJECTILE_RADIUS * 2.0
	Fx.fit_sprite(sprite, Vector2(d, d))


func _on_area_entered(area: Area2D) -> void:
	if spent:
		return
	if state == State.HOSTILE:
		if area.is_in_group("shield"):
			area.handle_projectile(self)
		elif area.is_in_group("wall"):
			spent = true
			area.take_damage(damage, global_position)
			queue_free()
	else:
		if area.is_in_group("enemy") and area.is_alive():
			spent = true
			area.take_hit(return_damage)
			Fx.puff(get_parent(), global_position, Color(1.0, 0.85, 0.4), 30.0)
			queue_free()
