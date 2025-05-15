extends Node3D

# Настройки редактора
enum Tool {BRUSH, ERASER, FILL, LINE, RECTANGLE}
var current_tool = Tool.BRUSH
var grid_visible = true
var show_grid = true
var history_max_size = 20
var undo_stack = []
var redo_stack = []

# Настройки камеры
var camera_sensitivity = 0.005
var camera_distance = 10.0
var camera_rotation = Vector2(0, 0)

@onready var grid_map = $GridMap
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var mesh_lib = preload("res://Blocks.tres")

# UI элементы
@onready var tools_panel = $UI/ToolsPanel
@onready var status_label = $UI/StatusLabel
@onready var layer_selector = $UI/LayerSelector

func _ready():
    setup_grid()
    setup_ui()
    update_camera()
    create_ground_plane()

func setup_grid():
    grid_map.cell_size = Vector3(1, 1, 1)
    grid_map.mesh_library = mesh_lib
    grid_map.set_layer_enabled(0, true)

func setup_ui():
    # Создаем кнопки инструментов
    var tools = {
        "Кисть": Tool.BRUSH,
        "Ластик": Tool.ERASER,
        "Заливка": Tool.FILL,
        "Линия": Tool.LINE,
        "Прямоугольник": Tool.RECTANGLE
    }
    
    for tool in tools:
        var btn = Button.new()
        btn.text = tool
        btn.toggle_mode = true
        btn.pressed.connect(_on_tool_selected.bind(tools[tool]))
        tools_panel.add_child(btn)
    
    # Настройка слоев
    for i in 3:
        layer_selector.add_item("Слой %d" % (i+1), i)
    layer_selector.selected = 0

func create_ground_plane():
    var plane = MeshInstance3D.new()
    plane.mesh = PlaneMesh.new()
    plane.mesh.size = Vector2(20, 20)
    plane.position = Vector3(10, 0, 10)
    var static_body = StaticBody3D.new()
    static_body.add_child(CollisionShape3D.new())
    static_body.get_child(0).shape = plane.mesh.create_trimesh_shape()
    add_child(plane)
    add_child(static_body)

func _input(event):
    handle_camera_input(event)
    handle_tools_input(event)
    handle_hotkeys(event)

func handle_camera_input(event):
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
        camera_rotation.x -= event.relative.x * camera_sensitivity
        camera_rotation.y = clamp(camera_rotation.y - event.relative.y * camera_sensitivity, -1.0, 1.0)
        update_camera()
    
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = clamp(camera_distance - 1.0, 5.0, 30.0)
            update_camera()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = clamp(camera_distance + 1.0, 5.0, 30.0)
            update_camera()

func handle_tools_input(event):
    if event is InputEventMouseButton and event.pressed:
        var start_pos = get_mouse_grid_position()
        if start_pos == null: return
        
        match current_tool:
            Tool.BRUSH, Tool.ERASER:
                handle_single_placement(event, start_pos)
            Tool.LINE, Tool.RECTANGLE:
                if event.button_index == MOUSE_BUTTON_LEFT:
                    handle_shape_start(start_pos)
            Tool.FILL:
                if event.button_index == MOUSE_BUTTON_LEFT:
                    flood_fill(start_pos)

func handle_hotkeys(event):
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_Z if event.ctrl_pressed:
                undo_action()
            KEY_Y if event.ctrl_pressed:
                redo_action()
            KEY_G:
                toggle_grid()

func get_mouse_grid_position():
    var mouse_pos = get_viewport().get_mouse_position()
    var from = camera.project_ray_origin(mouse_pos)
    var to = from + camera.project_ray_normal(mouse_pos) * 1000
    
    var result = get_world_3d().direct_space_state.intersect_ray(
        PhysicsRayQueryParameters3D.create(from, to)
    
    if result:
        return grid_map.local_to_map(result.position)
    return null

func handle_single_placement(event, pos):
    var current_layer = layer_selector.get_selected_id()
    var prev_block = grid_map.get_cell_item(pos, current_layer)
    
    if event.button_index == MOUSE_BUTTON_LEFT:
        var new_block = current_block_id if current_tool == Tool.BRUSH else -1
        add_to_history(pos, current_layer, prev_block, new_block)
        grid_map.set_cell_item(pos, new_block, current_layer)
    elif event.button_index == MOUSE_BUTTON_RIGHT:
        grid_map.set_cell_item(pos, -1, current_layer)

func handle_shape_start(start_pos):
    var current_layer = layer_selector.get_selected_id()
    var end_pos = await get_mouse_release_position()
    if current_tool == Tool.LINE:
        draw_line(start_pos, end_pos)
    elif current_tool == Tool.RECTANGLE:
        draw_rect(start_pos, end_pos)

func draw_line(start, end):
    var points = bresenham_line(start, end)
    for point in points:
        grid_map.set_cell_item(point, current_block_id, layer_selector.get_selected_id())

func draw_rect(start, end):
    var min_pos = Vector3i(min(start.x, end.x), 0, min(start.z, end.z))
    var max_pos = Vector3i(max(start.x, end.x), 0, max(start.z, end.z))
    
    for x in range(min_pos.x, max_pos.x + 1):
        for z in range(min_pos.z, max_pos.z + 1):
            grid_map.set_cell_item(Vector3i(x, 0, z), current_block_id, layer_selector.get_selected_id())

func flood_fill(start_pos):
    var target_block = grid_map.get_cell_item(start_pos, layer_selector.get_selected_id())
    if target_block == current_block_id: return
    
    var queue = [start_pos]
    var visited = {}
    
    while queue.size() > 0:
        var pos = queue.pop_front()
        if visited.has(pos): continue
        visited[pos] = true
        
        if grid_map.get_cell_item(pos, layer_selector.get_selected_id()) == target_block:
            grid_map.set_cell_item(pos, current_block_id, layer_selector.get_selected_id())
            queue.append_array(get_neighbors(pos))

func get_neighbors(pos):
    return [
        pos + Vector3i.RIGHT,
        pos + Vector3i.LEFT,
        pos + Vector3i.FORWARD,
        pos + Vector3i.BACK
    ]

func add_to_history(pos, layer, old, new):
    undo_stack.append({
        "position": pos,
        "layer": layer,
        "old": old,
        "new": new
    })
    if undo_stack.size() > history_max_size:
        undo_stack.pop_front()

func undo_action():
    if undo_stack.size() == 0: return
    var action = undo_stack.pop_back()
    grid_map.set_cell_item(action.position, action.old, action.layer)
    redo_stack.push_back(action)

func redo_action():
    if redo_stack.size() == 0: return
    var action = redo_stack.pop_back()
    grid_map.set_cell_item(action.position, action.new, action.layer)
    undo_stack.push_back(action)

func toggle_grid():
    show_grid = !show_grid
    grid_map.visible = show_grid
    update_status("Сетка: " + ("ВКЛ" if show_grid else "ВЫКЛ"))

func update_camera():
    camera_pivot.rotation = Vector3(camera_rotation.y, camera_rotation.x, 0)
    camera.position.z = camera_distance

func update_status(text):
    status_label.text = text
    get_tree().create_timer(2.0).timeout.connect(func(): status_label.text = "")

func _on_tool_selected(tool):
    current_tool = tool
    update_status("Выбран инструмент: " + tools_panel.get_child(tool).text)

func _on_layer_selected(index):
    for i in 3:
        grid_map.set_layer_enabled(i, i == index)
    update_status("Активный слой: %d" % (index + 1))
