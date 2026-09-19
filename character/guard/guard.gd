# guard.gd
extends CharacterBody3D

enum State { CHASING, HOLDING, STUNNED }

@export var player: Player
@export var chase_speed: float = 4.5
@export var catch_distance: float = 1.2
@export var stun_time: float = 4.0
@export var shove_stun_time: float = 2.5
@export var hits_to_retire: int = 3

@onready var agent: NavigationAgent3D = $NavigationAgent3D

var state: State = State.CHASING
var hits: int = 0
var active: bool = false
var stun_id: int = 0

func _ready() -> void:
	await get_tree().physics_frame
	active = true

func _physics_process(delta: float) -> void:
	if not active:
		return
	velocity.y -= 20.0 * delta
	match state:
		State.CHASING:
			_chase()
		State.HOLDING, State.STUNNED:
			velocity.x = 0.0
			velocity.z = 0.0
	move_and_slide()

func _chase() -> void:
	agent.target_position = player.global_position
	var dir := agent.get_next_path_position() - global_position
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * chase_speed
	velocity.z = dir.z * chase_speed

	var flat := Vector2(
		global_position.x - player.global_position.x,
		global_position.z - player.global_position.z)
	if flat.length() < catch_distance and not player.captured:
		state = State.HOLDING
		player.capture(self)

# called by the player after 10 presses
func on_released() -> void:
	_stun(shove_stun_time)

# called by the player's dart
func on_shot() -> void:
	var sprite := get_node_or_null("Sprite3D") as Sprite3D
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	hits += 1
	if state == State.HOLDING:
		player.release()
	if hits >= hits_to_retire:
		print("Guard gave up")
		queue_free()
		return
	_stun(stun_time)

func _stun(seconds: float) -> void:
	state = State.STUNNED
	stun_id += 1
	var id := stun_id
	await get_tree().create_timer(seconds).timeout
	if id == stun_id and state == State.STUNNED:
		state = State.CHASING
