extends CharacterBody3D

## === Movement Settings === ##
@export_category("Movement Settings")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var air_control: float = 0.3
@export var ground_acceleration: float = 10.0
@export var friction: float = 6.0
@export var gravity: float = 9.8
@export var max_air_speed: float = 10.0
@export var bunnyhop_multiplier: float = 1.1  # Only for VIPs

## === Player Settings === ##
@export_category("Player Settings")
@export var player_name: String = "Player"
@export var clan_tag: String = ""
@export var health: int = 100:
    set(value):
        health = clamp(value, 0, 100)
        if health <= 0:
            die()

## === Camera Settings === ##
@export_category("Camera Settings")
@export var mouse_sensitivity: float = 0.2
@export var max_look_angle: float = 90.0
@export var min_look_angle: float = -90.0

## === Components === ##
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var weapon_manager = $CameraPivot/Camera3D/WeaponManager
@onready var nickname_label = $NicknameLabel
@onready var death_camera = $DeathCamera
@onready var respawn_timer = $RespawnTimer

## === Variables === ##
var current_speed: float = 0.0
var is_running: bool = false
var wish_dir: Vector3 = Vector3.ZERO
var player_id: int = 0
var player_role: String = "player" # player/vip/admin/developer
var bunnyhop_enabled: bool = false
var autobunnyhop_enabled: bool = false
var is_grounded: bool = false
var was_grounded: bool = false
var is_alive: bool = true
var killer_id: int = -1
var team: String = ""

# Network sync
var sync_position: Vector3
var sync_rotation: Vector2
var last_sync_time: float = 0.0
const SYNC_INTERVAL: float = 0.1  # 100ms

func _ready():
    # Initialize multiplayer
    if multiplayer.has_multiplayer_peer():
        player_id = multiplayer.get_unique_id()
        set_multiplayer_authority(player_id)
    
    # Only setup for local player
    if is_multiplayer_authority():
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        camera.current = true
        death_camera.current = false
    else:
        set_physics_process(false)
        set_process_input(false)
        set_process(false)
        camera.current = false
    
    # Setup nickname display
    update_nickname_display()

func update_nickname_display():
    var display_text = ("[%s] %s" % [clan_tag, player_name]) if clan_tag else player_name
    nickname_label.text = display_text
    nickname_label.visible = !is_multiplayer_authority()

func _physics_process(delta):
    if not is_multiplayer_authority() or not is_alive:
        return
    
    _handle_movement(delta)
    _handle_jump()
    
    move_and_slide()
    
    # Update grounded state
    was_grounded = is_grounded
    is_grounded = is_on_floor()
    
    # Auto bunnyhop for VIPs
    if autobunnyhop_enabled and Input.is_action_pressed("jump") and is_grounded and not was_grounded:
        _perform_bunnyhop()
    
    # Network sync
    last_sync_time += delta
    if last_sync_time >= SYNC_INTERVAL:
        last_sync_time = 0.0
        _sync_player_state()

func _handle_movement(delta):
    # Get input direction
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    # Apply movement
    var target_speed = run_speed if is_running else walk_speed
    
    if is_grounded:
        # Ground movement
        var current_speed = velocity.dot(direction)
        var add_speed = target_speed - current_speed
        
        if add_speed > 0:
            var accel_speed = ground_acceleration * target_speed * delta
            accel_speed = min(accel_speed, add_speed)
            velocity.x += accel_speed * direction.x
            velocity.z += accel_speed * direction.z
        
        # Apply friction
        var speed = velocity.length()
        if speed > 0:
            var control = max(speed, friction)
            var drop = control * friction * delta
            velocity *= max(speed - drop, 0) / speed
    else:
        # Air movement with better control
        var current_speed = velocity.dot(direction)
        var add_speed = target_speed - current_speed
        
        if add_speed > 0:
            var accel_speed = ground_acceleration * air_control * delta
            accel_speed = min(accel_speed, add_speed)
            velocity.x += accel_speed * direction.x
            velocity.z += accel_speed * direction.z
        
        # Limit air speed
        var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
        if horizontal_velocity.length() > max_air_speed:
            horizontal_velocity = horizontal_velocity.normalized() * max_air_speed
            velocity.x = horizontal_velocity.x
            velocity.z = horizontal_velocity.z
    
    # Apply gravity
    if not is_grounded:
        velocity.y -= gravity * delta

func _handle_jump():
    if Input.is_action_just_pressed("jump") and is_grounded:
        _perform_bunnyhop()

func _perform_bunnyhop():
    velocity.y = jump_velocity
    
    # Bunnyhop speed boost for VIPs
    if bunnyhop_enabled:
        var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
        if horizontal_velocity.length() > walk_speed * 0.8:
            velocity.y = jump_velocity * bunnyhop_multiplier
            # Small horizontal boost while maintaining momentum
            var boost_dir = horizontal_velocity.normalized()
            velocity.x = boost_dir.x * horizontal_velocity.length() * 1.05
            velocity.z = boost_dir.z * horizontal_velocity.length() * 1.05

func _input(event):
    if not is_multiplayer_authority() or not is_alive:
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
    if event.is_action_pressed("shoot"):
        weapon_manager.shoot.rpc()

    # Toggle mouse capture
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func die():
    if not is_alive:
        return
    
    is_alive = false
    visible = false
    nickname_label.visible = false
    
    if is_multiplayer_authority():
        # Switch to death camera
        camera.current = false
        death_camera.current = true
        
        # Look at killer if possible
        if killer_id != -1:
            var killer = get_tree().get_nodes_in_group("players").filter(func(p): return p.player_id == killer_id)
            if killer.size() > 0:
                death_camera.look_at(killer[0].global_position)
        
        # Start respawn timer
        respawn_timer.start(5.0)

func respawn():
    is_alive = true
    health = 100
    visible = true
    nickname_label.visible = !is_multiplayer_authority()
    
    if is_multiplayer_authority():
        death_camera.current = false
        camera.current = true
        
        # Teleport to spawn point
        var spawn_points = get_tree().get_nodes_in_group("spawn_" + team)
        if spawn_points.size() > 0:
            global_transform.origin = spawn_points[randi() % spawn_points.size()].global_transform.origin

func _on_respawn_timer_timeout():
    respawn.rpc()

@rpc("call_local")
func set_damage(amount: int, attacker_id: int):
    if not is_alive:
        return
    
    health -= amount
    if health <= 0:
        killer_id = attacker_id
        die()

@rpc("call_local")
func set_player_role(role: String):
    player_role = role
    bunnyhop_enabled = role in ["vip", "admin", "developer"]
    autobunnyhop_enabled = role in ["vip", "admin", "developer"]

@rpc("call_local")
func set_player_team(new_team: String):
    team = new_team
    # Update player material/color based on team

func _sync_player_state():
    rpc("_remote_update_state", 
        global_position,
        Vector2(rotation.y, camera_pivot.rotation.x),
        velocity)

@rpc("unreliable", "any_peer")
func _remote_update_state(pos: Vector3, rot: Vector2, vel: Vector3):
    if not is_multiplayer_authority():
        global_position = pos.lerp(global_position, 0.5)  # Smooth interpolation
        rotation.y = rot.x
        camera_pivot.rotation.x = rot.y
        velocity = vel
