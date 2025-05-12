extends CharacterBody3D

## === Movement Settings === ##
@export_category("Movement Settings")
@export var walk_speed: float = 250.0
@export var run_speed: float = 300.0
@export var jump_velocity: float = 8.0
@export var air_accelerate: float = 10.0
@export var ground_accelerate: float = 10.0
@export var friction: float = 4.0
@export var gravity: float = 20.0
@export var max_air_speed: float = 30.0
@export var bunnyhop_multiplier: float = 1.1  # Only for VIPs

## === Mouse Settings === ##
@export_category("Mouse Settings")
@export var mouse_sensitivity: float = 0.3
@export var max_look_angle: float = 90.0
@export var min_look_angle: float = -90.0

## === Camera Effects === ##
@export_category("Camera Effects")
@export var breathing_amplitude: float = 0.05
@export var breathing_frequency: float = 0.5
@export var walk_bob_amount: float = 0.2
@export var run_bob_amount: float = 0.3
@export var weapon_sway_amount: float = 0.1
@export var weapon_sway_speed: float = 3.0

## === Components === ##
@onready var camera_pivot = %Camera
@onready var camera = %MainCamera
@onready var weapon_system = $Camera/LeanPivot/MainCamera/Weapons_Manager
@onready var nickname_label = $NameLabel
@onready var model: MeshInstance3D = $Camera/LeanPivot/MainCamera/Object_30
@onready var weapon_pivot = $Camera/LeanPivot/MainCamera/Weapons_Manager

## === Variables === ##
var current_speed: float = 0.0
var is_running: bool = false
var wish_dir: Vector3 = Vector3.ZERO
var player_id: String = ""
var player_role: String = "player" # player/vip/admin/developer
var bunnyhop_enabled: bool = false
var autobunnyhop_enabled: bool = false
var is_grounded: bool = false
var was_grounded: bool = false
var move_direction: Vector3 = Vector3.ZERO
var last_velocity: Vector3 = Vector3.ZERO
var player_name: String = "Player"
var sync_timer: float = 0.0
const SYNC_INTERVAL: float = 0.1  # 10 times per second

# Camera effects
var breathing_timer: float = 0.0
var bob_timer: float = 0.0
var default_camera_pos: Vector3
var default_weapon_pos: Vector3
var weapon_sway_target: Vector3 = Vector3.ZERO
var weapon_sway_current: Vector3 = Vector3.ZERO

func _ready():
	# Initialize multiplayer
	if multiplayer.has_multiplayer_peer():
		player_id = str(multiplayer.get_unique_id())
		set_multiplayer_authority(name.to_int())
	
	# Only setup for local player or server
	if is_multiplayer_authority():
		# Hide mouse cursor for local player
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# Enable camera only for local player
		camera.current = true
		
		# Check player role (should come from server)
		_check_player_role()
	else:
		# Disable processing for other players
		set_physics_process(false)
		set_process_input(false)
		set_process(false)
		camera.current = false
	
	# Setup nickname
	nickname_label.text = player_name
	nickname_label.visible = !is_multiplayer_authority()
	
	# Store default positions for effects
	default_camera_pos = camera_pivot.position
	default_weapon_pos = weapon_pivot.position if weapon_pivot else Vector3.ZERO

func _check_player_role():
	# This should be set by server
	if player_id == "developer_123":
		player_role = "developer"
		bunnyhop_enabled = true
		autobunnyhop_enabled = true
	elif player_id == "vip_456":
		player_role = "vip"
		bunnyhop_enabled = true
		autobunnyhop_enabled = true

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	_handle_movement(delta)
	_handle_jump()
	
	# Apply movement
	move_and_slide()
	
	# Update grounded state
	was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	# Auto bunnyhop for VIPs
	if autobunnyhop_enabled and Input.is_action_pressed("jump") and is_grounded and not was_grounded:
		_perform_bunnyhop()
	
	sync_timer += delta
	if sync_timer >= SYNC_INTERVAL:
		sync_timer = 0.0
		_sync_player_state()
	
	# Sync position with other players
	if multiplayer.has_multiplayer_peer():
		rpc("_update_player_state", global_transform.origin, velocity, rotation, camera_pivot.rotation)

func _process(delta):
	if not is_multiplayer_authority():
		return
	
	# Camera breathing effect
	breathing_timer += delta
	var breathing_offset = sin(breathing_timer * breathing_frequency) * breathing_amplitude
	camera_pivot.position.y = default_camera_pos.y + breathing_offset
	
	# Weapon sway
	_weapon_sway(delta)
	
	# Head bob when moving
	if is_grounded and velocity.length() > 1.0:
		var bob_amount = run_bob_amount if is_running else walk_bob_amount
		bob_timer += delta * velocity.length() * 0.01
		var bob_offset = Vector3(
			sin(bob_timer * 2.0) * bob_amount,
			abs(sin(bob_timer)) * bob_amount * 1.5,
			0
		)
		camera_pivot.position += bob_offset

func _weapon_sway(delta):
	# Calculate sway based on mouse movement
	var mouse_movement = Input.get_last_mouse_velocity()
	weapon_sway_target = Vector3(
		clamp(mouse_movement.x * 0.001, -1, 1),
		clamp(mouse_movement.y * 0.001, -1, 1),
		0
	) * weapon_sway_amount
	
	# Smoothly interpolate to target sway
	weapon_sway_current = weapon_sway_current.lerp(weapon_sway_target, delta * weapon_sway_speed)
	
	# Apply sway to weapon pivot
	if weapon_pivot:
		weapon_pivot.rotation_degrees = Vector3(
			weapon_sway_current.y * 30,
			weapon_sway_current.x * 20,
			weapon_sway_current.x * 10
		)

func _handle_movement(delta):
	# Get input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var target_speed = run_speed if is_running else walk_speed
	
	if is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * target_speed, ground_accelerate * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, ground_accelerate * delta)
	else:
		velocity.x = lerp(velocity.x, direction.x * target_speed, air_accelerate * delta)
		velocity.z = lerp(velocity.z, direction.z * target_speed, air_accelerate * delta)
	
	velocity.y -= gravity * delta
	# Determine wish direction
	wish_dir = Vector3(direction.x, 0, direction.z)
	
	# Apply acceleration
	if is_grounded:
		_accelerate(delta, target_speed, ground_accelerate)
		_apply_friction(delta)
	else:
		_accelerate(delta, max_air_speed, air_accelerate)
	
	# Apply gravity
	if not is_grounded:
		velocity.y -= gravity * delta

func _accelerate(delta: float, target_speed: float, accel: float):
	var current_speed = velocity.dot(wish_dir)
	var add_speed = target_speed - current_speed
	
	if add_speed <= 0:
		return
	
	var accel_speed = accel * target_speed * delta
	accel_speed = min(accel_speed, add_speed)
	
	velocity.x += accel_speed * wish_dir.x
	velocity.z += accel_speed * wish_dir.z

func _apply_friction(delta: float):
	var speed = velocity.length()
	
	if speed < 0.1:
		velocity = Vector3.ZERO
		return
	
	var control = max(speed, walk_speed if is_grounded else air_accelerate)
	var drop = control * friction * delta
	
	var new_speed = max(speed - drop, 0)
	if new_speed > 0:
		new_speed /= speed
	
	velocity *= new_speed

func _handle_jump():
	if Input.is_action_just_pressed("jump") and is_grounded:
		_perform_bunnyhop()

func _perform_bunnyhop():
	velocity.y = jump_velocity
	
	# Bunnyhop speed boost for VIPs
	if bunnyhop_enabled:
		var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
		if horizontal_speed > walk_speed * 0.8:
			velocity.y = jump_velocity * bunnyhop_multiplier
			# Small horizontal boost
			var boost_dir = Vector3(velocity.x, 0, velocity.z).normalized()
			velocity.x += boost_dir.x * 10
			velocity.z += boost_dir.z * 10

func _input(event):
	if not is_multiplayer_authority():
		return
	
	# Camera control
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera_pivot.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(min_look_angle),
			deg_to_rad(max_look_angle)
		)
	
	# Running
	if event.is_action_pressed("run"):
		is_running = true
	if event.is_action_released("run"):
		is_running = false
	
	# Weapon interaction
	if event.is_action_pressed("Shoot"):
		weapon_system.shoot()

	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

@rpc("call_local")
func set_player_role(role: String):
	player_role = role
	bunnyhop_enabled = role in ["vip", "admin", "developer"]
	autobunnyhop_enabled = role in ["vip", "admin", "developer"]
	print("Player role set to: ", role, " | Bunnyhop: ", bunnyhop_enabled, " | AutoBunnyhop: ", autobunnyhop_enabled)

@rpc("call_local")
func teleport_to(position: Vector3):
	global_transform.origin = position
	velocity = Vector3.ZERO

@rpc("call_local")
func set_player_nickname(new_nickname: String):
	player_name = new_nickname
	nickname_label.text = player_name

func _sync_player_state():
	rpc("_remote_update_state", 
		global_position,
		Vector2(rotation.y, camera_pivot.rotation.x))
		
@rpc("unreliable", "any_peer")
func _remote_update_state(pos: Vector3, rot: Vector2):
	if not is_multiplayer_authority():
		global_position = pos
		rotation.y = rot.x
		camera_pivot.rotation.x = rot.y
