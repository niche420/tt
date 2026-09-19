extends Interactable

@export var gives_item: ItemData

func _interact(player: Node) -> void:
	$BottleSprite.visible = false
	$BrokenSprite.visible = true
	Inventory.add(gives_item)
	$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
