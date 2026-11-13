extends Node2D
## Moves left/right only, on a fixed Y. Has no health. Carries the shield.

@onready var sprite: Sprite2D = $Sprite2D
@onready var shield: Area2D = $Shield


func _ready() -> void:
	Fx.fit_sprite(sprite, GameConfig.HERO_SIZE)
	shield.position = Vector2(0, GameConfig.SHIELD_OFFSET_Y)
	position.y = GameConfig.HERO_Y


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	position.x += dir * GameState.move_speed * delta
	# Keep the whole shield inside the play field.
	var half := GameConfig.SHIELD_WIDTH * 0.5
	position.x = clampf(position.x, GameConfig.FIELD_LEFT + half, GameConfig.FIELD_RIGHT - half)
