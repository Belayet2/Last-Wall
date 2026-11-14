extends SceneTree
## Cuts the downloaded cannon and coin sheets into the game's sprites.
## Run from the project folder:
##   godot --headless --path . --script res://tools/make_cannon_coin_art.gd -- --cannon=<cannon_spritesheet.png> --coin=<coin_Sheet.png>
##
## Makes:
##   enemy_cannon.png  = 8 frames side by side (60 x 30 each): idle, loading, fire + smoke, smoke fading
##   icon_cannon.png   = HUD icon (one cannon)
##   cannonball.png    = the ball from the sheet (cannons and the boss fire it)
##   coin_spin.png     = 10 frames side by side (16 x 16 each): a spinning coin
##   icon_coin.png     = the first coin frame

const OUT := "res://assets/sprites/"
const ArtData = preload("res://scripts/data/art_data.gd")
const CANNON_ROW := Rect2i(0, 80, 480, 30)      # the firing animation row of the sheet
const CANNON_ICON := Rect2i(2, 2, 37, 26)       # first cannon of the top row
const BALL_AREA := Rect2i(364, 32, 16, 44)      # the cannonball in the middle row


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cannon="):
			_cannon(Image.load_from_file(arg.substr(9)))
		elif arg.begins_with("--coin="):
			_coin(Image.load_from_file(arg.substr(7)))
	quit()


func _cannon(sheet: Image) -> void:
	sheet.convert(Image.FORMAT_RGBA8)
	_save(sheet.get_region(CANNON_ROW), "enemy_cannon")
	_save(sheet.get_region(CANNON_ICON), "icon_cannon")
	var ball := sheet.get_region(BALL_AREA)
	_save(ball.get_region(ball.get_used_rect()), "cannonball")


func _coin(sheet: Image) -> void:
	sheet.convert(Image.FORMAT_RGBA8)
	_save(sheet, "coin_spin")
	var h := sheet.get_height()
	_save(sheet.get_region(Rect2i(0, 0, h, h)), "icon_coin")


func _save(img: Image, key: String) -> void:
	img.save_png(ProjectSettings.globalize_path(_path_of(key)))
	print("saved ", key, " ", img.get_size())

## Where a picture lives (its path in scripts/data/art_data.gd); makes the folder if needed.
func _path_of(key: String) -> String:
	var path := OUT + key + ".png"
	if ArtData.SPRITES.has(key):
		path = ArtData.SPRITES[key]["path"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return path
