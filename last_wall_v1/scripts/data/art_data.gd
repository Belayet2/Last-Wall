## Every sprite the game uses, its file, and the size it is drawn at.
## To replace art: overwrite the PNG with your own (same file name).
## Your image can be any size; it is scaled to "size" below.
## "frames" = the picture is a strip of that many frames side by side ("size" is one frame).

const SPRITES := {
	# hero (seen from behind) and his shield (drawn behind him)
	"hero": {"path": "res://assets/sprites/characters/hero.png", "size": Vector2(80, 104)},
	"shield": {"path": "res://assets/sprites/characters/shield.png", "size": Vector2(88, 72)},
	"shadow": {"path": "res://assets/sprites/characters/shadow.png", "size": Vector2(64, 16)},
	# stones
	"stone": {"path": "res://assets/sprites/shots/stone.png", "size": Vector2(22, 22)},
	"stone_returned": {"path": "res://assets/sprites/shots/stone_returned.png", "size": Vector2(28, 28)},
	# enemies (standing pose + windup pose)
	"enemy_cannon": {"path": "res://assets/sprites/characters/enemy_cannon.png", "size": Vector2(120, 60), "frames": 8},
	"enemy_slinger": {"path": "res://assets/sprites/characters/enemy_slinger.png", "size": Vector2(40, 48)},
	"enemy_slinger_windup": {"path": "res://assets/sprites/characters/enemy_slinger_windup.png", "size": Vector2(40, 48)},
	"enemy_catapult": {"path": "res://assets/sprites/characters/enemy_catapult.png", "size": Vector2(80, 64)},
	"enemy_catapult_windup": {"path": "res://assets/sprites/characters/enemy_catapult_windup.png", "size": Vector2(80, 64)},
	# world
	# our wall: a grid of bricks (see brick_data.gd). Each brick is drawn 64 x 22.
	"foundation_1": {"path": "res://assets/sprites/bricks/foundation_1.png", "size": Vector2(64, 22)},
	"foundation_2": {"path": "res://assets/sprites/bricks/foundation_2.png", "size": Vector2(64, 22)},
	"foundation_3": {"path": "res://assets/sprites/bricks/foundation_3.png", "size": Vector2(64, 22)},
	"foundation_4": {"path": "res://assets/sprites/bricks/foundation_4.png", "size": Vector2(64, 22)},
	"foundation_5": {"path": "res://assets/sprites/bricks/foundation_5.png", "size": Vector2(64, 22)},
	"brick_mud": {"path": "res://assets/sprites/bricks/brick_mud.png", "size": Vector2(64, 22)},
	"brick_clay": {"path": "res://assets/sprites/bricks/brick_clay.png", "size": Vector2(64, 22)},
	"brick_stone": {"path": "res://assets/sprites/bricks/brick_stone.png", "size": Vector2(64, 22)},
	"brick_marble": {"path": "res://assets/sprites/bricks/brick_marble.png", "size": Vector2(64, 22)},
	"brick_cracks_1": {"path": "res://assets/sprites/bricks/brick_cracks_1.png", "size": Vector2(64, 22)},
	"brick_cracks_2": {"path": "res://assets/sprites/bricks/brick_cracks_2.png", "size": Vector2(64, 22)},
	"brick_slot": {"path": "res://assets/sprites/bricks/brick_slot.png", "size": Vector2(64, 22)},
	"ground": {"path": "res://assets/sprites/world/ground.png", "size": Vector2(1280, 400)},
	"path": {"path": "res://assets/sprites/world/path.png", "size": Vector2(1280, 75)},
	# enemy side at the top: sky (walls 1-4, the broken wall in front of it is drawn from the bricks), the sea (wall 5)
	"sky": {"path": "res://assets/sprites/world/sky.png", "size": Vector2(1280, 150)},
	"sea": {"path": "res://assets/sprites/world/sea.png", "size": Vector2(1280, 150)},
	"beach": {"path": "res://assets/sprites/world/beach.png", "size": Vector2(1280, 400)},
	# boss
	"ship": {"path": "res://assets/sprites/characters/ship.png", "size": Vector2(252, 140)},
	"cannonball": {"path": "res://assets/sprites/shots/cannonball.png", "size": Vector2(22, 22)},
	# end screens (the story scenes are drawn in the game from these pictures and the bricks)
	"story_throne_room": {"path": "res://assets/sprites/screens/story_throne_room.png", "size": Vector2(1280, 720)},
	"portrait_king": {"path": "res://assets/sprites/screens/portrait_king.png", "size": Vector2(288, 336)},
	"portrait_commander": {"path": "res://assets/sprites/screens/portrait_commander.png", "size": Vector2(288, 336)},
	# HUD icons
	"icon_wall": {"path": "res://assets/sprites/ui/icon_wall.png", "size": Vector2(28, 28)},
	"icon_coin": {"path": "res://assets/sprites/ui/icon_coin.png", "size": Vector2(32, 32)},
	"coin_spin": {"path": "res://assets/sprites/ui/coin_spin.png", "size": Vector2(32, 32), "frames": 10},
	"icon_cannon": {"path": "res://assets/sprites/ui/icon_cannon.png", "size": Vector2(37, 26)},
	"icon_slinger": {"path": "res://assets/sprites/ui/icon_slinger.png", "size": Vector2(26, 26)},
	"icon_catapult": {"path": "res://assets/sprites/ui/icon_catapult.png", "size": Vector2(30, 26)},
}


static func texture(key: String) -> Texture2D:
	var info: Dictionary = SPRITES[key]
	return load(info["path"])


static func size_of(key: String) -> Vector2:
	var info: Dictionary = SPRITES[key]
	return info["size"]


## How many frames the picture has (1 = a normal picture).
static func frames_of(key: String) -> int:
	var info: Dictionary = SPRITES[key]
	return int(info.get("frames", 1))


## Makes a Sprite2D showing `key`. Pass `draw_size` to override the size.
static func make_sprite(key: String, draw_size: Vector2 = Vector2.ZERO) -> Sprite2D:
	var sprite := Sprite2D.new()
	apply(sprite, key, draw_size)
	return sprite


## Sets the texture of `sprite` to `key` and scales it to the target size.
static func apply(sprite: Sprite2D, key: String, draw_size: Vector2 = Vector2.ZERO) -> void:
	var tex := texture(key)
	var frames := frames_of(key)
	sprite.texture = tex
	sprite.hframes = frames
	var target := size_of(key) if draw_size == Vector2.ZERO else draw_size
	sprite.scale = target / (tex.get_size() / Vector2(frames, 1))
