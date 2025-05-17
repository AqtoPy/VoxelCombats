func _ready() -> void:
    # 1. Инициализация рук
    initialize_hands()
    
    # 2. Ждем завершения текущего кадра
    await get_tree().process_frame
    
    # 3. Очистка старых данных (на случай реинициализации)
    weapon_stack.clear()
    for child in get_children():
        if child is WeaponBase:
            child.queue_free()
    weapon_instances.clear()
    
    # 4. Загрузка стартового оружия
    load_default_weapons()
    
    # 5. Проверка наличия оружия
    if weapon_stack.is_empty():
        push_error("No weapons loaded in weapon stack!")
        return
    
    # 6. Распределение оружия по категориям
    setup_weapon_categories()
    
    # 7. Инициализация экземпляров оружия
    for slot in weapon_stack:
        initialize_weapon(slot)
    
    # 8. Автоматический выбор стартового оружия
    var start_weapon = (
        weapon_categories[WeaponCategory.PRIMARY] or 
        weapon_categories[WeaponCategory.SECONDARY] or 
        weapon_stack[0]
    )
    
    if start_weapon:
        enter(start_weapon, determine_weapon_category(start_weapon))
    else:
        push_error("Failed to find any valid starting weapon")

func determine_weapon_category(slot: WeaponSlot) -> WeaponCategory:
    if slot.weapon.slot_type == "primary":
        return WeaponCategory.PRIMARY
    elif slot.weapon.slot_type == "secondary":
        return WeaponCategory.SECONDARY
    elif slot.weapon.slot_type == "melee":
        return WeaponCategory.MELEE
    elif slot.weapon.slot_type == "explosive":
        return WeaponCategory.EXPLOSIVE
    else:
        return WeaponCategory.PRIMARY  # fallback
