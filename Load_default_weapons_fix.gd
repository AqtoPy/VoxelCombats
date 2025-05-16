func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        if !weapon_scene:
            push_error("Empty weapon scene in default_weapons!")
            continue
            
        # Создаем временный экземпляр оружия
        var weapon_instance = weapon_scene.instantiate()
        
        # Получаем ресурс оружия безопасным способом
        var weapon_res: WeaponResource = null
        if weapon_instance.has_method("get_weapon_resource"):
            weapon_res = weapon_instance.get_weapon_resource()
        
        if !weapon_res:
            push_error("Failed to get weapon resource from: ", weapon_scene.resource_path)
            weapon_instance.queue_free()
            continue
        
        # Создаем новый слот для оружия
        var slot = WeaponSlot.new()
        slot.weapon = weapon_res.duplicate(true)  # Создаем уникальную копию ресурса
        
        # Инициализируем боеприпасы
        slot.current_ammo = slot.weapon.magazine_size
        slot.reserve_ammo = slot.weapon.max_ammo - slot.weapon.magazine_size
        
        weapon_stack.append(slot)
        weapon_instance.queue_free()
