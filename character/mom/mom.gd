# mom.gd
extends CharacterBody3D

enum State { SHOPPING, CHASING }

@export var waypoints_root: Node3D    # only used when nothing is left on her list
@export var player: CharacterBody3D
@export var angry_texture: Texture2D
@export var walk_speed: float = 2.5
@export var chase_speed: float = 5.0
@export var shop_time: float = 3.0
@export var catch_distance: float = 2.5

@export_group("Vision")
@export var view_distance: float = 12.0
@export var view_angle: float = 100.0
@export var notice_radius: float = 5.0
@export var call_security_after: float = 8.0   # seconds of chasing

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var stamina: Stamina = $Stamina
@onready var sprite: Sprite3D = $Sprite3D

var state: State = State.SHOPPING
var active: bool = false
var waiting: bool = false
var known_items: Array[String] = []
var facing: Vector3 = Vector3.FORWARD
var current_target: Interactable = null
var patrolling: bool = false
var waypoint_index: int = 0
var chase_time: float = 0.0
var security_was_called: bool = false

func _ready() -> void:
	stamina.changed.connect(_on_stamina_changed)
	stamina.depleted.connect(_on_exhausted)
	GameManager.player_captured.connect(_on_player_captured)
	await get_tree().physics_frame
	active = true

func _physics_process(delta: float) -> void:
	if not active:
		return
	velocity.y -= 20.0 * delta
	match state:
		State.SHOPPING:
			_look_for_things()
			_shopping()
		State.CHASING:
			_chasing(delta)
	move_and_slide()

# ---------- Noticing ----------

func _look_for_things() -> void:
	for item_name in GameManager.destroyed_positions:
		if item_name in known_items:
			continue
		if _can_notice_item(GameManager.destroyed_positions[item_name]):
			_notice_item(item_name)

func _can_notice_item(pos: Vector3) -> bool:
	var flat := Vector3(pos.x - global_position.x, 0.0, pos.z - global_position.z)
	var dist := flat.length()
	if dist < 2.0:
		return true   # practically standing on it
	if dist <= notice_radius:
		# close enough that the shelf's collider shouldn't hide it, but she must face it
		return rad_to_deg(facing.angle_to(flat)) <= view_angle / 2.0
	return _can_see(pos)

func _notice_item(item_name: String) -> void:
	if item_name in known_items:
		return
	known_items.append(item_name)
	print("Mom noticed that ", item_name, " is destroyed!")
	_start_chase()

func _can_see(target: Vector3) -> bool:
	var eyes := global_position + Vector3.UP * 1.6
	var to_target := target - eyes
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	if flat.length() > view_distance:
		return false
	if rad_to_deg(facing.angle_to(flat)) > view_angle / 2.0:
		return false
	var query := PhysicsRayQueryParameters3D.create(eyes, target, 1)
	query.exclude = [get_rid(), player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.position.distance_to(target) < 1.5

# ---------- Shopping ----------

func _shopping() -> void:
	if waiting:
		_stop_moving()
		return
	if current_target == null or not is_instance_valid(current_target):
		if not _choose_target():
			_patrol()
			return
	if agent.is_navigation_finished():
		# arrived: if it's been wrecked, she notices right away
		var st = GameManager.items.get(current_target.list_item_name, -1)
		if st == GameManager.ItemState.SABOTAGED:
			_notice_item(current_target.list_item_name)
			return
		_browse()
		return
	_move_along_path(walk_speed)

func _choose_target() -> bool:
	var best: Interactable = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("list_items"):
		var item := node as Interactable
		if not _needs_visit(item):
			continue
		var d := global_position.distance_to(item.global_position)
		if d < best_dist:
			best_dist = d
			best = item
	current_target = best
	if best:
		patrolling = false
		agent.target_position = best.global_position
		print("Mom heading to: ", best.list_item_name)
	return best != null

func _needs_visit(item: Interactable) -> bool:
	var st = GameManager.items.get(item.list_item_name, -1)
	if st == GameManager.ItemState.INTACT:
		return true
	return st == GameManager.ItemState.SABOTAGED and not known_items.has(item.list_item_name)

func _browse() -> void:
	waiting = true
	await get_tree().create_timer(shop_time * 0.5).timeout
	if state != State.SHOPPING:
		return
	_collect(current_target)
	await get_tree().create_timer(shop_time * 0.5).timeout
	if state != State.SHOPPING:
		return
	current_target = null
	waiting = false

func _collect(item: Interactable) -> void:
	if not is_instance_valid(item):
		return
	if GameManager.items.get(item.list_item_name, -1) != GameManager.ItemState.INTACT:
		return
	print("Mom picked up ", item.list_item_name)
	item.collect_by_mom()

func _patrol() -> void:
	if not patrolling:
		patrolling = true
		_go_to_waypoint()
	if agent.is_navigation_finished():
		waypoint_index = (waypoint_index + 1) % waypoints_root.get_child_count()
		_go_to_waypoint()
	_move_along_path(walk_speed)

func _go_to_waypoint() -> void:
	var marker := waypoints_root.get_child(waypoint_index) as Marker3D
	agent.target_position = marker.global_position

# ---------- Anger (permanent) ----------

func _start_chase() -> void:
	if state == State.CHASING:
		return
	state = State.CHASING
	chase_time = 0.0
	waiting = false
	stamina.draining = true   # she only stops when this runs out
	if angry_texture:
		sprite.texture = angry_texture
	GameManager.mom_angered.emit()
	GameManager.mom_chase_changed.emit(true)

func _chasing(delta: float) -> void:
	chase_time += delta
	if chase_time > call_security_after and not security_was_called:
		security_was_called = true
		print("Mom called security!")
		GameManager.security_called.emit()

	agent.target_position = player.global_position
	_move_along_path(chase_speed)

	var flat := Vector2(
		global_position.x - player.global_position.x,
		global_position.z - player.global_position.z)
	if flat.length() < catch_distance:
		GameManager.lose()

func _on_stamina_changed(value: float, max_value: float) -> void:
	GameManager.mom_stamina_changed.emit(value, max_value)

func _on_exhausted() -> void:
	print("Mom is exhausted!")
	GameManager.win()

func _on_player_captured(_pos: Vector3) -> void:
	_start_chase()

func on_shot() -> void:
	print("Mom was hit by a dart!")
	sprite.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)

# ---------- Movement helpers ----------

func _move_along_path(speed: float) -> void:
	var next_pos := agent.get_next_path_position()
	var dir := next_pos - global_position
	dir.y = 0.0
	dir = dir.normalized()
	if dir.length() > 0.01:
		facing = dir
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _stop_moving() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
