extends Area2D
## A thrown stone. Hostile stones hurt the wall; returned (gold) stones hurt enemies.

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const FxScript = preload("res://scripts/fx.gd")

const LAYER_SHIELD := 1
const LAYER_HOSTILE := 2
const LAYER_RETURNED := 4
const LAYER_ENEMY := 8
const LAYER_WALL := 16

var velocity := Vector2.ZERO
var returned := false
var wall_damage := 0
var return_damage := 1
var diameter := 20.0
var marker: Node2D = null   # landing marker, removed when the stone is bounced or gone
var art := "stone"          # picture while hostile ("cannonball" for the boss)

var _life := 0.0
var _gone := false
var _sprite: Sprite2D
var _fx: Node


func setup(start: Vector2, start_velocity: Vector2, stone_diameter: float, damage_to_wall: int, damage_to_enemy: int) -> void:
	position = start
	velocity = start_velocity
	diameter = stone_diameter
	wall_damage = damage_to_wall
	return_damage = damage_to_enemy


func _ready() -> void:
	add_to_group("stones")
	add_to_group("threat")
	collision_layer = LAYER_HOSTILE
	collision_mask = LAYER_SHIELD | LAYER_WALL
	monitorable = false
	var circle := CircleShape2D.new()
	circle.radius = diameter * 0.5
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)
	_sprite = ArtData.make_sprite(art, Vector2(diameter, diameter))
	add_child(_sprite)
	area_entered.connect(_on_area_entered)
	_fx = get_tree().get_first_node_in_group("fx")


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_sprite.rotation += GameData.STONE_SPIN * delta
	var r := diameter * 0.5
	if position.x < GameData.FIELD_LEFT + r:
		position.x = GameData.FIELD_LEFT + r
		velocity.x = absf(velocity.x)
		_puff(Vector2(GameData.FIELD_LEFT, position.y), FxData.SMALL_DUST)
		GameState.audio.play("tap")
	elif position.x > GameData.FIELD_RIGHT - r:
		position.x = GameData.FIELD_RIGHT - r
		velocity.x = -absf(velocity.x)
		_puff(Vector2(GameData.FIELD_RIGHT, position.y), FxData.SMALL_DUST)
		GameState.audio.play("tap")
	_life += delta
	if _life > GameData.STONE_LIFETIME or position.y < -40.0 or position.y > 760.0:
		remove()


func _on_area_entered(area) -> void:
	if _gone:
		return
	if returned:
		if area.is_in_group("enemies"):
			area.take_damage(return_damage + int(GameState.get_value("stone_power")))
			_puff(global_position, FxData.GOLD_CHIPS)
			remove()
	elif area.is_in_group("shield"):
		area.bounce_stone(self)
	elif area.is_in_group("wall"):
		area.take_damage(wall_damage, global_position)
		GameState.audio.play("wall_hit")
		_puff(global_position, FxData.DUST)
		remove()


## Called by the shield. The stone now belongs to the player.
func make_returned(new_velocity: Vector2) -> void:
	returned = true
	velocity = new_velocity
	remove_from_group("threat")
	_clear_marker()
	set_deferred("collision_layer", LAYER_RETURNED)
	set_deferred("collision_mask", LAYER_ENEMY)
	ArtData.apply(_sprite, "stone_returned", Vector2(diameter, diameter) * 1.25)
	if FxData.TRAIL["amount"] > 0:
		add_child(FxScript.make_trail(FxData.TRAIL))


func remove() -> void:
	if _gone:
		return
	_gone = true
	_clear_marker()
	queue_free()


## Breaks the stone into dust (used when a wave ends).
func shatter() -> void:
	_puff(global_position, FxData.DUST)
	remove()


func _puff(pos: Vector2, preset: Dictionary) -> void:
	if is_instance_valid(_fx):
		_fx.burst(pos, preset)


func _clear_marker() -> void:
	if is_instance_valid(marker):
		marker.queue_free()
	marker = null
