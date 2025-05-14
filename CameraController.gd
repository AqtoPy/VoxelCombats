extends Camera3D

class_name CameraController

var move_speed = 10.0
var rotation_speed = 0.005
var zoom_speed = 2.0
var min_zoom = 5.0
var max_zoom = 50.0

var is_rotating = false
var last_mouse_pos = Vector2.ZERO

func _input(event):
    # Вращение камеры
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            is_rotating = event.pressed
            if is_rotating:
                last_mouse_pos = event.position
            else:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if event is InputEventMouseMotion and is_rotating:
        _rotate_camera(event.relative)
    
    # Зум колесиком мыши
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            position += transform.basis.z * zoom_speed
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            position -= transform.basis.z * zoom_speed
        
        position = position.clamp(
            Vector3(-INF, min_zoom, -INF),
            Vector3(INF, max_zoom, INF)
        )

    # WASD движение
    var move_dir = Vector3.ZERO
    if Input.is_key_pressed(KEY_W):
        move_dir -= transform.basis.z
    if Input.is_key_pressed(KEY_S):
        move_dir += transform.basis.z
    if Input.is_key_pressed(KEY_A):
        move_dir -= transform.basis.x
    if Input.is_key_pressed(KEY_D):
        move_dir += transform.basis.x
        
    if move_dir != Vector3.ZERO:
        position += move_dir.normalized() * move_speed * get_process_delta_time()

func _rotate_camera(relative: Vector2):
    # Вертикальное вращение
    rotate_x(-relative.y * rotation_speed)
    # Горизонтальное вращение
    rotate_y(-relative.x * rotation_speed)
    
    # Ограничение углов
    rotation.x = clamp(rotation.x, -PI/2, PI/2)
