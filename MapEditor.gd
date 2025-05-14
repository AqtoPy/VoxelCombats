# MapEditor.gd
extends Node3D

class_name MapEditor

signal map_saved(map_name)
signal map_loaded(map_data)
signal error_occurred(message)

const BLOCK_SCENE = preload("res://blocks/Block.tscn")
const SAVE_DIR = "user://maps/"
const HISTORY_MAX_SIZE = 50

enum Tools {BRUSH, ERASER, SELECT, FILL}
enum BrushShapes {SQUARE, CIRCLE}

# Настройки редактора
var current_tool = Tools.BRUSH
var brush_size = 1
var brush_shape = BrushShapes.SQUARE
var selected_block = 0
var grid_snap = true
var grid_size = Vector3(1, 1, 1)

# Состояние редактора
var map_data = {}
var history = []
var redo_stack = []
var selected_blocks = []
var clipboard = []

@onready var camera_controller = $CameraController
@onready var ui = $UI
@onready var grid = $Grid
@onready var block_library = $BlockLibrary

var is_dragging = false
var drag_start_pos = Vector3.ZERO
var current_layer = 0


func _ready():
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    _setup_input()
    _update_grid()
    _load_block_library()
    _create_new_map()


func _create_new_map():
    map_data = {
        "name": "Untitled",
        "blocks": [],
        "layers": [{
            "name": "Base",
            "blocks": []
        }],
        "materials": {},
        "version": "1.0"
    }
    _clear_visual_blocks()


func _setup_input():
    InputMap.add_action("editor_undo")
    InputMap.add_action("editor_redo")
    InputMap.action_add_event("editor_undo", InputEventKey.create_with_keycode(KEY_Z | KEY_CTRL))
    InputMap.action_add_event("editor_redo", InputEventKey.create_with_keycode(KEY_Y | KEY_CTRL))


func _input(event):
    if event is InputEventMouseMotion:
        _handle_mouse_movement()
    
    if event.is_action_pressed("editor_undo"):
        undo()
    if event.is_action_pressed("editor_redo"):
        redo()
    
    if event.is_action_pressed("editor_primary_action"):
        _start_operation()
    if event.is_action_released("editor_primary_action"):
        _end_operation()


func _handle_mouse_movement():
    var mouse_pos = _get_mouse_world_position()
    if grid_snap:
        mouse_pos = _snap_to_grid(mouse_pos)
    
    ui.update_cursor_position(mouse_pos)


func _start_operation():
    is_dragging = true
    drag_start_pos = _get_mouse_world_position()
    
    match current_tool:
        Tools.BRUSH, Tools.ERASER:
            _paint_blocks()
        Tools.SELECT:
            _start_selection()


func _end_operation():
    is_dragging = false
    _commit_to_history()


func _paint_blocks():
    var blocks = _get_affected_blocks()
    var operation = {
        "type": "PAINT",
        "data": _get_current_state(blocks),
        "tool": current_tool
    }
    
    for block_pos in blocks:
        if current_tool == Tools.BRUSH:
            _place_block(block_pos)
        else:
            _remove_block(block_pos)
    
    history.append(operation)
    _limit_history()


func _place_block(position: Vector3):
    var block_data = {
        "position": position,
        "block_id": selected_block,
        "layer": current_layer
    }
    
    _remove_existing_block(position)
    map_data.blocks.append(block_data)
    
    var new_block = BLOCK_SCENE.instantiate()
    new_block.setup(block_data, block_library)
    add_child(new_block)


func _remove_block(position: Vector3):
    for i in range(map_data.blocks.size() -1, -1, -1):
        var block = map_data.blocks[i]
        if block.position == position && block.layer == current_layer:
            map_data.blocks.remove_at(i)
            _remove_visual_block(position)
            break


func undo():
    if history.is_empty():
        return
    
    var operation = history.pop_back()
    redo_stack.push_back(operation)
    
    match operation.type:
        "PAINT":
            _restore_state(operation.data)


func redo():
    if redo_stack.is_empty():
        return
    
    var operation = redo_stack.pop_back()
    history.append(operation)
    
    match operation.type:
        "PAINT":
            if operation.tool == Tools.BRUSH:
                _remove_blocks(operation.data)
            else:
                _place_blocks(operation.data)


func save_map(file_name: String):
    var save_path = SAVE_DIR + file_name + ".map"
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    
    if file:
        var json = JSON.stringify(map_data)
        file.store_string(json)
        map_saved.emit(file_name)
    else:
        error_occurred.emit("Failed to save map: %s" % file_name)


func load_map(file_name: String):
    var load_path = SAVE_DIR + file_name + ".map"
    var file = FileAccess.open(load_path, FileAccess.READ)
    
    if file:
        var json = file.get_as_text()
        map_data = JSON.parse_string(json)
        _rebuild_visual_blocks()
        map_loaded.emit(map_data)
    else:
        error_occurred.emit("Failed to load map: %s" % file_name)


func _rebuild_visual_blocks():
    _clear_visual_blocks()
    for block_data in map_data.blocks:
        var block = BLOCK_SCENE.instantiate()
        block.setup(block_data, block_library)
        add_child(block)


func _clear_visual_blocks():
    for child in get_children():
        if child is MapBlock:
            child.queue_free()


func _get_affected_blocks() -> Array:
    var current_pos = _get_mouse_world_position()
    var positions = []
    
    match brush_shape:
        BrushShapes.SQUARE:
            positions = _get_square_area(drag_start_pos, current_pos)
        BrushShapes.CIRCLE:
            positions = _get_circle_area(drag_start_pos, current_pos)
    
    return positions


func _get_square_area(start: Vector3, end: Vector3) -> Array:
    var positions = []
    var min_pos = Vector3(
        min(start.x, end.x),
        min(start.y, end.y),
        min(start.z, end.z)
    )
    var max_pos = Vector3(
        max(start.x, end.x),
        max(start.y, end.y),
        max(start.z, end.z)
    )
    
    for x in range(min_pos.x, max_pos.x +1):
        for y in range(min_pos.y, max_pos.y +1):
            for z in range(min_pos.z, max_pos.z +1):
                positions.append(Vector3(x, y, z))
    
    return positions


func _get_circle_area(center: Vector3, radius_pos: Vector3) -> Array:
    var radius = center.distance_to(radius_pos)
    var positions = []
    
    # Реализация алгоритма Брезенхэма для 3D сферы
    # ... (сложная математическая реализация)
    
    return positions


func _commit_to_history():
    if history.size() > HISTORY_MAX_SIZE:
        history.pop_front()


func _get_current_state(blocks: Array) -> Array:
    var state = []
    for pos in blocks:
        var block = _get_block_at(pos)
        state.append({
            "position": pos,
            "exists": block != null,
            "data": block.get_data() if block else null
        })
    return state


func _restore_state(state: Array):
    for entry in state:
        if entry.exists:
            _place_block(entry.position)
        else:
            _remove_block(entry.position)


func _update_grid():
    grid.update_grid(grid_size, grid_snap)


func _snap_to_grid(pos: Vector3) -> Vector3:
    return pos.snapped(grid_size)


func _get_mouse_world_position() -> Vector3:
    var mouse_pos = get_viewport().get_mouse_position()
    var ray_length = 1000
    var from = camera.project_ray_origin(mouse_pos)
    var to = from + camera.project_ray_normal(mouse_pos) * ray_length
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    var result = space_state.intersect_ray(query)
    
    return result.position if result else Vector3.ZERO


# Block Library Management
func _load_block_library():
    block_library.load_blocks("res://blocks/library/")
    ui.update_block_palette(block_library.get_blocks())


func select_block(block_id: int):
    selected_block = block_id
    ui.update_selected_block(block_library.get_block(block_id))


# UI Signal Handlers
func _on_ui_tool_selected(tool: int):
    current_tool = tool


func _on_ui_brush_size_changed(size: int):
    brush_size = size


func _on_ui_grid_toggled(enabled: bool):
    grid_snap = enabled
    _update_grid()


func _on_ui_save_requested(file_name):
    save_map(file_name)


func _on_ui_load_requested(file_name):
    load_map(file_name)


# MapBlock Class (MapBlock.gd)
class_name MapBlock
extends MeshInstance3D

var block_data = {}
var is_selected = false

func setup(data: Dictionary, library: BlockLibrary):
    block_data = data
    var block_info = library.get_block(data.block_id)
    mesh = block_info.mesh
    material_override = block_info.material


func get_data() -> Dictionary:
    return block_data


func set_selected(value: bool):
    is_selected = value
    if value:
        material_override.albedo_color = Color(1, 0.5, 0)
    else:
        material_override.albedo_color = Color.WHITE
