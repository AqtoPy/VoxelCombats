extends Node3D

signal weapon_changed
signal update_ammo
signal update_weapon_stack
signal hit_successful
signal add_signal_to_hud
signal connect_weapon_to_hud

@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int = 3
@export var hands_scene: PackedScene
@export var crosshair_texture: Texture2D

@onready var bullet_point = get_node("%BulletPoint")
@onready var debug_bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")
@onready var crosshair = preload("res://UI/Crosshair.tscn")

var hands_instance: Node3D
var current_crosshair: Control
var next_weapon: WeaponSlot
var spray_profiles: Dictionary = {}
var _count = 0
var shot_tween

# Магазин оружия (пример)
var weapon_shop = {
    "pistol": {"cost": 100, "scene": preload("res://Weapons/Pistol.tscn")},
    "rifle": {"cost": 300, "scene": preload("res://Weapons/Rifle.tscn")},
    "shotgun": {"cost": 500, "scene": preload("res://Weapons/Shotgun.tscn")}
}

@export var weapon_stack: Array[WeaponSlot] # Массив оружия у игрока
var current_weapon_slot: WeaponSlot = null
var available_weapons: Array[WeaponSlot] = [] # Все доступные оружия

func _ready() -> void:
    # Инициализация рук
    hands_instance = hands_scene.instantiate()
    add_child(hands_instance)
    
    # Инициализация прицела
    current_crosshair = crosshair.instantiate()
    get_tree().root.get_node("HUD").add_child(current_crosshair)
    
    if weapon_stack.is_empty():
        push_error("Weapon Stack is empty, please populate with weapons")
    else:
        animation_player.animation_finished.connect(_on_animation_finished)
        for i in weapon_stack:
            initialize_weapon(i)
        current_weapon_slot = weapon_stack[0]
        if check_valid_weapon_slot():
            enter()
            update_weapon_stack.emit(weapon_stack)

func initialize_weapon(_weapon_slot: WeaponSlot):
    if !_weapon_slot or !_weapon_slot.weapon:
        return
        
    # Загружаем сцену оружия
    var weapon_scene = _weapon_slot.weapon.weapon_scene.instantiate()
    add_child(weapon_scene)
    _weapon_slot.weapon_instance = weapon_scene
    
    if _weapon_slot.weapon.weapon_spray:
        spray_profiles[_weapon_slot.weapon.weapon_name] = _weapon_slot.weapon.weapon_spray.instantiate()
    
    connect_weapon_to_hud.emit(_weapon_slot.weapon)
    weapon_scene.visible = false # Сначала скрываем

func enter() -> void:
    if current_weapon_slot.weapon_instance:
        # Показываем текущее оружие и скрываем остальные
        for weapon in weapon_stack:
            if weapon.weapon_instance:
                weapon.weapon_instance.visible = (weapon == current_weapon_slot)
        
        current_weapon_slot.weapon_instance.visible = true
        animation_player.queue(current_weapon_slot.weapon.pick_up_animation)
        weapon_changed.emit(current_weapon_slot.weapon.weapon_name)
        update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
        
        # Обновляем прицел
        update_crosshair(current_weapon_slot.weapon.crosshair_type)

func exit(_next_weapon: WeaponSlot) -> void:
    if _next_weapon != current_weapon_slot:
        if animation_player.get_current_animation() != current_weapon_slot.weapon.change_animation:
            animation_player.queue(current_weapon_slot.weapon.change_animation)
            next_weapon = _next_weapon

func update_crosshair(type: String) -> void:
    match type:
        "dot":
            current_crosshair.set_texture(crosshair_texture, Color.WHITE, 10)
        "circle":
            current_crosshair.set_texture(crosshair_texture, Color.WHITE, 20)
        "rifle":
            current_crosshair.set_complex_crosshair()
        _:
            current_crosshair.set_texture(crosshair_texture, Color.WHITE, 10)

# Покупка оружия в магазине
func buy_weapon(weapon_name: String, player_money: int) -> bool:
    if weapon_shop.has(weapon_name):
        var weapon_data = weapon_shop[weapon_name]
        if player_money >= weapon_data["cost"]:
            # Создаем новый слот оружия
            var new_slot = WeaponSlot.new()
            new_slot.weapon = weapon_data["scene"].weapon_resource
            
            # Добавляем в доступное оружие
            available_weapons.append(new_slot)
            return true
    return false

# Выбор оружия из меню
func select_weapon_from_menu(weapon_slot: WeaponSlot) -> void:
    if weapon_stack.size() >= max_weapons:
        # Заменяем первое оружие
        weapon_stack[0] = weapon_slot
    else:
        weapon_stack.append(weapon_slot)
    
    initialize_weapon(weapon_slot)
    exit(weapon_slot)

# Остальные функции (shoot, reload, melee и т.д.) остаются такими же, как в оригинальном скрипте,
# но с учетом того, что оружие теперь отдельные сцены

func _on_animation_finished(anim_name):
    if anim_name == current_weapon_slot.weapon.shoot_animation:
        if current_weapon_slot.weapon.auto_fire == true:
            if Input.is_action_pressed("Shoot"):
                shoot()

    if anim_name == current_weapon_slot.weapon.change_animation:
        change_weapon(next_weapon)
    
    if anim_name == current_weapon_slot.weapon.reload_animation:
        if !current_weapon_slot.weapon.incremental_reload:
            calculate_reload()

func change_weapon(weapon_slot: WeaponSlot) -> void:
    current_weapon_slot = weapon_slot
    next_weapon = null
    enter()

func _process(delta):
    # Обновление позиции оружия относительно рук
    if current_weapon_slot and current_weapon_slot.weapon_instance:
        current_weapon_slot.weapon_instance.global_transform = hands_instance.get_node("WeaponPosition").global_transform
