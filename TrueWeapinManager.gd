extends Node3D

# Сигналы (остаются без изменений)
signal weapon_changed(weapon_name: String)
signal update_ammo(ammo: Array)
signal update_weapon_stack(weapons: Array)
signal hit_successful
signal add_signal_to_hud
signal connect_weapon_to_hud(weapon: WeaponResource)
signal weapon_purchased(weapon_name: String)
signal weapon_selected(weapon_slot: WeaponSlot)

# Экспортируемые переменные (добавлены проверки)
@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int = 3
@export var hands_scene: PackedScene
@export var crosshair_texture: PackedScene
@export var default_weapons: Array[PackedScene] = []

# Ноды (добавлена безопасная загрузка)
@onready var bullet_point: Node3D = %BulletPoint if has_node("%BulletPoint") else null
@onready var debug_bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")
@onready var crosshair = preload("res://Player_Controller/HUD ASSETS/crosshair001.png")

# Переменные (добавлены инициализации)
var hands_instance: Node3D = null
var current_crosshair: Control = null
var next_weapon: WeaponSlot = null
var spray_profiles: Dictionary = {}
var _count: int = 0
var shot_tween: Tween = null

# Система оружия (добавлены проверки null)
@export var weapon_stack: Array[WeaponSlot] = []
var current_weapon_slot: WeaponSlot = null
var available_weapons: Array[WeaponSlot] = []

# Магазин оружия (добавлены проверки ресурсов)
var weapon_shop = {
    "pistol": {
        "cost": 100,
        "scene": preload("res://weapons/glock.tscn") if ResourceLoader.exists("res://weapons/glock.tscn") else null,
        "resource": preload("res://weapons/Resources/Glock.tres") if ResourceLoader.exists("res://weapons/Resources/Glock.tres") else null
    },
    "rifle": {
        "cost": 300,
        "scene": preload("res://weapons/ak-47.tscn") if ResourceLoader.exists("res://weapons/ak-47.tscn") else null,
        "resource": preload("res://weapons/Resources/AK-47.tres") if ResourceLoader.exists("res://weapons/Resources/AK-47.tres") else null
    },
    "shotgun": {
        "cost": 500,
        "scene": preload("res://weapons/spas_12.tscn") if ResourceLoader.exists("res://weapons/spas_12.tscn") else null,
        "resource": preload("res://weapons/Resources/Spas-12.tres") if ResourceLoader.exists("res://weapons/Resources/Spas-12.tres") else null
    }
}

func _ready() -> void:
    initialize_hands()
    load_default_weapons()
    
    if !weapon_stack.is_empty():
        initialize_current_weapon()
    else:
        push_error("Weapon stack is empty after initialization!")

func initialize_hands() -> void:
    if hands_scene:
        hands_instance = hands_scene.instantiate()
        add_child(hands_instance)
        animation_player = hands_instance.get_node("AnimationPlayer") if hands_instance.has_node("AnimationPlayer") else null
    else:
        push_error("Hands scene not assigned!")

func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        if !weapon_scene:
            push_error("Empty weapon scene in default_weapons!")
            continue
            
        var weapon = weapon_scene.instantiate()
        
        # Проверка наличия необходимого метода
        if weapon.has_method("get_weapon_resource"):
            var weapon_res = weapon.get_weapon_resource()
            if weapon_res:
                var slot = WeaponSlot.new()
                slot.weapon = weapon_res
                # Исправление инициализации боеприпасов
                slot.current_ammo = slot.weapon.magazine if slot.weapon else 0
                slot.reserve_ammo = (slot.weapon.max_ammo - slot.weapon.magazine) if slot.weapon else 0
                weapon_stack.append(slot)
            else:
                push_error("Weapon resource is null in: ", weapon_scene.resource_path)
        else:
            push_error("Weapon scene missing get_weapon_resource() method: ", weapon_scene.resource_path)
        
        weapon.queue_free()

func initialize_current_weapon() -> void:
    if animation_player:
        animation_player.animation_finished.connect(_on_animation_finished)
    
    for weapon_slot in weapon_stack:
        initialize_weapon(weapon_slot)
    
    if !weapon_stack.is_empty():
        current_weapon_slot = weapon_stack[0]
        if check_valid_weapon_slot():
            enter()
            update_weapon_stack.emit(weapon_stack)
        else:
            push_error("First weapon slot is invalid!")
    else:
        push_error("Weapon stack is empty during initialization!")

func initialize_weapon(weapon_slot: WeaponSlot) -> void:
    if !weapon_slot or !weapon_slot.weapon:
        push_error("Invalid weapon slot or missing weapon resource!")
        return
    
    if !weapon_slot.weapon.weapon_scene:
        push_error("Missing weapon scene in resource: ", weapon_slot.weapon.resource_path)
        return
    
    var weapon_scene = weapon_slot.weapon.weapon_scene.instantiate()
    weapon_slot.weapon_instance = weapon_scene
    add_child(weapon_scene)
    
    # Инициализация анимаций
    if weapon_scene.has_node("AnimationPlayer"):
        var anim_player = weapon_scene.get_node("AnimationPlayer")
        if anim_player.has_animation(weapon_slot.weapon.pick_up_animation):
            anim_player.play(weapon_slot.weapon.pick_up_animation)
        else:
            push_error("Missing animation: ", weapon_slot.weapon.pick_up_animation)

func enter() -> void:
    if !check_valid_weapon_slot():
        return
    
    if current_weapon_slot.weapon_instance:
        # Скрываем все оружия кроме текущего
        for weapon in weapon_stack:
            if weapon.weapon_instance:
                weapon.weapon_instance.visible = (weapon == current_weapon_slot)
        
        current_weapon_slot.weapon_instance.visible = true
        
        # Воспроизведение анимаций
        if animation_player and current_weapon_slot.weapon.pick_up_animation:
            animation_player.queue(current_weapon_slot.weapon.pick_up_animation)
        
        # Обновление интерфейса
        weapon_changed.emit(current_weapon_slot.weapon.weapon_name)
        update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
        update_crosshair(current_weapon_slot.weapon.crosshair_type)
        
        # Анимация рук
        if hands_instance and current_weapon_slot.weapon.hands_draw_animation:
            hands_instance.play_animation(
                current_weapon_slot.weapon.hands_draw_animation,
                current_weapon_slot.weapon.hands_animation_speed
            )

func check_valid_weapon_slot() -> bool:
    if current_weapon_slot and current_weapon_slot.weapon:
        return true
    push_warning("Invalid weapon slot or missing weapon resource")
    return false

func shoot() -> void:
    if !check_valid_weapon_slot():
        return
    
    # Проверка возможности стрельбы
    if current_weapon_slot.current_ammo <= 0 and current_weapon_slot.weapon.has_ammo:
        reload()
        return
    
    # Проверка анимаций
    if animation_player.is_playing() and current_weapon_slot.weapon.incremental_reload:
        animation_player.stop()
    
    if animation_player and current_weapon_slot.weapon.shoot_animation:
        animation_player.play(current_weapon_slot.weapon.shoot_animation)
    
    # Обновление боеприпасов
    if current_weapon_slot.weapon.has_ammo:
        current_weapon_slot.current_ammo -= 1
        update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    
    # Создание снаряда
    if current_weapon_slot.weapon.projectile_to_load and bullet_point:
        var spread = Vector2.ZERO
        if current_weapon_slot.weapon.weapon_spray:
            _count += 1
            spread = spray_profiles[current_weapon_slot.weapon.weapon_name].get_spray(
                _count, 
                current_weapon_slot.weapon.magazine
            )
        load_projectile(spread)

@rpc("any_peer")
func load_projectile(spread: Vector2) -> void:
    var projectile: Projectile = current_weapon_slot.weapon.projectile_to_load.instantiate()
    projectile.position = bullet_point.global_position
    projectile.rotation = owner.rotation
    bullet_point.add_child(projectile)
    add_signal_to_hud.emit(projectile)
    
    projectile.set_projectile(
        current_weapon_slot.weapon.damage,
        spread,
        current_weapon_slot.weapon.fire_range,
        bullet_point.global_position
    )

func reload() -> void:
    if !check_valid_weapon_slot():
        return
    
    if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
        return
    
    if animation_player:
        if current_weapon_slot.reserve_ammo > 0:
            animation_player.queue(current_weapon_slot.weapon.reload_animation)
        else:
            animation_player.queue(current_weapon_slot.weapon.out_of_ammo_animation)

# Остальные функции остаются аналогичными с добавлением проверок null
# ...
