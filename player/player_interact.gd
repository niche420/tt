extends RayCast3D

@onready var player: Node = owner

var current: Interactable = null

signal prompt_changed(text: String, locked: bool)

func _physics_process(_delta: float) -> void:
	current = null
	if is_colliding():
		var hit = get_collider()
		if hit and hit.get_parent() is Interactable:
			current = hit.get_parent()
	if current:
		prompt_changed.emit(current.get_prompt(), current.is_locked())
	else:
		prompt_changed.emit("", false)

func _unhandled_input(event: InputEvent) -> void:
	if player.get("captured"):
		return
	if event.is_action_pressed("interact") and current:
		current.try_interact(player)
