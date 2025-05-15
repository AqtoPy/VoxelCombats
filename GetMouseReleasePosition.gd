# Возвращает позицию на GridMap при отпускании кнопки мыши
func get_mouse_release_position():
    # Ждем пока кнопка мыши будет отпущена
    while true:
        # Получаем текущее событие мыши
        var mouse_event = await get_tree().process_frame
        
        if mouse_event is InputEventMouseButton:
            if not mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
                # Когда кнопка отпущена, возвращаем позицию на сетке
                var mouse_pos = get_viewport().get_mouse_position()
                var from = camera.project_ray_origin(mouse_pos)
                var to = from + camera.project_ray_normal(mouse_pos) * 1000
                
                var result = get_world_3d().direct_space_state.intersect_ray(
                    PhysicsRayQueryParameters3D.create(from, to)
                )
                
                if result:
                    return grid_map.local_to_map(result.position)
                return null
