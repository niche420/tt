extends Interactable

func _interact(player: Node) -> void:
	$ClosedSprite.visible = false
	$OpenedSprite.visible = true
	$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
