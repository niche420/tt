extends HBoxContainer

func _ready() -> void:
	Inventory.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in get_children():
		child.queue_free()

	for item in Inventory.items:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(64, 64)

		if item.icon:
			var icon := TextureRect.new()
			icon.texture = item.icon
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slot.add_child(icon)
		else:
			var label := Label.new()
			label.text = item.display_name if item.display_name != "" else item.id
			slot.add_child(label)

		add_child(slot)
