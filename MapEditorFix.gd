extends Node3D

# Настройки
var camera_sensitivity = 0.005
var camera_distance = 10.0
var camera_rotation = Vector2(0, 0)
var current_block_id = 0
var saved_maps_dir = "user://maps/"

@onready var grid_map = $GridMap
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var mesh_lib = preload("res://Blocks.tres")

func _ready():
    # Настройка GridMap
    grid_map.mesh_library = mesh_lib
    grid_map.cell_size = Vector3(1, 1, 1)
    
    # Создаем физическую плоскость
    var plane = MeshInstance3D.new()
    plane.mesh = PlaneMesh.new()
    plane.mesh.size = Vector2(20, 20)
    plane.position = Vector3(10, 0, 10)
    plane.create_trimesh_collision()
    add_child(plane)
    
    # Проверка загрузки
    print("MeshLibrary loaded:", mesh_lib != null)
    print("Blocks available:", mesh_lib.get_item_list())

func _input(event):
    # Вращение камеры
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
        camera_rotation.x -= event.relative.x * camera_sensitivity
        camera_rotation.y = clamp(camera_rotation.y - event.relative.y * camera_sensitivity, -1.0, 1.0)
        update_camera()
    
    # Приближение/отдаление
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = clamp(camera_distance - 1.0, 5.0, 30.0)
            update_camera()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = clamp(camera_distance + 1.0, 5.0, 30.0)
            update_camera()
    
    # Размещение блоков
    if event is InputEventMouseButton and event.pressed:
        var mouse_pos = event.position
        var from = camera.project_ray_origin(mouse_pos)
        var to = from + camera.project_ray_normal(mouse_pos) * 1000
        
        var result = get_world_3d().direct_space_state.intersect_ray(
            PhysicsRayQueryParameters3D.create(from, to)
        )
        
        if result:
            var cell_pos = grid_map.world_to_map(result.position)
            print("Attempting to place block at:", cell_pos)
            
            if event.button_index == MOUSE_BUTTON_LEFT:
                grid_map.set_cell_item(cell_pos, current_block_id)
                print("Block placed. Used cells:", grid_map.get_used_cells())
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                grid_map.set_cell_item(cell_pos, -1)

func update_camera():
    camera_pivot.rotation = Vector3(camera_rotation.y, camera_rotation.x, 0)
    camera.position.z = camera_distance
