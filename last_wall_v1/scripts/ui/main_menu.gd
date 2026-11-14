extends Node2D
## Start menu: the game world in the background, the title, Play and Quit.
## The Play click is also the first click the browser needs before it allows sound.

const GameScript = preload("res://scripts/game.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const WallScript = preload("res://scripts/wall.gd")
const HeroScript = preload("res://scripts/hero.gd")
const UI = preload("res://scripts/ui/ui_style.gd")


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameState.reset()

	# living backdrop: the world, the wall, the hero (you can walk him around), enemies on the ruins
	GameScript.build_world(self)
	var wall := WallScript.new()
	var layout := GameState.current_layout()          # the last layer, plus a few rows of bricks for show
	for col in range(layout.size()):
		var column: Array = layout[col]
		for type_key in ["stone", "clay", "clay" if col % 3 != 1 else "marble"]:
			column.append({"type": type_key, "hp": 1, "max": 1})
	wall.setup(layout, "foundation_1")
	add_child(wall)
	add_child(HeroScript.new())
	for x in [330.0, 640.0, 950.0]:
		var e := ArtData.make_sprite("enemy_cannon")           # idle frame, barrel toward the middle
		e.position = Vector2(x, GameData.ENEMY_Y)
		e.flip_h = x > GameData.FIELD_CENTER_X
		e.offset = Vector2(-7 if e.flip_h else 7, 0)
		add_child(e)

	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var col := VBoxContainer.new()
	col.position = Vector2(0, 170)
	col.size = Vector2(GameData.SCREEN_WIDTH, 380)
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var title := UI.centered(UI.world_label("LAST WALL", 104))
	col.add_child(title)
	col.add_child(UI.centered(UI.world_label("Bounce the stones back. Take the walls back.", 26)))
	col.add_child(UI.spacer(26))

	var play := UI.button("Play", true, Vector2(240, 56), 28)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_on_play)
	col.add_child(play)
	if not OS.has_feature("web"):
		var quit := UI.button("Quit", false, Vector2(240, 46), 22)
		quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		quit.pressed.connect(func() -> void: GameState.audio.quit_game())
		col.add_child(quit)
	play.grab_focus()

	var hint := UI.centered(UI.world_label("A / D or arrow keys to move     Esc to pause     M to mute", 18))
	hint.position = Vector2(0, 684)
	hint.size = Vector2(GameData.SCREEN_WIDTH, 30)
	root.add_child(hint)

	# the title gently floats
	var t := title.create_tween().set_loops()
	t.tween_property(title, "position:y", title.position.y - 6, 1.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(title, "position:y", title.position.y, 1.4).set_trans(Tween.TRANS_SINE)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/story.tscn")
