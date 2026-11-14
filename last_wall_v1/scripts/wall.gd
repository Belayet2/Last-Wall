extends Node2D
## Our wall: a grid of bricks, like a brick-breaker game turned upside down.
## Every column is a stack: the last layer (foundation) at the bottom, the bricks you built on top.
## A hostile stone hits the TOP brick of its column. If a last-layer brick breaks, the wall falls.
## Build mode (before the fight): click a column to lay the selected brick on top, right-click to take the top one off.

signal wall_fallen
signal foundation_changed(hp: int, max_hp: int)   # the weakest brick of the last layer
signal layout_changed                               # a brick was laid or taken off (build mode)

const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")

var foundation_art := "foundation_1"
var selected_type := "clay"
var build_mode := false:
	set = set_build_mode

var _layout: Array = []             # per column: Array of brick dicts, bottom first
var _sprites: Array = []            # per column: Array of Sprite2D, same order
var _fallen := false
var _slots: Array[Sprite2D] = []    # build mode: the next free place in each column
var _labels: Array[Label] = []      # build mode: each column's total HP
var _danger: Array[ColorRect] = []  # build mode: red strip where enemies aim the most
var _ghost: Sprite2D
var _hover := -1
var _build_layer: Node2D


func setup(layout: Array, art_key: String) -> void:
	_layout = layout
	foundation_art = art_key


func _ready() -> void:
	add_to_group("wall")
	var bed := ArtData.make_sprite("path", Vector2(GameData.SCREEN_WIDTH, GameData.WALL_HEIGHT))
	bed.position = Vector2(GameData.FIELD_CENTER_X, GameData.WALL_TOP + GameData.WALL_HEIGHT * 0.5)
	bed.modulate = Color(0.7, 0.64, 0.58)
	bed.z_index = -5
	add_child(bed)
	for side in [0, 1]:                       # a tower of old stone at each end
		var x := BrickData.COLUMN_LEFT * 0.5 if side == 0 else GameData.SCREEN_WIDTH - BrickData.COLUMN_LEFT * 0.5
		for row in range(BrickData.ROWS):
			var s := ArtData.make_sprite(foundation_art, Vector2(BrickData.COLUMN_LEFT, BrickData.BRICK_H))
			s.position = Vector2(x, _row_y(row))
			s.modulate = Color(0.85, 0.85, 0.85)
			add_child(s)
	for col in range(BrickData.COLUMNS):
		var stack: Array[Sprite2D] = []
		_sprites.append(stack)
		var column: Array = _layout[col]
		for row in range(column.size()):
			stack.append(_make_brick_sprite(col, row, column[row]))
	_build_build_layer()
	build_mode = build_mode


# ---------------------------------------------------------------- fighting

## Which column a stone at `pos` hits, or -1 if it has not reached the wall yet.
func hit_column(pos: Vector2, radius: float) -> int:
	var col := clampi(floori((pos.x - BrickData.COLUMN_LEFT) / BrickData.BRICK_W), 0, BrickData.COLUMNS - 1)
	if pos.y + radius >= top_y(col):
		return col
	return -1


## A stone hit the top brick of `col`.
func damage(col: int, amount: int, hit_pos: Vector2) -> void:
	var column: Array = _layout[col]
	if column.is_empty() or _fallen:
		return
	var row := column.size() - 1
	var brick: Dictionary = column[row]
	brick["hp"] = maxi(int(brick["hp"]) - amount, 0)
	var sprite: Sprite2D = _sprites[col][row]
	var fx := get_tree().get_first_node_in_group("fx")
	if fx:
		fx.float_text(hit_pos + Vector2(0, -24), "-%d" % amount, FxData.DAMAGE_COLOR)
	if brick["hp"] > 0:
		_update_cracks(sprite, brick)
		_hit_wobble(sprite)
		if fx:
			fx.shake(FxData.SHAKE_WALL_HIT)
	else:
		_break_brick(col, fx)
	if row == 0:
		var weakest := weakest_foundation()
		foundation_changed.emit(weakest.x, weakest.y)
		if column.is_empty():
			_fallen = true
			wall_fallen.emit()


## The y where the top brick of `col` starts (stones stop here).
func top_y(col: int) -> float:
	var height: int = (_layout[col] as Array).size()
	return BrickData.BOTTOM - BrickData.BRICK_H * height


## (hp, max) of the weakest last-layer brick (hp 0 = there is a hole).
func weakest_foundation() -> Vector2i:
	var weakest := Vector2i(999999, 1)
	for column in _layout:
		if column.is_empty():
			return Vector2i(0, weakest.y)
		var base: Dictionary = column[0]
		weakest.y = base["max"]
		if int(base["hp"]) < weakest.x:
			weakest.x = base["hp"]
	return weakest


## Wave cleared: the bricks still standing are mended.
func heal_full() -> void:
	for col in range(BrickData.COLUMNS):
		var column: Array = _layout[col]
		for row in range(column.size()):
			column[row]["hp"] = column[row]["max"]
			var s: Sprite2D = _sprites[col][row]
			_update_cracks(s, column[row])
			s.modulate = Color(1.4, 1.35, 1.1)
			s.create_tween().tween_property(s, "modulate", Color.WHITE, 0.5)
	var weakest := weakest_foundation()
	foundation_changed.emit(weakest.x, weakest.y)


func get_layout() -> Array:
	return _layout.duplicate(true)


# ---------------------------------------------------------------- building

func set_build_mode(on: bool) -> void:
	build_mode = on
	if _build_layer:
		_build_layer.visible = on
		_refresh_build()


func column_height(col: int) -> int:
	return (_layout[col] as Array).size()


func column_hp(col: int) -> int:
	var total := 0
	for brick in _layout[col]:
		total += int(brick["hp"])
	return total


func is_full(col: int) -> bool:
	return column_height(col) >= BrickData.ROWS


## Lays a brick from the stock on top of `col`. Returns false if it can't.
func place(col: int, type_key: String) -> bool:
	if col < 0 or is_full(col) or not GameState.use_brick(type_key):
		return false
	var hp: int = BrickData.TYPES[type_key]["hp"]
	var brick := {"type": type_key, "hp": hp, "max": hp}
	(_layout[col] as Array).append(brick)
	var s := _make_brick_sprite(col, column_height(col) - 1, brick)
	(_sprites[col] as Array).append(s)
	var rest := s.position.y
	s.position.y -= BrickData.DROP_HEIGHT
	s.modulate.a = 0.0
	var drop := s.create_tween().set_parallel(true)
	drop.tween_property(s, "position:y", rest, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_property(s, "modulate:a", 1.0, 0.1)
	GameState.audio.play("repair")
	layout_changed.emit()
	_refresh_build()
	return true


## Takes the top brick of `col` back into the stock (never the last layer).
func take_off(col: int) -> bool:
	if col < 0 or column_height(col) <= 1:
		return false
	var brick: Dictionary = (_layout[col] as Array).pop_back()
	var s: Sprite2D = (_sprites[col] as Array).pop_back()
	GameState.return_brick(brick["type"])
	var pop := s.create_tween().set_parallel(true)
	pop.tween_property(s, "position:y", s.position.y - 14.0, 0.15)
	pop.tween_property(s, "modulate:a", 0.0, 0.15)
	pop.chain().tween_callback(s.queue_free)
	GameState.audio.play("click")
	layout_changed.emit()
	_refresh_build()
	return true


## Build screen: how hard the enemies hit each column (0..1), shown as a red strip.
func set_danger(values: Array) -> void:
	for col in range(mini(values.size(), _danger.size())):
		_danger[col].color.a = BrickData.DANGER_ALPHA_MAX * float(values[col])


func _unhandled_input(event: InputEvent) -> void:
	if not build_mode:
		return
	if event is InputEventMouseMotion:
		_set_hover(_column_at(get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed:
		var col := _column_at(get_global_mouse_position())
		if col < 0:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not place(col, selected_type):
				_nudge(col)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			take_off(col)
			get_viewport().set_input_as_handled()


## The column under the mouse (anywhere over the wall or just above it), or -1.
func _column_at(p: Vector2) -> int:
	var top := BrickData.BOTTOM - BrickData.BRICK_H * BrickData.ROWS - 40.0
	if p.y < top or p.y > BrickData.BOTTOM:
		return -1
	var col := floori((p.x - BrickData.COLUMN_LEFT) / BrickData.BRICK_W)
	return col if col >= 0 and col < BrickData.COLUMNS else -1


func _set_hover(col: int) -> void:
	_hover = col
	_refresh_ghost()


func select_type(type_key: String) -> void:
	selected_type = type_key
	_refresh_ghost()


func _refresh_build() -> void:
	if not _build_layer:
		return
	for col in range(BrickData.COLUMNS):
		var height := column_height(col)
		_slots[col].visible = height < BrickData.ROWS
		_slots[col].position = Vector2(_col_x(col), _row_y(mini(height, BrickData.ROWS - 1)))
		_labels[col].text = str(column_hp(col))
	_refresh_ghost()


func _refresh_ghost() -> void:
	if not _ghost:
		return
	var show := build_mode and _hover >= 0 and not is_full(_hover) and GameState.brick_count(selected_type) > 0
	_ghost.visible = show
	if show:
		ArtData.apply(_ghost, BrickData.TYPES[selected_type]["art"])
		_ghost.position = Vector2(_col_x(_hover), _row_y(column_height(_hover)))


## "Can't put a brick there" wiggle.
func _nudge(col: int) -> void:
	var stack: Array = _sprites[col]
	if stack.is_empty():
		return
	_hit_wobble(stack[stack.size() - 1])


func _build_build_layer() -> void:
	_build_layer = Node2D.new()
	_build_layer.z_index = 3
	add_child(_build_layer)
	for col in range(BrickData.COLUMNS):
		var strip := ColorRect.new()
		strip.color = Color(BrickData.DANGER_COLOR, 0.0)
		strip.position = Vector2(_col_x(col) - BrickData.BRICK_W * 0.5 + 1.0, GameData.WALL_TOP - 7.0)
		strip.size = Vector2(BrickData.BRICK_W - 2.0, 7.0)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_build_layer.add_child(strip)
		_danger.append(strip)
		var slot := ArtData.make_sprite("brick_slot", Vector2(BrickData.BRICK_W, BrickData.BRICK_H))
		_build_layer.add_child(slot)
		_slots.append(slot)
		var label := UI.centered(UI.world_label("", 14))
		label.add_theme_constant_override("outline_size", 5)
		label.size = Vector2(BrickData.BRICK_W, 20)
		label.position = Vector2(_col_x(col) - BrickData.BRICK_W * 0.5, GameData.WALL_TOP - 30.0)
		_build_layer.add_child(label)
		_labels.append(label)
	_ghost = Sprite2D.new()
	_ghost.modulate = Color(1, 1, 1, 0.6)
	_ghost.visible = false
	_build_layer.add_child(_ghost)


# ---------------------------------------------------------------- looks

func _make_brick_sprite(col: int, row: int, brick: Dictionary) -> Sprite2D:
	var art := foundation_art if brick["type"] == "foundation" else String(BrickData.TYPES[brick["type"]]["art"])
	var s := ArtData.make_sprite(art, Vector2(BrickData.BRICK_W, BrickData.BRICK_H))
	s.position = Vector2(_col_x(col), _row_y(row))
	var cracks := Sprite2D.new()
	cracks.name = "Cracks"
	cracks.visible = false
	s.add_child(cracks)
	add_child(s)
	_update_cracks(s, brick)
	return s


func _update_cracks(s: Sprite2D, brick: Dictionary) -> void:
	var cracks: Sprite2D = s.get_node("Cracks")
	var ratio := float(brick["hp"]) / float(brick["max"])
	if ratio >= BrickData.CRACK_1_BELOW:
		cracks.visible = false
		return
	cracks.visible = true
	var key := "brick_cracks_2" if ratio < BrickData.CRACK_2_BELOW else "brick_cracks_1"
	cracks.texture = ArtData.texture(key)
	cracks.scale = ArtData.size_of(key) / cracks.texture.get_size() / s.scale


func _hit_wobble(s: Sprite2D) -> void:
	var home_x := s.position.x
	s.modulate = FxData.WALL_HIT_FLASH
	var t := s.create_tween()
	t.tween_property(s, "position:x", home_x + FxData.WALL_JIGGLE, 0.04)
	t.tween_property(s, "position:x", home_x - FxData.WALL_JIGGLE, 0.06)
	t.tween_property(s, "position:x", home_x, 0.05)
	s.create_tween().tween_property(s, "modulate", Color.WHITE, 0.2)


func _break_brick(col: int, fx: Node) -> void:
	var brick: Dictionary = (_layout[col] as Array).pop_back()
	var s: Sprite2D = (_sprites[col] as Array).pop_back()
	var last_layer: bool = brick["type"] == "foundation"
	GameState.audio.play("wall_crack")
	if fx:
		var rubble: Dictionary = FxData.BRICK_RUBBLE.duplicate()
		rubble["color"] = FxData.WALL_RUBBLE["color"] if last_layer else BrickData.TYPES[brick["type"]]["color"]
		fx.burst(s.global_position, rubble)
		fx.shake(FxData.SHAKE_WALL_CRACK if last_layer else FxData.SHAKE_BRICK_BREAK)
	var fall := s.create_tween().set_parallel(true)
	fall.tween_property(s, "position:y", s.position.y + 10.0, 0.2)
	fall.tween_property(s, "rotation", randf_range(-0.4, 0.4), 0.2)
	fall.tween_property(s, "modulate:a", 0.0, 0.2)
	fall.chain().tween_callback(s.queue_free)


func _col_x(col: int) -> float:
	return BrickData.COLUMN_LEFT + BrickData.BRICK_W * (col + 0.5)


func _row_y(row: int) -> float:
	return BrickData.BOTTOM - BrickData.BRICK_H * (row + 0.5)
