class_name Player
extends CharacterBody3D

const SPEED = 20.0
const JUMP_VELOCITY = 4.5

@onready var stamina: Stamina = %Stamina

const SHOOT_MASK := 1 | 4      # world (layer 1) + enemies (layer 3)
const SHOOT_RANGE := 40.0

@export var shoot_cooldown: float = 0.4
@export var dart_size: float = 0.3
var ammo: int = 0
var can_shoot: bool = true

@onready var camera: Camera3D = $head/Camera3D

func add_ammo(amount: int) -> void:
	ammo += amount
	GameManager.ammo_changed.emit(ammo)
	
const STRUGGLE_NEEDED := 10

var captured: bool = false
var struggle_count: int = 0
var captor: Node = null

func capture(by: Node) -> void:
	if captured:
		return
	captured = true
	captor = by
	struggle_count = 0
	GameManager.struggle_changed.emit(0, STRUGGLE_NEEDED)
	GameManager.player_captured.emit(global_position)

func release() -> void:
	captured = false
	captor = null
	GameManager.struggle_ended.emit()

func _struggle() -> void:
	struggle_count += 1
	GameManager.struggle_changed.emit(struggle_count, STRUGGLE_NEEDED)
	if struggle_count >= STRUGGLE_NEEDED:
		var guard := captor
		release()
		if guard and is_instance_valid(guard):
			guard.on_released()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		try_shoot()
	elif captured and event.is_action_pressed("interact"):
		_struggle()

func try_shoot() -> void:
	if not can_shoot or ammo <= 0 or not Inventory.has("blaster"):
		return
	can_shoot = false
	ammo -= 1
	GameManager.ammo_changed.emit(ammo)

	var forward := -camera.global_transform.basis.z
	var from := camera.global_position
	var to := from + forward * SHOOT_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to, SHOOT_MASK)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	var end_point := to
	if hit:
		end_point = hit.position
		print("Shot hit: ", hit.collider.name)
		if hit.collider.has_method("on_shot"):
			hit.collider.on_shot()
	_spawn_dart(from + forward * 1.0 - camera.global_transform.basis.y * 0.3, end_point)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func _spawn_dart(from: Vector3, to: Vector3) -> void:
	var dart := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = dart_size * 0.5
	mesh.height = dart_size
	dart.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	dart.material_override = mat
	get_tree().current_scene.add_child(dart)
	dart.global_position = from
	var travel_time := clampf(from.distance_to(to) / 150.0, 0.05, 0.3)
	var tween := dart.create_tween()
	tween.tween_property(dart, "global_position", to, travel_time)
	tween.tween_callback(dart.queue_free)

func _ready() -> void:
	stamina.depleted.connect(_on_exhausted)

func _on_exhausted() -> void:
	GameManager.lose("You ran out of energy!")

func _physics_process(delta: float) -> void:
	if captured:
		stamina.draining = false
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= 20.0 * delta
		move_and_slide()
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var moving := input_dir != Vector2.ZERO
	var sprinting := Input.is_action_pressed("sprint") and moving and stamina.value > 0.0
	stamina.draining = sprinting
	var current_speed := SPEED * (1.6 if sprinting else 1.0)

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
