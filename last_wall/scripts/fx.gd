class_name Fx
extends RefCounted
## Tiny effect helpers (placeholder juice). Uses assets/sprites/puff.png.

const PUFF_TEXTURE := preload("res://assets/sprites/puff.png")


## Scales a sprite so its texture fills `target_size` on screen, whatever the PNG resolution.
static func fit_sprite(sprite: Sprite2D, target_size: Vector2) -> void:
	if sprite == null or sprite.texture == null:
		return
	var tex_size := sprite.texture.get_size()
	sprite.scale = target_size / tex_size


## A soft circle that grows and fades out.
static func puff(parent: Node, pos: Vector2, color: Color, size := 28.0, duration := 0.3) -> void:
	if parent == null:
		return
	var s := Sprite2D.new()
	s.texture = PUFF_TEXTURE
	s.modulate = color
	s.global_position = pos
	parent.add_child(s)
	s.global_position = pos
	fit_sprite(s, Vector2(size, size) * 0.5)
	var end_scale := s.scale * 2.0
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", end_scale, duration)
	tw.tween_property(s, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(s.queue_free)


## Briefly tints a node, then returns it to white.
static func flash(node: CanvasItem, color: Color, duration := 0.15) -> void:
	if node == null:
		return
	node.modulate = color
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color.WHITE, duration)
