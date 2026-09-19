# security_spawner.gd
extends Node3D

@export var guard_scene: PackedScene
@export var player: Player
@export var max_guards: int = 1

var spawned: int = 0

func _ready() -> void:
	GameManager.security_called.connect(_spawn)

func _unhandled_input(event: InputEvent) -> void:
	# debug: F1 spawns a guard so you can test without Mom's timer
	if OS.is_debug_build() and event is InputEventKey \
			and event.pressed and event.keycode == KEY_F1:
		_spawn()

func _spawn() -> void:
	if spawned >= max_guards:
		return
	spawned += 1
	var guard := guard_scene.instantiate()
	guard.player = player
	add_child(guard)
	guard.global_position = _farthest_marker().global_position
	print("Security has arrived!")

func _farthest_marker() -> Marker3D:
	var best: Marker3D = null
	var best_dist := -1.0
	for child in get_children():
		if child is Marker3D:
			var d := player.global_position.distance_to(child.global_position)
			if d > best_dist:
				best_dist = d
				best = child
	return best
