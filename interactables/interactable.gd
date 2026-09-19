class_name Interactable
extends Node3D

@export var prompt_text: String = "Interact"
@export var locked_text: String = ""
@export var required_item: String = ""
@export var consume_item: bool = true
@export var list_item_name: String = ""   # e.g. "Wine". Empty = not on mom's list

func _ready() -> void:
	if list_item_name != "":
		GameManager.register_item(list_item_name)
		add_to_group("list_items")

func is_locked() -> bool:
	return required_item != "" and not Inventory.has(required_item)

func get_prompt() -> String:
	if is_locked():
		if locked_text != "":
			return locked_text
		return "Need " + required_item
	return prompt_text

func try_interact(player: Node) -> void:
	if is_locked():
		return
	if required_item != "" and consume_item:
		Inventory.remove(required_item)
	_interact(player)
	if list_item_name != "":
		GameManager.sabotage_item(list_item_name, global_position)

func collect_by_mom() -> void:
	var item_name := list_item_name
	visible = false
	remove_from_group("list_items")
	queue_free()
	GameManager.collect_item(item_name)

func _interact(player: Node) -> void:
	pass
