@onready var grid_map = $GridMap

func _ready():
    # Явно указываем MeshLibrary
    grid_map.mesh_library = preload("res://Blocks.tres")
    print("MeshLibrary items: ", grid_map.mesh_library.get_item_list())

#еще

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        var mouse_pos = event.position
        var from = camera.project_ray_origin(mouse_pos)
        var to = from + camera.project_ray_normal(mouse_pos) * 1000
        
        var result = get_world_3d().direct_space_state.intersect_ray(
            PhysicsRayQueryParameters3D.create(from, to)
        )
        
        if result:
            var cell_pos = grid_map.world_to_map(result.position)
            var block_index = 0  # Индекс блока в MeshLibrary (0, 1 или 2)
            
            if event.button_index == MOUSE_BUTTON_LEFT:
                # Ставим блок с учетом его поворота
                grid_map.set_cell_item(cell_pos, block_index, 0)
                print("Блок ", block_index, " поставлен в ", cell_pos)
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                grid_map.set_cell_item(cell_pos, -1)
