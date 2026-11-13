extends Node
## Spawns the wave for a wall and reports when it is cleared.

signal enemy_threw(from: Vector2, dir: Vector2, speed: float, damage: int, return_damage: int)
signal enemies_left_changed(count: int)
signal wave_cleared

## Which scene to use for each enemy type name in LevelData.
const ENEMY_SCENES := {
	"thrower": preload("res://scenes/enemies/thrower.tscn"),
}

@export var enemy_parent: Node2D

var alive := 0


func spawn_wave(wall_number: int) -> void:
	var types: Array = LevelData.get_wall(wall_number)["enemies"]
	alive = types.size()
	var width := GameConfig.FIELD_RIGHT - GameConfig.FIELD_LEFT
	var spacing := width / float(types.size() + 1)
	for i in types.size():
		var enemy: Enemy = ENEMY_SCENES[types[i]].instantiate()
		enemy.position = Vector2(GameConfig.FIELD_LEFT + spacing * (i + 1), GameConfig.ENEMY_ROW_Y)
		enemy.threw.connect(enemy_threw.emit)
		enemy.died.connect(_on_enemy_died)
		enemy_parent.add_child(enemy)
	enemies_left_changed.emit(alive)


func _on_enemy_died(_enemy: Area2D, coin_reward: int) -> void:
	GameState.add_coins(coin_reward)
	alive -= 1
	enemies_left_changed.emit(alive)
	if alive <= 0:
		wave_cleared.emit()
