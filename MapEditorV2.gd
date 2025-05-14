extends Node3D

var current_block = 0
var blocks = [
    preload("res://BlocksMesh.tres")
]
var saved_maps_dir = "user://maps/"
var camera_rotation = Vector2(0, 0)
var camera_distance = 10.0
var is_rotating = false
var grid_plane: MeshInstance3D
var grid_size = Vector2(20, 20) # Размер сетки

@onready var grid_map = $GridMap
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var ui = $UI
@onready var map_name_edit = $UI/MapNameEdit
@onready var save_button = $UI/SaveButton
@onready var load_button = $UI/LoadButton
@onready var exit_button = $UI/ExitButton
@onready var block_selector = $UI/BlockSelector
@onready var status_label = $UI/StatusLabel

func _ready():
    DirAccess.make_dir_absolute(saved_maps_dir)
    create_grid_plane() # Создаем видимую сетку
    setup_ui()
    update_camera_position()
    load_saved_maps_list()

func create_grid_plane():
    # Создаем визуальную сетку в качестве пола
    var plane_mesh = PlaneMesh.new()
    plane_mesh.size = Vector2(grid_size.x, grid_size.y)
    plane_mesh.subdivide_width = grid_size.x
    plane_mesh.subdivide_depth = grid_size.y
    
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    
    grid_plane = MeshInstance3D.new()
    grid_plane.mesh = plane_mesh
    grid_plane.material_override = material
    grid_plane.position = Vector3(grid_size.x/2, 0, grid_size.y/2)
    add_child(grid_plane)

func setup_ui():
    # Настройка элементов UI
    map_name_edit.placeholder_text = "Введите название карты"
    save_button.text = "Сохранить"
    load_button.text = "Загрузить"
    exit_button.text = "Выход"
    
    # Создаем кнопки для выбора блоков
    for i in range(blocks.size()):
        var btn = Button.new()
        btn.text = "Блок %d" % (i + 1)
        btn.custom_minimum_size = Vector2(80, 40)
        btn.pressed.connect(_on_block_selected.bind(i))
        block_selector.add_child(btn)
    
    # Подключаем сигналы
    save_button.pressed.connect(_on_save_button_pressed)
    load_button.pressed.connect(_on_load_button_pressed)
    exit_button.pressed.connect(_on_exit_button_pressed)

func _input(event):
    # Вращение камеры
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
    
    # Размещение/удаление блоков
    if event is InputEventMouseButton and event.pressed:
        var mouse_pos = event.position
        var ray_length = 1000
        var from = camera.project_ray_origin(mouse_pos)
        var to = from + camera.project_ray_normal(mouse_pos) * ray_length
        var params = PhysicsRayQueryParameters3D.create(from, to)
        var result = get_world_3d().direct_space_state.intersect_ray(params)
        
        if result:
            var cell_pos = grid_map.world_to_map(result.position)
            # Ограничиваем размещение блоков в пределах сетки
            if cell_pos.x >= 0 and cell_pos.x < grid_size.x and cell_pos.z >= 0 and cell_pos.z < grid_size.y:
                if event.button_index == MOUSE_BUTTON_LEFT:
                    grid_map.set_cell_item(cell_pos, current_block)
                elif event.button_index == MOUSE_BUTTON_RIGHT:
                    grid_map.set_cell_item(cell_pos, -1)

func update_camera_position():
    var target_pos = Vector3(grid_size.x/2, 0, grid_size.y/2)
    camera_pivot.global_transform.origin = target_pos
    camera_pivot.rotation = Vector3(camera_rotation.y, camera_rotation.x, 0)
    camera.position = Vector3(0, 0, camera_distance)
    camera.look_at(target_pos, Vector3.UP)

func save_map():
    var map_name = map_name_edit.text.strip_edges()
    if map_name == "":
        show_status("Введите название карты!", Color.RED)
        return
    
    var map_data = []
    for cell in grid_map.get_used_cells():
        map_data.append({
            "position": cell,
            "block": grid_map.get_cell_item(cell)
        })
    
    var file_path = saved_maps_dir.path_join(map_name + ".map")
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    file.store_var(map_data)
    file.close()
    
    show_status("Карта '%s' сохранена!" % map_name, Color.GREEN)
    load_saved_maps_list()
    update_main_maps()

func load_map(map_name: String):
    grid_map.clear()
    var file_path = saved_maps_dir.path_join(map_name + ".map")
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, FileAccess.READ)
        var map_data = file.get_var()
        for cell in map_data:
            grid_map.set_cell_item(cell.position, cell.block)
        show_status("Карта '%s' загружена!" % map_name, Color.GREEN)
    else:
        show_status("Карта не найдена!", Color.RED)

func load_saved_maps_list():
    var load_menu = $UI/LoadMenu
    for child in load_menu.get_children():
        child.queue_free()
    
    var dir = DirAccess.open(saved_maps_dir)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".map"):
                var btn = Button.new()
                btn.text = file_name.trim_suffix(".map")
                btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                btn.pressed.connect(_on_map_load_button_pressed.bind(btn.text))
                load_menu.add_child(btn)
            file_name = dir.get_next()

func show_status(message: String, color: Color):
    status_label.text = message
    status_label.modulate = color
    
    var timer = get_tree().create_timer(3.0)
    timer.timeout.connect(func(): status_label.text = "")

func update_main_maps():
    var main = get_node("/root/Main")
    if main and main.has_method("load_custom_maps"):
        main.load_custom_maps()

func _on_block_selected(block_index: int):
    current_block = block_index
    show_status("Выбран блок %d" % (block_index + 1), Color.WHITE)

func _on_save_button_pressed():
    save_map()

func _on_load_button_pressed():
    $UI/LoadMenu.visible = not $UI/LoadMenu.visible

func _on_map_load_button_pressed(map_name: String):
    load_map(map_name)
    map_name_edit.text = map_name
    $UI/LoadMenu.visible = false

func _on_exit_button_pressed():
    get_tree().change_scene_to_file("res://main_menu.tscn")
