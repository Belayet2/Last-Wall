## Every sprite the game uses, its file, and the size it is drawn at.
## To replace art: overwrite the PNG with your own (same file name).
## Your image can be any size; it is scaled to "size" below.

const SPRITES := {
	# hero (seen from behind) and his shield (drawn behind him)
	"hero": {"path": "res://assets/sprites/hero.png", "size": Vector2(80, 104)},
	"shield": {"path": "res://assets/sprites/shield.png", "size": Vector2(88, 72)},
	"shadow": {"path": "res://assets/sprites/shadow.png", "size": Vector2(64, 16)},
	# stones
	"stone": {"path": "res://assets/sprites/stone.png", "size": Vector2(22, 22)},
	"stone_returned": {"path": "res://assets/sprites/stone_returned.png", "size": Vector2(28, 28)},
	# enemies (standing pose + windup pose)
	"enemy_thrower": {"path": "res://assets/sprites/enemy_thrower.png", "size": Vector2(48, 56)},
	"enemy_thrower_windup": {"path": "res://assets/sprites/enemy_thrower_windup.png", "size": Vector2(48, 56)},
	"enemy_slinger": {"path": "res://assets/sprites/enemy_slinger.png", "size": Vector2(40, 48)},
	"enemy_slinger_windup": {"path": "res://assets/sprites/enemy_slinger_windup.png", "size": Vector2(40, 48)},
	"enemy_catapult": {"path": "res://assets/sprites/enemy_catapult.png", "size": Vector2(80, 64)},
	"enemy_catapult_windup": {"path": "res://assets/sprites/enemy_catapult_windup.png", "size": Vector2(80, 64)},
	# world
	# our wall: 5 different walls x 3 looks
	"wall_1_whole": {"path": "res://assets/sprites/wall_1_whole.png", "size": Vector2(1280, 95)},
	"wall_1_cracked": {"path": "res://assets/sprites/wall_1_cracked.png", "size": Vector2(1280, 95)},
	"wall_1_broken": {"path": "res://assets/sprites/wall_1_broken.png", "size": Vector2(1280, 95)},
	"wall_2_whole": {"path": "res://assets/sprites/wall_2_whole.png", "size": Vector2(1280, 95)},
	"wall_2_cracked": {"path": "res://assets/sprites/wall_2_cracked.png", "size": Vector2(1280, 95)},
	"wall_2_broken": {"path": "res://assets/sprites/wall_2_broken.png", "size": Vector2(1280, 95)},
	"wall_3_whole": {"path": "res://assets/sprites/wall_3_whole.png", "size": Vector2(1280, 95)},
	"wall_3_cracked": {"path": "res://assets/sprites/wall_3_cracked.png", "size": Vector2(1280, 95)},
	"wall_3_broken": {"path": "res://assets/sprites/wall_3_broken.png", "size": Vector2(1280, 95)},
	"wall_4_whole": {"path": "res://assets/sprites/wall_4_whole.png", "size": Vector2(1280, 95)},
	"wall_4_cracked": {"path": "res://assets/sprites/wall_4_cracked.png", "size": Vector2(1280, 95)},
	"wall_4_broken": {"path": "res://assets/sprites/wall_4_broken.png", "size": Vector2(1280, 95)},
	"wall_5_whole": {"path": "res://assets/sprites/wall_5_whole.png", "size": Vector2(1280, 95)},
	"wall_5_cracked": {"path": "res://assets/sprites/wall_5_cracked.png", "size": Vector2(1280, 95)},
	"wall_5_broken": {"path": "res://assets/sprites/wall_5_broken.png", "size": Vector2(1280, 95)},
	"ground": {"path": "res://assets/sprites/ground.png", "size": Vector2(1280, 400)},
	"path": {"path": "res://assets/sprites/path.png", "size": Vector2(1280, 75)},
	# enemy side at the top: the next wall in ruins (walls 1-4), the sea (wall 5)
	"ruins_1": {"path": "res://assets/sprites/ruins_1.png", "size": Vector2(1280, 150)},
	"ruins_2": {"path": "res://assets/sprites/ruins_2.png", "size": Vector2(1280, 150)},
	"ruins_3": {"path": "res://assets/sprites/ruins_3.png", "size": Vector2(1280, 150)},
	"ruins_4": {"path": "res://assets/sprites/ruins_4.png", "size": Vector2(1280, 150)},
	"sea": {"path": "res://assets/sprites/sea.png", "size": Vector2(1280, 150)},
	"beach": {"path": "res://assets/sprites/beach.png", "size": Vector2(1280, 400)},
	# boss
	"ship": {"path": "res://assets/sprites/ship.png", "size": Vector2(252, 140)},
	"cannonball": {"path": "res://assets/sprites/cannonball.png", "size": Vector2(24, 24)},
	"edge_rocks": {"path": "res://assets/sprites/edge_rocks.png", "size": Vector2(40, 475)},
	"marker": {"path": "res://assets/sprites/marker.png", "size": Vector2(56, 18)},
	# story and end screens (drawn small, shown big)
	"story_map": {"path": "res://assets/sprites/story_map.png", "size": Vector2(1280, 720)},
	"story_kings": {"path": "res://assets/sprites/story_kings.png", "size": Vector2(1280, 720)},
	"story_field": {"path": "res://assets/sprites/story_field.png", "size": Vector2(1280, 720)},
	"story_ships": {"path": "res://assets/sprites/story_ships.png", "size": Vector2(1280, 720)},
	"story_map_fallen": {"path": "res://assets/sprites/story_map_fallen.png", "size": Vector2(1280, 720)},
	"story_king_calls": {"path": "res://assets/sprites/story_king_calls.png", "size": Vector2(1280, 720)},
	"story_hero": {"path": "res://assets/sprites/story_hero.png", "size": Vector2(1280, 720)},
	"story_throne_room": {"path": "res://assets/sprites/story_throne_room.png", "size": Vector2(1280, 720)},
	"portrait_king": {"path": "res://assets/sprites/portrait_king.png", "size": Vector2(288, 336)},
	"portrait_commander": {"path": "res://assets/sprites/portrait_commander.png", "size": Vector2(288, 336)},
	"portrait_messenger": {"path": "res://assets/sprites/portrait_messenger.png", "size": Vector2(288, 336)},
	# HUD icons
	"icon_wall": {"path": "res://assets/sprites/icon_wall.png", "size": Vector2(28, 28)},
	"icon_coin": {"path": "res://assets/sprites/icon_coin.png", "size": Vector2(26, 26)},
	"icon_enemy": {"path": "res://assets/sprites/icon_enemy.png", "size": Vector2(26, 26)},
	"icon_slinger": {"path": "res://assets/sprites/icon_slinger.png", "size": Vector2(26, 26)},
	"icon_catapult": {"path": "res://assets/sprites/icon_catapult.png", "size": Vector2(30, 26)},
}


static func texture(key: String) -> Texture2D:
	var info: Dictionary = SPRITES[key]
	return load(info["path"])


static func size_of(key: String) -> Vector2:
	var info: Dictionary = SPRITES[key]
	return info["size"]


## Makes a Sprite2D showing `key`. Pass `draw_size` to override the size.
static func make_sprite(key: String, draw_size: Vector2 = Vector2.ZERO) -> Sprite2D:
	var sprite := Sprite2D.new()
	apply(sprite, key, draw_size)
	return sprite


## Sets the texture of `sprite` to `key` and scales it to the target size.
static func apply(sprite: Sprite2D, key: String, draw_size: Vector2 = Vector2.ZERO) -> void:
	var tex := texture(key)
	sprite.texture = tex
	var target := size_of(key) if draw_size == Vector2.ZERO else draw_size
	sprite.scale = target / tex.get_size()
