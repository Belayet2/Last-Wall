extends CanvasLayer
## Side panels with wall HP, coins, enemies left, plus the center end-of-wave message.

signal restart_requested

@onready var wall_label: Label = %WallLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var coins_label: Label = %CoinsLabel
@onready var enemies_label: Label = %EnemiesLabel
@onready var bounce_label: Label = %BounceLabel
@onready var message: Control = %Message
@onready var message_title: Label = %MessageTitle
@onready var message_sub: Label = %MessageSub


func _ready() -> void:
	message.visible = false
	message.gui_input.connect(_on_message_input)
	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)
	bounce_label.text = "Bounce chance: %d%%" % roundi(GameState.bounce_rate * 100.0)


func set_wall_number(n: int) -> void:
	wall_label.text = "WALL %d" % n


func set_wall_hp(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [hp, max_hp]


func set_enemies_left(n: int) -> void:
	enemies_label.text = "Enemies left: %d" % n


func show_message(title: String, sub: String) -> void:
	message_title.text = title
	message_sub.text = sub
	message.visible = true


func _on_coins_changed(coins: int) -> void:
	coins_label.text = "Coins: %d" % coins


func _on_message_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		restart_requested.emit()
