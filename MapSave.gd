# Добавляем в существующий код
var saved_maps_dir = "user://maps/"

func save_map():
    var map_name = $UI/MapNameEdit.text.strip_edges()
    if map_name == "":
        update_status("Введите название карты!", Color.RED)
        return
    
    var map_data = {
        "cells": [],
        "settings": {
            "cell_size": grid_map.cell_size,
            "layers": []
        }
    }
    
    # Сохраняем все слои
    for layer in grid_map.get_layers_count():
        var layer_data = []
        for cell in grid_map.get_used_cells(layer):
            layer_data.append({
                "pos": {"x": cell.x, "y": cell.y, "z": cell.z},
                "block": grid_map.get_cell_item(cell, layer)
            })
        map_data["settings"]["layers"].append({
            "enabled": grid_map.is_layer_enabled(layer)
        })
        map_data["cells"].append(layer_data)
    
    # Создаем папку если нужно
    if not DirAccess.dir_exists_absolute(saved_maps_dir):
        DirAccess.make_dir_absolute(saved_maps_dir)
    
    # Сохраняем в файл
    var file_path = saved_maps_dir.path_join(map_name + ".map")
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(map_data, "\t"))
    file.close()
    
    update_status("Карта '%s' сохранена!" % map_name, Color.GREEN)

func load_map(map_name: String):
    var file_path = saved_maps_dir.path_join(map_name + ".map")
    if not FileAccess.file_exists(file_path):
        update_status("Файл карты не найден!", Color.RED)
        return
    
    # Очищаем текущую карту
    grid_map.clear()
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    var map_data = JSON.parse_string(file.get_as_text())
    
    # Загружаем настройки
    grid_map.cell_size = Vector3(
        map_data["settings"]["cell_size"]["x"],
        map_data["settings"]["cell_size"]["y"],
        map_data["settings"]["cell_size"]["z"]
    )
    
    # Загружаем слои
    for layer in map_data["cells"].size():
        if layer >= grid_map.get_layers_count():
            grid_map.add_layer()
        
        grid_map.set_layer_enabled(layer, map_data["settings"]["layers"][layer]["enabled"])
        
        for cell in map_data["cells"][layer]:
            var pos = Vector3i(
                cell["pos"]["x"],
                cell["pos"]["y"],
                cell["pos"]["z"]
            )
            grid_map.set_cell_item(pos, cell["block"], layer)
    
    update_status("Карта '%s' загружена!" % map_name, Color.GREEN)
