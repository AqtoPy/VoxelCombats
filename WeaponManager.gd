extends Node3D

# Сигналы
signal weapon_changed(weapon_name: String)
signal update_ammo(ammo: Array)
signal update_weapon_stack(weapons: Array)
signal hit_successful
signal add_signal_to_hud
signal connect_weapon_to_hud(weapon: WeaponResource)
signal weapon_purchased(weapon_name: String)
signal weapon_selected(weapon_slot: WeaponSlot)

# Экспортируемые переменные
@export var animation_player: AnimationPlayer
@export var melee_hitbox: ShapeCast3D
@export var max_weapons: int = 3
@export var hands_scene: PackedScene
@export var crosshair_texture: Texture2D
@export var default_weapons: Array[PackedScene] = []

# Ноды
@onready var bullet_point = get_node("%BulletPoint")
@onready var debug_bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")
@onready var crosshair = preload("res://UI/Crosshair.tscn")

# Переменные
var hands_instance: Node3D
var current_crosshair: Control
var next_weapon: WeaponSlot
var spray_profiles: Dictionary = {}
var _count = 0
var shot_tween

# Система оружия
@export var weapon_stack: Array[WeaponSlot] # Оружие у игрока
var current_weapon_slot: WeaponSlot = null
var available_weapons: Array[WeaponSlot] = [] # Все доступные оружия

# Магазин оружия
var weapon_shop = {
    "pistol": {
        "cost": 100, 
        "scene": preload("res://Weapons/Pistol.tscn"),
        "resource": preload("res://Weapons/Resources/PistolResource.tres")
    },
    "rifle": {
        "cost": 300, 
        "scene": preload("res://Weapons/Rifle.tscn"),
        "resource": preload("res://Weapons/Resources/RifleResource.tres")
    },
    "shotgun": {
        "cost": 500, 
        "scene": preload("res://Weapons/Shotgun.tscn"),
        "resource": preload("res://Weapons/Resources/ShotgunResource.tres")
    }
}

func _ready() -> void:
    # Инициализация рук
    initialize_hands()
    
    # Инициализация прицела
    initialize_crosshair()
    
    # Загрузка стартового оружия
    load_default_weapons()
    
    # Инициализация текущего оружия
    if !weapon_stack.is_empty():
        initialize_current_weapon()

func initialize_hands() -> void:
    hands_instance = hands_scene.instantiate()
    add_child(hands_instance)
    animation_player = hands_instance.get_node("AnimationPlayer")

func initialize_crosshair() -> void:
    current_crosshair = crosshair.instantiate()
    get_tree().root.get_node("HUD").add_child(current_crosshair)

func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        var weapon = weapon_scene.instantiate()
        var slot = WeaponSlot.new()
        slot.weapon = weapon.weapon_resource
        slot.current_ammo = slot.weapon.magazine
        slot.reserve_ammo = slot.weapon.max_ammo
        weapon_stack.append(slot)
        weapon.queue_free()

func initialize_current_weapon() -> void:
    animation_player.animation_finished.connect(_on_animation_finished)
    
    for weapon_slot in weapon_stack:
        initialize_weapon(weapon_slot)
    
    current_weapon_slot = weapon_stack[0]
    if check_valid_weapon_slot():
        enter()
        update_weapon_stack.emit(weapon_stack)

func initialize_weapon(_weapon_slot: WeaponSlot) -> void:
    if !_weapon_slot or !_weapon_slot.weapon:
        return
        
    # Загружаем сцену оружия
    var weapon_scene = _weapon_slot.weapon.weapon_scene.instantiate()
    add_child(weapon_scene)
    _weapon_slot.weapon_instance = weapon_scene
    
    if _weapon_slot.weapon.weapon_spray:
        spray_profiles[_weapon_slot.weapon.weapon_name] = _weapon_slot.weapon.weapon_spray.instantiate()
    
    connect_weapon_to_hud.emit(_weapon_slot.weapon)
    weapon_scene.visible = false

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

# Система магазина
func buy_weapon(weapon_name: String, player_money: int) -> bool:
    if weapon_shop.has(weapon_name):
        var weapon_data = weapon_shop[weapon_name]
        if player_money >= weapon_data["cost"]:
            var new_slot = create_weapon_slot(weapon_name)
            available_weapons.append(new_slot)
            weapon_purchased.emit(weapon_name)
            return true
    return false

func create_weapon_slot(weapon_name: String) -> WeaponSlot:
    var slot = WeaponSlot.new()
    slot.weapon = weapon_shop[weapon_name]["resource"]
    slot.current_ammo = slot.weapon.magazine
    slot.reserve_ammo = slot.weapon.max_ammo
    return slot

func select_weapon_from_menu(weapon_slot: WeaponSlot) -> void:
    if weapon_stack.size() >= max_weapons:
        weapon_stack[0] = weapon_slot
    else:
        weapon_stack.append(weapon_slot)
    
    initialize_weapon(weapon_slot)
    exit(weapon_slot)
    weapon_selected.emit(weapon_slot)

# Основные функции оружия
func check_valid_weapon_slot() -> bool:
    if current_weapon_slot and current_weapon_slot.weapon:
        return true
    push_warning("Invalid weapon slot or missing weapon resource")
    return false

func shoot() -> void:
    if !check_valid_weapon_slot():
        return
        
    if current_weapon_slot.current_ammo != 0 or !current_weapon_slot.weapon.has_ammo:
        if current_weapon_slot.weapon.incremental_reload and animation_player.current_animation == current_weapon_slot.weapon.reload_animation:
            animation_player.stop()
            
        if !animation_player.is_playing():
            animation_player.play(current_weapon_slot.weapon.shoot_animation)
            if current_weapon_slot.weapon.has_ammo:
                current_weapon_slot.current_ammo -= 1
                
            update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
            
            if shot_tween:
                shot_tween.kill()
            
            var spread = Vector2.ZERO
            if current_weapon_slot.weapon.weapon_spray:
                _count += 1
                spread = spray_profiles[current_weapon_slot.weapon.weapon_name].get_spray(_count, current_weapon_slot.weapon.magazine)
                
            load_projectile(spread)
    else:
        reload()

@rpc("any_peer")
func load_projectile(spread: Vector2) -> void:
    var projectile: Projectile = current_weapon_slot.weapon.projectile_to_load.instantiate()
    projectile.position = bullet_point.global_position
    projectile.rotation = owner.rotation
    bullet_point.add_child(projectile)
    add_signal_to_hud.emit(projectile)
    var bullet_point_origin = bullet_point.global_position
    projectile.set_projectile(
        current_weapon_slot.weapon.damage,
        spread,
        current_weapon_slot.weapon.fire_range,
        bullet_point_origin
    )

func reload() -> void:
    if !check_valid_weapon_slot():
        return
        
    if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
        return
    elif !animation_player.is_playing():
        if current_weapon_slot.reserve_ammo != 0:
            animation_player.queue(current_weapon_slot.weapon.reload_animation)
        else:
            animation_player.queue(current_weapon_slot.weapon.out_of_ammo_animation)

func calculate_reload() -> void:
    if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine:
        var anim_length = animation_player.get_current_animation_length()
        animation_player.advance(anim_length)
        return
        
    var mag_amount = current_weapon_slot.weapon.magazine
    if current_weapon_slot.weapon.incremental_reload:
        mag_amount = current_weapon_slot.current_ammo + 1
        
    var reload_amount = min(
        mag_amount - current_weapon_slot.current_ammo,
        mag_amount,
        current_weapon_slot.reserve_ammo
    )

    current_weapon_slot.current_ammo += reload_amount
    current_weapon_slot.reserve_ammo -= reload_amount
    
    update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    shot_count_update()

func melee() -> void:
    if !check_valid_weapon_slot():
        return
        
    var current_anim = animation_player.get_current_animation()
    if current_anim == current_weapon_slot.weapon.shoot_animation:
        return
        
    if current_anim != current_weapon_slot.weapon.melee_animation:
        animation_player.play(current_weapon_slot.weapon.melee_animation)
        if melee_hitbox.is_colliding():
            var colliders = melee_hitbox.get_collision_count()
            for c in colliders:
                var target = melee_hitbox.get_collider(c)
                if target.is_in_group("Target") and target.has_method("hit_successful"):
                    hit_successful.emit()
                    var direction = (target.global_transform.origin - owner.global_transform.origin).normalized()
                    var position = melee_hitbox.get_collision_point(c)
                    target.hit_successful(current_weapon_slot.weapon.melee_damage, direction, position)

func drop(slot: WeaponSlot) -> void:
    if !check_valid_weapon_slot() or !slot.weapon.can_be_dropped or weapon_stack.size() <= 1:
        return
        
    var weapon_index = weapon_stack.find(slot)
    if weapon_index != -1:
        weapon_stack.remove_at(weapon_index)
        update_weapon_stack.emit(weapon_stack)

        if slot.weapon.weapon_drop:
            var weapon_dropped = slot.weapon.weapon_drop.instantiate()
            weapon_dropped.weapon = slot
            weapon_dropped.global_transform = bullet_point.global_transform
            get_tree().root.add_child(weapon_dropped)
            
            animation_player.play(current_weapon_slot.weapon.drop_animation)
            weapon_index = max(weapon_index - 1, 0)
            exit(weapon_stack[weapon_index])

# Обработчики событий
func _on_animation_finished(anim_name: String) -> void:
    if !current_weapon_slot:
        return
        
    if anim_name == current_weapon_slot.weapon.shoot_animation:
        if current_weapon_slot.weapon.auto_fire and Input.is_action_pressed("Shoot"):
            shoot()

    if anim_name == current_weapon_slot.weapon.change_animation:
        change_weapon(next_weapon)
    
    if anim_name == current_weapon_slot.weapon.reload_animation and !current_weapon_slot.weapon.incremental_reload:
        calculate_reload()

func change_weapon(weapon_slot: WeaponSlot) -> void:
    current_weapon_slot = weapon_slot
    next_weapon = null
    enter()

func _process(delta: float) -> void:
    if current_weapon_slot and current_weapon_slot.weapon_instance:
        current_weapon_slot.weapon_instance.global_transform = hands_instance.get_node("WeaponPosition").global_transform

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("WeaponUp"):
        if check_valid_weapon_slot():
            var weapon_index = weapon_stack.find(current_weapon_slot)
            weapon_index = min(weapon_index + 1, weapon_stack.size() - 1)
            exit(weapon_stack[weapon_index])

    if event.is_action_pressed("WeaponDown"):
        if check_valid_weapon_slot():
            var weapon_index = weapon_stack.find(current_weapon_slot)
            weapon_index = max(weapon_index - 1, 0)
            exit(weapon_stack[weapon_index])
        
    if event.is_action_pressed("Shoot"):
        if check_valid_weapon_slot():
            shoot()
    
    if event.is_action_released("Shoot"):
        if check_valid_weapon_slot():
            shot_count_update()
    
    if event.is_action_pressed("Reload"):
        if check_valid_weapon_slot():
            reload()
        
    if event.is_action_pressed("Drop_Weapon"):
        if check_valid_weapon_slot():
            drop(current_weapon_slot)
        
    if event.is_action_pressed("Melee"):
        if check_valid_weapon_slot():
            melee()

func shot_count_update() -> void:
    shot_tween = get_tree().create_tween()
    shot_tween.tween_property(self, "_count", 0, 1)
