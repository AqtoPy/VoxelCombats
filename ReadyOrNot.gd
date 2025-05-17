func _ready() -> void:
    # 1. Инициализация рук
    initialize_hands()
    
    # 2. Ждем завершения текущего кадра
    await get_tree().process_frame
    
    # 3. Очистка старых данных
    clear_weapons()
    
    # 4. Загрузка стартового оружия
    load_default_weapons()
    
    # 5. Проверка наличия оружия
    if weapon_stack.is_empty():
        push_error("No weapons loaded in weapon stack!")
        return
    
    # 6. Инициализация и распределение по слотам
    initialize_and_categorize_weapons()
    
    # 7. Автоматический выбор стартового оружия
    equip_default_weapon()

func clear_weapons():
    weapon_stack.clear()
    for child in get_children():
        if child is WeaponBase:
            child.queue_free()
    weapon_instances.clear()
    weapon_categories = {
        WeaponCategory.PRIMARY: null,
        WeaponCategory.SECONDARY: null,
        WeaponCategory.MELEE: null,
        WeaponCategory.EXPLOSIVE: null
    }

func initialize_and_categorize_weapons():
    for slot in weapon_stack:
        initialize_weapon(slot)
        categorize_weapon_slot(slot)

func categorize_weapon_slot(slot: WeaponSlot):
    match slot.weapon.slot_type:
        "primary":
            if !weapon_categories[WeaponCategory.PRIMARY]:
                weapon_categories[WeaponCategory.PRIMARY] = slot
        "secondary":
            if !weapon_categories[WeaponCategory.SECONDARY]:
                weapon_categories[WeaponCategory.SECONDARY] = slot
        "melee":
            if !weapon_categories[WeaponCategory.MELEE]:
                weapon_categories[WeaponCategory.MELEE] = slot
        "explosive":
            if !weapon_categories[WeaponCategory.EXPLOSIVE]:
                weapon_categories[WeaponCategory.EXPLOSIVE] = slot

func equip_default_weapon():
    var start_weapon = (
        weapon_categories[WeaponCategory.PRIMARY] or 
        weapon_categories[WeaponCategory.SECONDARY] or 
        weapon_stack[0]  # Fallback
    )
    
    if start_weapon:
        var category = get_category_for_slot(start_weapon)
        enter(start_weapon, category)
    else:
        push_error("Failed to find any valid starting weapon")

func get_category_for_slot(slot: WeaponSlot) -> WeaponCategory:
    for category in weapon_categories:
        if weapon_categories[category] == slot:
            return category
    return WeaponCategory.PRIMARY  # Default fallback
