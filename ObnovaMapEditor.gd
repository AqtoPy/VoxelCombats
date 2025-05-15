extends Node3D

# Добавляем в существующий код
var shape_start_pos = null
var is_drawing_shape = false

func handle_tools_input(event):
    if event is InputEventMouseButton:
        var grid_pos = get_mouse_grid_position()
        if grid_pos == null: return
        
        if event.pressed:
            match current_tool:
                Tool.BRUSH, Tool.ERASER:
                    handle_single_placement(event, grid_pos)
                Tool.LINE, Tool.RECTANGLE:
                    if event.button_index == MOUSE_BUTTON_LEFT:
                        shape_start_pos = grid_pos
                        is_drawing_shape = true
        else:
            if is_drawing_shape and event.button_index == MOUSE_BUTTON_LEFT:
                match current_tool:
                    Tool.LINE:
                        draw_line(shape_start_pos, grid_pos)
                    Tool.RECTANGLE:
                        draw_rect(shape_start_pos, grid_pos)
                is_drawing_shape = false
                shape_start_pos = null

func _process(delta):
    if is_drawing_shape:
        var current_pos = get_mouse_grid_position()
        if current_pos:
            # Временная визуализация при рисовании
            clear_preview()
            match current_tool:
                Tool.LINE:
                    preview_line(shape_start_pos, current_pos)
                Tool.RECTANGLE:
                    preview_rect(shape_start_pos, current_pos)

func clear_preview():
    # Очищаем временные блоки (например, установленные на слое для превью)
    for layer in grid_map.get_layers_count():
        if layer == PREVIEW_LAYER:
            grid_map.clear_layer(layer)

const PREVIEW_LAYER = 99  # Специальный слой для превью

func preview_line(start, end):
    var points = bresenham_line(start, end)
    for point in points:
        grid_map.set_cell_item(point, current_block_id, PREVIEW_LAYER)

func preview_rect(start, end):
    var min_pos = Vector3i(min(start.x, end.x), 0, min(start.z, end.z))
    var max_pos = Vector3i(max(start.x, end.x), 0, max(start.z, end.z))
    
    for x in range(min_pos.x, max_pos.x + 1):
        for z in range(min_pos.z, max_pos.z + 1):
            grid_map.set_cell_item(Vector3i(x, 0, z), current_block_id, PREVIEW_LAYER)

func draw_line(start, end):
    var points = bresenham_line(start, end)
    var current_layer = layer_selector.get_selected_id()
    
    # Сохраняем в историю перед изменением
    var affected_cells = []
    for point in points:
        affected_cells.append({
            "pos": point,
            "old": grid_map.get_cell_item(point, current_layer),
            "new": current_block_id
        })
    
    add_to_history(affected_cells, current_layer)
    
    # Применяем изменения
    for point in points:
        grid_map.set_cell_item(point, current_block_id, current_layer)

func draw_rect(start, end):
    var min_pos = Vector3i(min(start.x, end.x), 0, min(start.z, end.z))
    var max_pos = Vector3i(max(start.x, end.x), 0, max(start.z, end.z))
    var current_layer = layer_selector.get_selected_id()
    
    # Сохраняем в историю перед изменением
    var affected_cells = []
    for x in range(min_pos.x, max_pos.x + 1):
        for z in range(min_pos.z, max_pos.z + 1):
            var pos = Vector3i(x, 0, z)
            affected_cells.append({
                "pos": pos,
                "old": grid_map.get_cell_item(pos, current_layer),
                "new": current_block_id
            })
    
    add_to_history(affected_cells, current_layer)
    
    # Применяем изменения
    for x in range(min_pos.x, max_pos.x + 1):
        for z in range(min_pos.z, max_pos.z + 1):
            grid_map.set_cell_item(Vector3i(x, 0, z), current_block_id, current_layer)

# Алгоритм Брезенхема для рисования линий
func bresenham_line(start, end):
    var points = []
    var x0 = start.x
    var y0 = start.z
    var x1 = end.x
    var y1 = end.z
    
    var dx = abs(x1 - x0)
    var dy = abs(y1 - y0)
    var sx = 1 if x0 < x1 else -1
    var sy = 1 if y0 < y1 else -1
    var err = dx - dy
    
    while true:
        points.append(Vector3i(x0, 0, y0))
        if x0 == x1 and y0 == y1:
            break
        var e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy
    
    return points

# Обновленная функция для истории действий
func add_to_history(cells, layer):
    var action = {
        "cells": cells,
        "layer": layer,
        "timestamp": Time.get_unix_time_from_system()
    }
    undo_stack.append(action)
    if undo_stack.size() > history_max_size:
        undo_stack.pop_front()
    redo_stack.clear()
