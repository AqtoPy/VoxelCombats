extends Node3D

# ... (остальные переменные остаются такими же)

func _input(event):
    # Вращение камеры (как было)
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
        is_rotating = event.pressed
        if is_rotating:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    if event is InputEventMouseMotion and is_rotating:
        camera_rotation.x -= event.relative.x * 0.01
        camera_rotation.y = clamp(camera_rotation.y - event.relative.y * 0.01, -PI/2 + 0.1, PI/2 - 0.1)
        update_camera_position()
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
        camera_distance = clamp(camera_distance - 1.0, 5.0, 30.0)
        update_camera_position()
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        camera_distance = clamp(camera_distance + 1.0, 5.0, 30.0)
        update_camera_position()
    
    # Размещение/удаление блоков - ОБНОВЛЕННЫЙ КОД
    if event is InputEventMouseButton and event.pressed:
        var mouse_pos = event.position
        var from = camera.project_ray_origin(mouse_pos)
        var to = from + camera.project_ray_normal(mouse_pos) * 1000
        
        # Добавим отладочную визуализацию луча
        DebugDraw3D.draw_line_3d(from, to, Color.RED, 0.1)
        
        var space_state = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.collide_with_areas = true
        query.collide_with_bodies = true
        
        var result = space_state.intersect_ray(query)
        print("Raycast result: ", result)  # Отладочный вывод
        
        if result.size() > 0:
            var hit_position = result.position
            var cell_pos = grid_map.world_to_map(hit_position)
            print("Hit at world pos: ", hit_position, " | Grid pos: ", cell_pos)
            
            # Проверяем, что попали именно в сетку (а не в другие объекты)
            if result.collider == grid_plane:
                if event.button_index == MOUSE_BUTTON_LEFT:
                    print("Placing block at: ", cell_pos)
                    grid_map.set_cell_item(cell_pos, current_block)
                elif event.button_index == MOUSE_BUTTON_RIGHT:
                    print("Removing block at: ", cell_pos)
                    grid_map.set_cell_item(cell_pos, -1)
            else:
                print("Hit object: ", result.collider.name)
        else:
            print("Raycast didn't hit anything")

      # debug load
      extends Node3D
@onready var debug_draw = preload("res://addons/debug_draw_3d/debug_draw_3d.gdns").new()
add_child(debug_draw)
