extends Node
# Screen flow: title -> story (3 screens) -> game <-> shop -> win / lose.

const D = preload("res://data.gd")
const Game = preload("res://game.gd")

const STORY := [
	"The commander speaks to the king:\n\n\"The war is over. We won.\nBut most of our soldiers did not come home.\"",
	"A messenger runs in:\n\n\"My king, ships are coming from the sea.\nMore of them than before.\"",
	"\"Every wall has fallen. There is no army left.\n...Call the hero.\"",
]

var ui: CanvasLayer
var screen: Control = null
var game: Game = null
var pause_label: Label
var story_index := 0
var shop_target := 1
var shop_header := ""
var shop_info: Label
var shop_buttons := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # so Esc works while paused
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	pause_label = Label.new()
	pause_label.text = "PAUSED\nPress Esc to resume"
	pause_label.add_theme_font_size_override("font_size", 40)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui.add_child(pause_label)
	pause_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_label.visible = false
	show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game != null:
		get_tree().paused = not get_tree().paused
		pause_label.visible = get_tree().paused


# ---------- Screens ----------

func show_title() -> void:
	var box := _center_box(_new_screen())
	_add_label(box, "LAST WALL", 64)
	_add_label(box, "Bounce the enemy shots back with your shield.", 22)
	_add_button(box, "Click to Start", _on_start)


func _on_start() -> void:
	story_index = 0
	_show_story()


func _show_story() -> void:
	if story_index >= STORY.size():
		GameState.reset()
		_start_game()
		return
	var panel := _new_screen()
	panel.gui_input.connect(_on_story_input)
	var box := _center_box(panel)
	_add_label(box, STORY[story_index], 30)
	_add_label(box, "\n(click to continue)", 18)


func _on_story_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_next_story()


func _next_story() -> void:
	story_index += 1
	_show_story()


func _start_game() -> void:
	_clear_screen()
	get_tree().paused = false
	game = Game.new()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.finished.connect(_on_wave_finished)
	add_child(game)


# The "Bounce Back" loop: hold -> advance, fall -> retreat.
func _on_wave_finished(held: bool) -> void:
	var cur: int = GameState.current_wall
	game.queue_free()
	game = null
	if held:
		GameState.wall_hp[cur - 1] = GameState.wall_max(cur) # retaking heals to 100%
		var bonus := D.RETAKE_BONUS_PER_WALL * cur
		GameState.add_coins(bonus)
		if cur == D.LEVELS.size():
			_show_end(true)
			return
		shop_target = cur + 1
		shop_header = "Wall %d held! Retake bonus: +%d coins.\nNext: push out to Wall %d." % [cur, bonus, shop_target]
	else:
		GameState.wall_hp[cur - 1] = 0
		if cur == 1:
			_show_end(false)
			return
		shop_target = cur - 1
		shop_header = "Wall %d fell!\nBounce back and defend Wall %d." % [cur, shop_target]
	if GameState.wall_hp[shop_target - 1] <= 0: # a fallen wall starts with some free HP
		GameState.wall_hp[shop_target - 1] = mini(D.FREE_WALL_HP, GameState.wall_max(shop_target))
	_show_shop()


func _show_shop() -> void:
	var box := _center_box(_new_screen())
	_add_label(box, "SHOP", 48)
	_add_label(box, shop_header, 22)
	shop_info = _add_label(box, "", 22)
	shop_buttons.clear()
	for key in D.SHOP:
		shop_buttons[key] = _add_button(box, "", _buy.bind(key))
	shop_buttons["repair"] = _add_button(box, "", _buy_repair)
	_add_button(box, "Continue", _on_shop_continue)
	_refresh_shop()


func _buy(key: String) -> void:
	GameState.buy_upgrade(key)
	_refresh_shop()


func _buy_repair() -> void:
	GameState.buy_repair(shop_target)
	_refresh_shop()


func _refresh_shop() -> void:
	var hp: int = GameState.wall_hp[shop_target - 1]
	var max_hp: int = GameState.wall_max(shop_target)
	shop_info.text = "Coins: %d        Wall %d HP: %d / %d" % [GameState.coins, shop_target, hp, max_hp]
	for key in D.SHOP:
		var b: Button = shop_buttons[key]
		var lvl: int = GameState.levels[key]
		var cost := GameState.upgrade_cost(key)
		var txt := "%s   Lv %d/%d   (now: %s)" % [D.SHOP[key]["name"], lvl, D.SHOP[key]["costs"].size(), _value_text(key)]
		if cost < 0:
			b.text = txt + "   MAX"
			b.disabled = true
		else:
			b.text = txt + "   cost %d" % cost
			b.disabled = GameState.coins < cost
	var repair: Button = shop_buttons["repair"]
	var rcost: int = GameState.repair_cost()
	repair.text = "Repair Wall %d   +%d HP   cost %d" % [shop_target, D.REPAIR_HP, rcost]
	repair.disabled = hp >= max_hp or GameState.coins < rcost


func _value_text(key: String) -> String:
	match key:
		"bounce":
			return "%d%%" % roundi(GameState.bounce_rate() * 100.0)
		"speed":
			return "%d" % roundi(GameState.move_speed())
		"aim":
			return "%.2f" % GameState.aim_accuracy()
	return "+%d max HP" % int(GameState.levels["reinforce"] * GameState.step("reinforce"))


func _on_shop_continue() -> void:
	GameState.current_wall = shop_target
	_start_game()


func _show_end(won: bool) -> void:
	var box := _center_box(_new_screen())
	_add_label(box, "The sea is quiet. The kingdom is saved." if won else "The last wall has fallen.", 36)
	_add_button(box, "Play Again" if won else "Try Again", _on_try_again)


func _on_try_again() -> void:
	GameState.reset()
	_start_game()


# ---------- UI helpers ----------

func _clear_screen() -> void:
	if screen != null:
		screen.queue_free()
		screen = null


func _new_screen() -> ColorRect:
	_clear_screen()
	var panel := ColorRect.new()
	panel.color = Color(0.07, 0.09, 0.14)
	ui.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen = panel
	return panel


func _center_box(parent: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	return box


func _add_label(box: Control, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	box.add_child(l)
	return l


func _add_button(box: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(560, 44)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(on_press)
	box.add_child(b)
	return b
