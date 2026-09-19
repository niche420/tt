extends CanvasLayer

@onready var panel: Control = $Panel
@onready var message: Label = $Panel/VBoxContainer/Message
@onready var retry: Button = $Panel/VBoxContainer/RetryButton

func _ready() -> void:
	panel.visible = false
	GameManager.game_won.connect(_on_won)
	GameManager.game_lost.connect(_on_lost)
	retry.pressed.connect(GameManager.restart)

func _on_won() -> void:
	_show("You win! Off to Chuck E. Cheese!")

func _on_lost(reason: String) -> void:
	_show(reason)

func _show(text: String) -> void:
	message.text = text
	panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
