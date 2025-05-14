extends Node3D

class_name MapEditor

signal map_saved(map_name)
signal map_loaded(map_data)
signal error_occurred(message)
signal tool_changed(tool_type)
signal block_selected(block_id)

const BLOCK_SCENE = preload("res://blocks/Block.tscn")
const SAVE_DIR = "user://maps/"
const HISTORY_MAX_SIZE = 50
const GRID_MATERIAL = preload("res://materials/grid_material.tres")

enum Tools {BRUSH, ERASER, SELECT, FILL, MOVE}
enum BrushShapes {SQUARE, CIRCLE}
enum SelectionModes {SINGLE, RECT, POLYGON}

@export var default_brush_size := 1
@export var max_brush_size := 10
@export var grid_size := Vector3(1, 1, 1)
@export var max_layers := 5

var current_tool := Tools.BRUSH
var brush_size := default_brush_size
var brush_shape := BrushShapes.SQUARE
var selected_block := 0
var grid_snap := true
var current_layer := 0
var selection_mode := SelectionModes.SINGLE

var map_data := {
    "name": "Untitled",
    "blocks": [],
    "layers": [],
    "materials": {},
    "version": "1.1"
}

var history := []
var redo_stack := []
var selected_blocks := []
var clipboard := []
var is_dragging := false
var drag_start_pos := Vector3.ZERO
var camera_controller: CameraController
var block_library: BlockLibrary

@onready var grid := $Grid as MeshInstance3D
@onready var blocks_node := $Blocks as Node3D
@onready var ui := $UI/CanvasLayer as CanvasLayer

func _ready():
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    _initialize_grid()
    _setup_camera()
    _load_block_library()
    _create_new_map()
    _connect_ui_signals()

func _process(delta):
    _update_cursor_preview()
    _handle_hotkeys()

func _input(event):
    _handle_mouse_input(event)
    _handle_tool_shortcuts(event)

#region Initialization
func _initialize_grid():
    grid.mesh = BoxMesh.new()
    grid.mesh.size = Vector3(100, 0.1, 100)
    grid.material_override = GRID_MATERIAL

func _setup_camera():
    camera_controller = $CameraController as CameraController
    camera_controller.setup(grid_size)

func _load_block_library():
    block_library = BlockLibrary.new()
    block_library.load_from_folder("res://blocks/library/")
    ui.update_block_palette(block_library.get_all_blocks())
    selected_block = block_library.get_default_block_id()

func _create_new_map():
    map_data = {
        "name": "Untitled",
        "blocks": [],
        "layers": _create_default_layers(),
        "materials": {},
        "version": "1.1"
    }
    _clear_visual_blocks()

func _create_default_layers() -> Array:
    return [{
        "name": "Base",
        "visible": true,
        "locked": false,
        "opacity": 1.0
    }]
#endregion

#region Core Editing Functions
func _start_operation():
    is_dragging = true
    drag_start_pos = _get_snapped_mouse_position()
    
    match current_tool:
        Tools.BRUSH, Tools.ERASER:
            _paint_operation()
        Tools.SELECT:
            _start_selection()
        Tools.FILL:
            _start_fill()

func _end_operation():
    is_dragging = false
    _commit_to_history()

func _paint_operation():
    var affected_blocks = _get_affected_blocks()
    var operation = {
        "type": "PAINT",
        "data": _get_current_state(affected_blocks),
        "tool": current_tool,
        "layer": current_layer
    }
    
    for block_pos in affected_blocks:
        if current_tool == Tools.BRUSH:
            _place_block(block_pos)
        else:
            _remove_block(block_pos)
    
    history.append(operation)
    _limit_history()

func _start_selection():
    var mouse_pos = _get_snapped_mouse_position()
    if Input.is_key_pressed(KEY_CTRL):
        selection_mode = SelectionModes.RECT
        drag_start_pos = mouse_pos
    else:
        _handle_single_selection(mouse_pos)

func _handle_single_selection(pos: Vector3):
    var block = _get_block_at(pos)
    if block:
        if Input.is_key_pressed(KEY_SHIFT):
            _toggle_block_selection(block)
        else:
            _clear_and_select_block(block)

func _toggle_block_selection(block):
    if block in selected_blocks:
        selected_blocks.erase(block)
        block.set_selected(false)
    else:
        selected_blocks.append(block)
        block.set_selected(true)

func _clear_and_select_block(block):
    _clear_selection()
    selected_blocks = [block]
    block.set_selected(true)

func _start_fill():
    var start_pos = _get_snapped_mouse_position()
    var target_block = _get_block_at(start_pos)
    if target_block:
        var fill_operation = {
            "type": "FILL",
            "data": _get_fill_region(target_block),
            "original_block": target_block.block_id,
            "new_block": selected_block
        }
        _apply_fill(fill_operation)

func _apply_fill(operation: Dictionary):
    var new_blocks = []
    for pos in operation.data:
        _remove_block(pos)
        _place_block(pos)
        new_blocks.append(pos)
    
    history.append({
        "type": "FILL",
        "data": operation.data,
        "original_block": operation.new_block,
        "new_block": operation.original_block
    })
#endregion

#region Block Management
func _place_block(position: Vector3):
    _remove_existing_block(position)
    
    var block_data = {
        "position": position,
        "block_id": selected_block,
        "layer": current_layer
    }
    
    map_data.blocks.append(block_data)
    _create_visual_block(block_data)

func _remove_block(position: Vector3):
    var removed = false
    for i in range(map_data.blocks.size() -1, -1, -1):
        var block = map_data.blocks[i]
        if block.position == position && block.layer == current_layer:
            map_data.blocks.remove_at(i)
            removed = true
    
    if removed:
        _remove_visual_block(position)

func _remove_existing_block(pos: Vector3):
    for block in blocks_node.get_children():
        if block.position == pos && block.layer == current_layer:
            block.queue_free()

func _create_visual_block(data: Dictionary):
    var block = BLOCK_SCENE.instantiate()
    block.setup(data, block_library)
    blocks_node.add_child(block)

func _remove_visual_block(pos: Vector3):
    for block in blocks_node.get_children():
        if block.position == pos && block.layer == current_layer:
            block.queue_free()

func _get_block_at(pos: Vector3) -> Node3D:
    for block in blocks_node.get_children():
        if block.position == pos && block.layer == current_layer:
            return block
    return null
#endregion

#region History Management
func undo():
    if history.is_empty():
        return
    
    var operation = history.pop_back()
    redo_stack.append(operation)
    _restore_state(operation.data)

func redo():
    if redo_stack.is_empty():
        return
    
    var operation = redo_stack.pop_back()
    history.append(operation)
    _restore_state(operation.data)

func _restore_state(state: Array):
    for entry in state:
        if entry.exists:
            _place_block(entry.position)
        else:
            _remove_block(entry.position)

func _commit_to_history():
    while history.size() > HISTORY_MAX_SIZE:
        history.pop_front()

func _limit_history():
    if history.size() > HISTORY_MAX_SIZE * 1.5:
        history = history.slice(history.size() - HISTORY_MAX_SIZE, history.size())
#endregion

#region Helper Functions
func _get_snapped_mouse_position() -> Vector3:
    var pos = _get_raw_mouse_position()
    return _snap_to_grid(pos) if grid_snap else pos

func _get_raw_mouse_position() -> Vector3:
    var mouse_pos = get_viewport().get_mouse_position()
    var ray_length = 1000
    var from = camera_controller.project_ray_origin(mouse_pos)
    var to = from + camera_controller.project_ray_normal(mouse_pos) * ray_length
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    var result = space_state.intersect_ray(query)
    return result.position if result else Vector3.ZERO

func _snap_to_grid(pos: Vector3) -> Vector3:
    return pos.snapped(grid_size)

func _get_affected_blocks() -> Array:
    var current_pos = _get_snapped_mouse_position()
    match brush_shape:
        BrushShapes.SQUARE:
            return _calculate_square_area(drag_start_pos, current_pos)
        BrushShapes.CIRCLE:
            return _calculate_circle_area(drag_start_pos, current_pos)
    return []

func _calculate_square_area(start: Vector3, end: Vector3) -> Array:
    var positions := []
    var min_pos = start
    var max_pos = end
    if brush_size > 1:
        min_pos -= Vector3(brush_size, 0, brush_size) * 0.5
        max_pos += Vector3(brush_size, 0, brush_size) * 0.5
    
    for x in range(min_pos.x, max_pos.x + 1):
        for z in range(min_pos.z, max_pos.z + 1):
            positions.append(Vector3(x, start.y, z))
    return positions

func _update_cursor_preview():
    ui.update_cursor_preview(
        _get_snapped_mouse_position(),
        brush_size,
        brush_shape
    )

func _clear_selection():
    for block in selected_blocks:
        block.set_selected(false)
    selected_blocks.clear()
#endregion

#region Save/Load
func save_map(file_name: String):
    var save_path = SAVE_DIR.path_join(file_name + ".map")
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    
    if file:
        map_data.name = file_name
        var json = JSON.stringify(map_data)
        file.store_string(json)
        map_saved.emit(file_name)
    else:
        error_occurred.emit("Failed to save map: %s" % file_name)

func load_map(file_name: String):
    var load_path = SAVE_DIR.path_join(file_name + ".map")
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
        _create_visual_block(block_data)
#endregion

#region UI Integration
func _connect_ui_signals():
    ui.tool_selected.connect(_on_tool_selected)
    ui.block_selected.connect(_on_block_selected)
    ui.brush_size_changed.connect(_on_brush_size_changed)
    ui.grid_toggled.connect(_on_grid_toggled)

func _on_tool_selected(tool: Tools):
    current_tool = tool
    tool_changed.emit(tool)

func _on_block_selected(block_id: int):
    selected_block = block_id
    block_selected.emit(block_id)

func _on_brush_size_changed(size: int):
    brush_size = clampi(size, 1, max_brush_size)

func _on_grid_toggled(enabled: bool):
    grid_snap = enabled
    grid.visible = enabled
#endregion

#region Hotkeys
func _handle_hotkeys():
    if Input.is_key_pressed(KEY_CTRL) and Input.is_key_just_pressed(KEY_S):
        ui.show_save_dialog()

func _handle_tool_shortcuts(event: InputEvent):
    if event.is_action_pressed("editor_undo"):
        undo()
    elif event.is_action_pressed("editor_redo"):
        redo()
    elif event.is_action_pressed("editor_copy"):
        _copy_selected()
    elif event.is_action_pressed("editor_paste"):
        _paste_clipboard()
#endregion

#region Clipboard
func _copy_selected():
    clipboard.clear()
    for block in selected_blocks:
        clipboard.append(block.get_data())

func _paste_clipboard():
    var offset = _calculate_paste_offset()
    for block_data in clipboard:
        var new_pos = block_data.position + offset
        _place_block(new_pos)
#endregion

func _calculate_paste_offset() -> Vector3:
    return _get_snapped_mouse_position() - clipboard[0].position

func _clear_visual_blocks():
    for block in blocks_node.get_children():
        block.queue_free()

func _get_current_state(blocks: Array) -> Array:
    var state = []
    for pos in blocks:
        state.append({
            "position": pos,
            "exists": _block_exists_at(pos)
        })
    return state

func _block_exists_at(pos: Vector3) -> bool:
    for block in map_data.blocks:
        if block.position == pos && block.layer == current_layer:
            return true
    return false
