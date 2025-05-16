func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        if weapon_scene == null:
            push_error("Пустая сцена оружия в default_weapons!")
            continue
            
        # 1. Создаем временный экземпляр оружия
        var weapon_instance = weapon_scene.instantiate()
        
        # 2. Получаем ресурс оружия безопасным способом
        var weapon_res: WeaponResource = null
        if weapon_instance.has_method("get_weapon_resource"):
            weapon_res = weapon_instance.get_weapon_resource()
        
        # 3. Если не получили ресурс, создаем временный
        if weapon_res == null:
            push_warning("Не удалось получить ресурс оружия, создаем временный")
            weapon_res = WeaponResource.new()
            weapon_res.weapon_name = "Temp Weapon"
            weapon_res.magazine_size = 30
            weapon_res.max_ammo = 90
        
        # 4. Создаем новый слот для оружия
        var slot = WeaponSlot.new()
        slot.weapon = weapon_res
        
        # 5. Инициализируем боеприпасы
        slot.current_ammo = weapon_res.magazine_size
        slot.reserve_ammo = weapon_res.max_ammo - weapon_res.magazine_size
        
        # 6. Добавляем в стек оружия
        weapon_stack.append(slot)
        
        # 7. Очищаем временный экземпляр
        weapon_instance.queue_free()
    
    # Проверяем результат
    if weapon_stack.is_empty():
        push_error("Не удалось загрузить ни одного оружия!")
    else:
        print("Успешно загружено оружий: ", weapon_stack.size())
