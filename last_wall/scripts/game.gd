extends Node2D
## The play field. Wires hero, wall, enemies, projectiles and HUD together with signals.

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

@onready var background: Sprite2D = $Background
@onready var wall: Area2D = $Wall
@onready var projectiles: Node2D = $Projectiles
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD

var _over := false


func _ready() -> void:
	get_tree().paused = false
	var field := Vector2(GameConfig.FIELD_RIGHT - GameConfig.FIELD_LEFT, GameConfig.FIELD_BOTTOM - GameConfig.FIELD_TOP)
	background.position = Vector2(GameConfig.FIELD_LEFT, GameConfig.FIELD_TOP) + field * 0.5
	Fx.fit_sprite(background, field)

	wall.hp_changed.connect(hud.set_wall_hp)
	wall.wall_fallen.connect(_on_wall_fallen)
	wave_manager.enemy_threw.connect(_spawn_projectile)
	wave_manager.enemies_left_changed.connect(hud.set_enemies_left)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	hud.restart_requested.connect(_restart)

	var level := LevelData.get_wall(GameState.current_wall)
	hud.set_wall_number(GameState.current_wall)
	wall.setup(level["max_hp"], level["max_hp"])
	wave_manager.spawn_wave(GameState.current_wall)


func _spawn_projectile(from: Vector2, dir: Vector2, speed: float, damage: int, return_damage: int) -> void:
	if _over:
		return
	var p: Projectile = PROJECTILE_SCENE.instantiate()
	projectiles.add_child(p)
	p.setup(from, dir, speed, damage, return_damage)


func _on_wave_cleared() -> void:
	if _over:
		return
	_over = true
	for p in projectiles.get_children():
		p.queue_free()
	hud.show_message("Wall Held!", "Click to play again")
	# Let the last enemy's pop animation finish before freezing the game.
	get_tree().create_timer(0.4).timeout.connect(_freeze)


func _freeze() -> void:
	get_tree().paused = true


func _on_wall_fallen() -> void:
	if _over:
		return
	_over = true
	hud.show_message("Wall Fell!", "Click to try again")
	get_tree().paused = true


func _restart() -> void:
	GameState.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
