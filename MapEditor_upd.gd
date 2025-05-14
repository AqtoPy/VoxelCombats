func _get_fill_region(start_pos: Vector3) -> Array:
    var target_block = _get_block_at(start_pos)
    if not target_block:
        return []
    
    var fill_blocks = []
    var queue = [start_pos]
    var visited = {}
    var original_id = target_block.block_id
    
    while not queue.is_empty():
        var current_pos = queue.pop_front()
        
        if visited.has(current_pos):
            continue
            
        var block = _get_block_at(current_pos)
        if block and block.block_id == original_id:
            fill_blocks.append(current_pos)
            visited[current_pos] = true
            
            # Добавляем соседей
            for dir in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
                var neighbor_pos = current_pos + dir
                if not visited.has(neighbor_pos):
                    queue.append(neighbor_pos)
    
    return fill_blocks

func _calculate_circle_area(center: Vector3, radius_pos: Vector3) -> Array:
    var radius = center.distance_to(radius_pos)
    var positions = []
    
    var start_x = center.x - radius
    var end_x = center.x + radius
    var start_z = center.z - radius
    var end_z = center.z + radius
    
    for x in range(start_x, end_x + 1):
        for z in range(start_z, end_z + 1):
            var pos = Vector3(x, center.y, z)
            if center.distance_to(pos) <= radius:
                positions.append(pos)
    
    return positions


# дополнения
# В секции переменных
var fill_tolerance = 0.1  # Допуск для заливки

# В секции функций
func _start_fill():
    var start_pos = _get_snapped_mouse_position()
    var fill_area = _get_fill_region(start_pos)
    
    var operation = {
        "type": "FILL",
        "positions": fill_area,
        "original_block": _get_block_at(start_pos).block_id,
        "new_block": selected_block
    }
    
    _apply_fill_operation(operation)

func _apply_fill_operation(operation: Dictionary):
    for pos in operation.positions:
        _remove_block(pos)
        _place_block(pos)
    
    history.append({
        "type": "FILL",
        "data": operation.positions,
        "original": operation.new_block,
        "replacement": operation.original_block
    })
