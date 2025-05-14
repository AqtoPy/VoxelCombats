extends Node3D

# Добавляем временную визуализацию луча
var debug_lines = []

func _process(delta):
    # Очищаем линии предыдущего кадра
    for line in debug_lines:
        line.queue_free()
    debug_lines.clear()

func draw_debug_line(from: Vector3, to: Vector3, color: Color = Color.RED):
    var immediate_mesh = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = color
    
    immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
    immediate_mesh.surface_add_vertex(from)
    immediate_mesh.surface_add_vertex(to)
    immediate_mesh.surface_end()
    
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = immediate_mesh
    add_child(mesh_instance)
    debug_lines.append(mesh_instance)

# d
func _input(event):
    # ... остальной код обработки ввода ...
    
    if event is InputEventMouseButton and event.pressed:
        var mouse_pos = event.position
        var from = camera.project_ray_origin(mouse_pos)
        var to = from + camera.project_ray_normal(mouse_pos) * 1000
        
        # Рисуем луч для отладки
        draw_debug_line(from, to)
        
        var space = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(from, to)
        query.collision_mask = 1 # Убедитесь что mask совпадает с вашими объектами
        
        var result = space.intersect_ray(query)
        print("Raycast result: ", result)
        
        if result:
            var cell_pos = grid_map.world_to_map(result.position)
            print("Hit grid at: ", cell_pos)
            
            if event.button_index == MOUSE_BUTTON_LEFT:
                grid_map.set_cell_item(cell_pos, current_block)
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                grid_map.set_cell_item(cell_pos, -1)


# проверка коллизии
func create_grid_plane():
    var plane_mesh = PlaneMesh.new()
    plane_mesh.size = Vector2(grid_size.x, grid_size.y)
    
    # Добавляем коллизию
    var static_body = StaticBody3D.new()
    var collision = CollisionShape3D.new()
    collision.shape = plane_mesh.get_mesh().create_trimesh_shape()
    static_body.add_child(collision)
    
    grid_plane = MeshInstance3D.new()
    grid_plane.mesh = plane_mesh
    add_child(grid_plane)
    add_child(static_body)
