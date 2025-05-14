func _handle_mouse_input(event: InputEvent) -> void:
    # Обработка движения мыши для предпросмотра
    if event is InputEventMouseMotion:
        _update_cursor_preview()
        if is_dragging:
            _handle_dragging_operation()

    # Обработка нажатий кнопок мыши
    if event is InputEventMouseButton:
        var mouse_pos = _get_snapped_mouse_position()
        
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                if event.pressed:
                    _start_mouse_operation(mouse_pos)
                else:
                    _end_mouse_operation()
            
            MOUSE_BUTTON_RIGHT:
                if event.pressed:
                    _handle_right_click(mouse_pos)
            
            MOUSE_BUTTON_WHEEL_UP:
                _adjust_brush_size(1)
            
            MOUSE_BUTTON_WHEEL_DOWN:
                _adjust_brush_size(-1)

func _start_mouse_operation(pos: Vector3) -> void:
    match current_tool:
        Tools.BRUSH, Tools.ERASER:
            _start_painting_operation(pos)
        
        Tools.SELECT:
            _start_selection_operation(pos)
        
        Tools.FILL:
            _execute_fill_operation(pos)
        
        Tools.MOVE:
            _start_move_operation(pos)

func _handle_dragging_operation() -> void:
    match current_tool:
        Tools.BRUSH, Tools.ERASER:
            _paint_continuous()
        
        Tools.SELECT:
            _update_selection_area()
        
        Tools.MOVE:
            _update_block_positions()

func _end_mouse_operation() -> void:
    is_dragging = false
    _commit_to_history()
    
    match current_tool:
        Tools.SELECT:
            _finalize_selection()
        
        Tools.MOVE:
            _finalize_movement()

func _start_painting_operation(pos: Vector3) -> void:
    drag_start_pos = pos
    is_dragging = true
    
    # Для единичного клика без перемещения
    _paint_single(pos)

func _paint_continuous() -> void:
    var current_pos = _get_snapped_mouse_position()
    var points = _get_line_points(drag_start_pos, current_pos)
    
    for point in points:
        _paint_single(point)
    
    drag_start_pos = current_pos

func _paint_single(pos: Vector3) -> void:
    match current_tool:
        Tools.BRUSH:
            _place_block(pos)
        
        Tools.ERASER:
            _remove_block(pos)

func _start_selection_operation(pos: Vector3) -> void:
    drag_start_pos = pos
    is_dragging = true
    
    if Input.is_key_pressed(KEY_CTRL):
        selection_mode = SelectionModes.RECT
        _start_rect_selection()
    elif Input.is_key_pressed(KEY_SHIFT):
        selection_mode = SelectionModes.ADD
    else:
        selection_mode = SelectionModes.SINGLE
        _clear_selection()

func _update_selection_area() -> void:
    if selection_mode == SelectionModes.RECT:
        _update_rect_selection()
    else:
        _update_freeform_selection()

func _execute_fill_operation(pos: Vector3) -> void:
    var fill_area = _get_fill_region(pos)
    var operation = {
        "type": "FILL",
        "positions": fill_area,
        "original_block": _get_block_at(pos).block_id,
        "new_block": selected_block
    }
    _apply_fill_operation(operation)

func _handle_right_click(pos: Vector3) -> void:
    match current_tool:
        Tools.SELECT:
            if Input.is_key_pressed(KEY_CTRL):
                _copy_selected()
            else:
                _open_context_menu(pos)
        
        _:
            _rotate_camera_view()

func _adjust_brush_size(delta: int) -> void:
    brush_size = clamp(brush_size + delta, 1, max_brush_size)
    ui.update_brush_size(brush_size)

# okak

func _get_line_points(start: Vector3, end: Vector3) -> Array:
    var points = []
    var steps = max(abs(end.x - start.x), abs(end.z - start.z))
    
    for i in steps + 1:
        var t = float(i) / steps
        var x = lerp(start.x, end.x, t)
        var z = lerp(start.z, end.z, t)
        points.append(Vector3(x, start.y, z))
    
    return points

func _start_rect_selection() -> void:
    selection_rect = Rect2(drag_start_pos.xz, Vector2.ZERO)

func _update_rect_selection() -> void:
    var current_pos = _get_snapped_mouse_position()
    selection_rect.size = current_pos.xz - drag_start_pos.xz
    _select_blocks_in_rect()

func _select_blocks_in_rect() -> void:
    var blocks = _get_blocks_in_area(
        Vector3(selection_rect.position.x, current_layer, selection_rect.position.y),
        Vector3(selection_rect.end.x, current_layer, selection_rect.end.y)
    )
    _add_to_selection(blocks)

func _open_context_menu(pos: Vector3) -> void:
    var menu = preload("res://ui/ContextMenu.tscn").instantiate()
    menu.position = get_viewport().get_mouse_position()
    menu.setup([
        {"name": "Copy", "callback": _copy_selected},
        {"name": "Rotate", "callback": _rotate_selected},
        {"name": "Delete", "callback": _delete_selected}
    ])
    add_child(menu)
