## Every sprite the game uses, its file, and the size it is drawn at.
## To replace art: overwrite the PNG with your own (same file name).
## Your image can be any size; it is scaled to "size" below.

const SPRITES := {
	"hero": {"path": "res://assets/sprites/hero.png", "size": Vector2(48, 64)},
	"shield": {"path": "res://assets/sprites/shield.png", "size": Vector2(150, 24)},
	"stone": {"path": "res://assets/sprites/stone.png", "size": Vector2(20, 20)},
	"stone_returned": {"path": "res://assets/sprites/stone_returned.png", "size": Vector2(24, 24)},
	"enemy_thrower": {"path": "res://assets/sprites/enemy_thrower.png", "size": Vector2(48, 56)},
	"enemy_slinger": {"path": "res://assets/sprites/enemy_slinger.png", "size": Vector2(40, 48)},
	"enemy_catapult": {"path": "res://assets/sprites/enemy_catapult.png", "size": Vector2(80, 64)},
	"wall_whole": {"path": "res://assets/sprites/wall_whole.png", "size": Vector2(760, 95)},
	"wall_cracked": {"path": "res://assets/sprites/wall_cracked.png", "size": Vector2(760, 95)},
	"wall_broken": {"path": "res://assets/sprites/wall_broken.png", "size": Vector2(760, 95)},
	"ground": {"path": "res://assets/sprites/ground.png", "size": Vector2(760, 400)},
	"path": {"path": "res://assets/sprites/path.png", "size": Vector2(760, 75)},
	"ruins": {"path": "res://assets/sprites/ruins.png", "size": Vector2(760, 150)},
	"side_panel": {"path": "res://assets/sprites/side_panel.png", "size": Vector2(260, 720)},
	"marker": {"path": "res://assets/sprites/marker.png", "size": Vector2(48, 16)},
}


## Makes a Sprite2D showing `key`. Pass `draw_size` to override the size.
static func make_sprite(key: String, draw_size: Vector2 = Vector2.ZERO) -> Sprite2D:
	var sprite := Sprite2D.new()
	apply(sprite, key, draw_size)
	return sprite


## Sets the texture of `sprite` to `key` and scales it to the target size.
static func apply(sprite: Sprite2D, key: String, draw_size: Vector2 = Vector2.ZERO) -> void:
	var info: Dictionary = SPRITES[key]
	var tex: Texture2D = load(info["path"])
	sprite.texture = tex
	var target: Vector2 = info["size"] if draw_size == Vector2.ZERO else draw_size
	sprite.scale = target / tex.get_size()
