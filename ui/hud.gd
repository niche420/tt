# hud.gd
extends CanvasLayer

@export var ray: RayCast3D
@export var player_stamina: Stamina

@onready var prompt: Label = $CenterContainer/VBoxContainer/PromptLabel
@onready var player_bar: ProgressBar = $PlayerStamina
@onready var mom_bar: ProgressBar = $MomStamina
@onready var list_label: RichTextLabel = $ShoppingList
@onready var ammo_label: Label = $AmmoLabel
@onready var struggle_label: Label = $StruggleLabel

@onready var angry_overlay: TextureRect = $AngryOverlay

func _on_ammo_changed(ammo: int) -> void:
	ammo_label.visible = true
	ammo_label.text = "Darts: %d" % ammo

func _refresh_list() -> void:
	var text := "[b]Mom's list[/b]\n"
	for item_name in GameManager.items:
		match GameManager.items[item_name]:
			GameManager.ItemState.INTACT:
				text += item_name + "\n"
			GameManager.ItemState.SABOTAGED:
				text += "[s][color=green]%s[/color][/s]\n" % item_name
			GameManager.ItemState.COLLECTED:
				text += "[s][color=gray]%s[/color][/s] (Mom took it)\n" % item_name
	list_label.text = text

func _ready() -> void:
	ray.prompt_changed.connect(_on_prompt_changed)
	player_stamina.changed.connect(_on_player_stamina_changed)
	GameManager.list_changed.connect(_refresh_list)
	_refresh_list()
	GameManager.mom_stamina_changed.connect(set_mom_stamina)
	GameManager.mom_chase_changed.connect(show_mom_bar)
	ammo_label.visible = false
	GameManager.ammo_changed.connect(_on_ammo_changed)
	GameManager.struggle_changed.connect(_on_struggle_changed)
	GameManager.struggle_ended.connect(_on_struggle_ended)
	mom_bar.visible = false
	struggle_label.visible = false
	angry_overlay.visible = false
	GameManager.mom_angered.connect(_on_mom_angered)
	
func _on_prompt_changed(text: String, locked: bool) -> void:
	prompt.text = text
	prompt.modulate = Color(1, 0.4, 0.4) if locked else Color.WHITE

func _on_player_stamina_changed(value: float, max_value: float) -> void:
	player_bar.max_value = max_value
	player_bar.value = value

func set_mom_stamina(value: float, max_value: float) -> void:
	mom_bar.max_value = max_value
	mom_bar.value = value

func show_mom_bar(shown: bool) -> void:
	mom_bar.visible = shown

func _on_struggle_changed(count: int, needed: int) -> void:
	struggle_label.visible = true
	struggle_label.text = "Caught! Mash SPACE!  %d / %d" % [count, needed]

func _on_struggle_ended() -> void:
	struggle_label.visible = false

func _on_mom_angered() -> void:
	angry_overlay.modulate.a = 1.0
	angry_overlay.visible = true
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(angry_overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): angry_overlay.visible = false)
