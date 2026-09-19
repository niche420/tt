extends Node

signal changed

var items: Array[ItemData] = []

func add(item: ItemData) -> void:
	if item == null:
		push_warning("Inventory.add() got an empty item")
		return
	items.append(item)
	print("Inventory now has: ", items.size(), " item(s)")
	changed.emit()

func has(id: String) -> bool:
	for item in items:
		if item.id == id:
			return true
	return false

func remove(id: String) -> void:
	for i in items.size():
		if items[i].id == id:
			items.remove_at(i)
			break
	changed.emit()
