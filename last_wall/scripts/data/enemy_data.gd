class_name EnemyData
extends RefCounted
## Stats for every enemy type. Tune freely.
## size = on-screen size of the sprite (the PNG is scaled to fit).

const TYPES := {
	"thrower": {
		"max_hp": 3,
		"throw_interval": 2.8,
		"projectile_speed": 180.0,
		"damage": 10,           # wall damage of its shots
		"return_damage": 1,     # damage its shot does to enemies when bounced back
		"coin_reward": 5,
		"size": Vector2(56, 56),
	},
}
