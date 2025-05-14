func initialize_weapon(weapon_slot: WeaponSlot) -> void:
    # 1. Проверка валидности слота и ресурса
    if !is_instance_valid(weapon_slot) or !weapon_slot.weapon:
        push_error("Invalid WeaponSlot or missing WeaponResource")
        return
    
    # 2. Проверка существующего экземпляра
    if weapon_instances.has(weapon_slot):
        push_warning("Weapon already initialized for slot: ", weapon_slot.weapon.weapon_name)
        return
    
    # 3. Проверка сцены оружия
    if !weapon_slot.weapon.weapon_scene:
        push_error("Missing weapon scene in resource: ", weapon_slot.weapon.resource_path)
        return
    
    # 4. Создание экземпляра
    var weapon_scene = weapon_slot.weapon.weapon_scene.instantiate()
    
    # 5. Передача ресурса в экземпляр
    if weapon_scene.has_method("set_weapon_resource"):
        weapon_scene.set_weapon_resource(weapon_slot.weapon)
    else:
        push_error("Weapon scene missing set_weapon_resource() method")
        weapon_scene.queue_free()
        return
    
    # 6. Добавление и настройка экземпляра
    add_child(weapon_scene)
    weapon_instances[weapon_slot] = weapon_scene
    weapon_scene.visible = false
    
    # 7. Инициализация анимаций
    var anim_player = weapon_scene.get_node_or_null("AnimationPlayer")
    if anim_player:
        if anim_player.has_animation(weapon_slot.weapon.pick_up_animation):
            anim_player.play(weapon_slot.weapon.pick_up_animation)
        else:
            push_error("Missing animation: ", weapon_slot.weapon.pick_up_animation)
    else:
        push_warning("No AnimationPlayer found in weapon scene")

func initialize_current_weapon() -> void:
    # 1. Инициализация всех слотов
    for slot in weapon_stack:
        initialize_weapon(slot)
    
    # 2. Проверка стека
    if weapon_stack.is_empty():
        push_error("Weapon stack is empty!")
        return
    
    # 3. Активация первого оружия
    var first_slot = weapon_stack[0]
    if weapon_instances.has(first_slot):
        enter(first_slot)
    else:
        push_error("Failed to initialize first weapon")

func _ready() -> void:
    initialize_hands()
    load_default_weapons()
    initialize_current_weapon()
