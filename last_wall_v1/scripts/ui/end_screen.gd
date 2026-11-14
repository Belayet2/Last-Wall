extends Control
## Win / lose screen (reads GameState.last_result). Throne room, a portrait, the narrator's closing line
## and a few stats.

const StoryData = preload("res://scripts/data/story_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var won := GameState.last_result == "win"
	var info: Dictionary = StoryData.WIN if won else StoryData.LOSE
	GameState.audio.play("victory" if won else "defeat")

	var bg := TextureRect.new()
	bg.texture = ArtData.texture("story_throne_room")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var portrait := TextureRect.new()
	portrait.texture = ArtData.texture(info["portrait"])
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.size = ArtData.size_of(info["portrait"])
	portrait.position = Vector2(120, 720 - portrait.size.y)
	add_child(portrait)

	var panel := UI.panel(34, 24, true)
	panel.position = Vector2(520, 150)
	add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(600, 0)
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(UI.label(info["title"], 64, UI.ACCENT))
	var quote := UI.label(info["text"], 24)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.custom_minimum_size = Vector2(600, 0)
	col.add_child(quote)
	col.add_child(UI.spacer(6))
	col.add_child(UI.label("Enemies defeated:  %d" % GameState.enemies_defeated, 20))
	col.add_child(UI.label("Coins earned:  %d" % GameState.coins_earned, 20))
	col.add_child(UI.label("Times you bounced back:  %d" % GameState.falls, 20))
	col.add_child(UI.spacer(10))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var first: Button
	if won:
		first = UI.button("Main Menu", true)
		first.pressed.connect(_to_menu)
		row.add_child(first)
		var again := UI.button("Play again", false)
		again.pressed.connect(_play_again)
		row.add_child(again)
	else:
		first = UI.button("Try again", true)
		first.pressed.connect(_play_again)
		row.add_child(first)
		var menu := UI.button("Main Menu", false)
		menu.pressed.connect(_to_menu)
		row.add_child(menu)
	first.grab_focus()


func _play_again() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
