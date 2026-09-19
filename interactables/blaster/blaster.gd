extends Interactable

@export var gives_item: ItemData
@export var ammo: int = 6

func _interact(player: Node) -> void:
	if gives_item and not Inventory.has(gives_item.id):
		Inventory.add(gives_item)
	player.add_ammo(ammo)
	visible = false
	$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
