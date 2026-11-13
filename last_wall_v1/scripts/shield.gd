extends Area2D
## The hero's round shield, held up in front of him (drawn behind his head).
## The thin golden arc over it is the shield's power, the AURA: every stone that
## touches the aura bounces (100%). Where it touches decides the angle, like a
## curved surface. Aim assist nudges the stone toward the nearest enemy.

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")

var catch_width := 140.0

var _sprite: Sprite2D
var _shape: CollisionShape2D
var _aura: Line2D
var _glow: Line2D
var _flash: Tween
var _nudge: Tween


func _ready() -> void:
	add_to_group("shield")
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	position = Vector2(0, GameData.SHIELD_CENTER_Y)
	_sprite = ArtData.make_sprite("shield")
	_sprite.z_index = -1
	add_child(_sprite)
	_glow = _make_line(GameData.AURA_GLOW_WIDTH, GameData.AURA_GLOW_ALPHA)
	_aura = _make_line(GameData.AURA_WIDTH, 1.0)
	_aura.modulate.a = GameData.AURA_ALPHA
	_shape = CollisionShape2D.new()
	add_child(_shape)
	set_catch_width(GameState.get_value("shield_width"))


func _make_line(line_width: float, alpha: float) -> Line2D:
	var line := Line2D.new()
	line.width = line_width
	line.z_index = 1
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var c := GameData.AURA_COLOR
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(c, 0.0), Color(c, alpha), Color(c, alpha), Color(c, 0.0)])
	line.gradient = g
	add_child(line)
	return line


## Width of the bounce zone (the Shield Aura upgrade makes it wider).
func set_catch_width(new_width: float) -> void:
	catch_width = new_width
	var rx := catch_width * 0.5
	var arc := PackedVector2Array()
	for i in range(GameData.AURA_POINTS + 1):
		var a := PI + PI * float(i) / GameData.AURA_POINTS
		arc.append(Vector2(cos(a) * rx, sin(a) * GameData.AURA_HEIGHT))
	_aura.points = arc
	_glow.points = arc
	var hull := arc.duplicate()
	hull.append(Vector2(rx, GameData.AURA_THICKNESS))
	hull.append(Vector2(-rx, GameData.AURA_THICKNESS))
	var poly := ConvexPolygonShape2D.new()
	poly.set_point_cloud(hull)
	_shape.shape = poly


func bounce_stone(stone) -> void:
	var stone_pos: Vector2 = stone.global_position
	var offset := clampf((stone_pos.x - global_position.x) / (catch_width * 0.5), -1.0, 1.0)
	var dir := Vector2.UP.rotated(deg_to_rad(offset * GameData.MAX_BOUNCE_ANGLE_DEG))
	var target := _nearest_enemy(stone_pos)
	if target != null:
		var to_enemy := (target.global_position - stone_pos).angle()
		dir = Vector2.from_angle(lerp_angle(dir.angle(), to_enemy, GameState.get_value("aim_assist")))
	var speed: float = stone.velocity.length() * GameData.RETURN_SPEED_MULT
	var surface_y := global_position.y - GameData.AURA_HEIGHT * sqrt(maxf(0.0, 1.0 - offset * offset))
	stone.global_position.y = minf(stone_pos.y, surface_y - float(stone.diameter) * 0.5)
	stone.make_returned(dir * speed)
	_flash_aura()
	GameState.audio.play("bounce")
	var fx := get_tree().get_first_node_in_group("fx")
	if fx:
		fx.burst(Vector2(stone_pos.x, surface_y), FxData.SPARKS, dir)
	if _nudge:
		_nudge.kill()
	_sprite.position.y = FxData.SHIELD_NUDGE
	_nudge = create_tween()
	_nudge.tween_property(_sprite, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _nearest_enemy(from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d := from.distance_squared_to((enemy as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _flash_aura() -> void:
	if _flash:
		_flash.kill()
	_aura.modulate = Color(1.6, 1.6, 1.6, 1.0)
	_glow.modulate = Color(2.0, 2.0, 2.0, 1.0)
	_flash = create_tween().set_parallel(true)
	_flash.tween_property(_aura, "modulate", Color(1, 1, 1, GameData.AURA_ALPHA), 0.25)
	_flash.tween_property(_glow, "modulate", Color.WHITE, 0.25)
