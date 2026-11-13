extends Node2D
# A thrown shot. Hostile = red, wobbles, hurts the wall. Returned = green, flies straight, hurts enemies.
# Moved by game.gd (step), which also does all collisions.

const D = preload("res://data.gd")

var vel := Vector2.ZERO
var radius := 8.0
var damage := 10
var heavy := false
var returned := false
var dead := false
var age := 0.0
var phase := 0.0


func setup(pos: Vector2, velocity: Vector2, dmg: int, r: float, is_heavy: bool) -> void:
	position = pos
	vel = velocity
	damage = dmg
	radius = r
	heavy = is_heavy
	phase = randf() * TAU


func step(delta: float) -> void:
	age += delta
	var move := vel
	if not returned: # gentle sideways sine curve
		move += vel.normalized().orthogonal() * sin(age * D.WOBBLE_FREQ + phase) * D.WOBBLE_AMP
	position += move * delta
	if age > D.PROJECTILE_LIFETIME:
		dead = true


func make_returned() -> void:
	returned = true
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, D.RETURNED_COLOR if returned else D.HOSTILE_COLOR)
