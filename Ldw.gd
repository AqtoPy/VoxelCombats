func load_default_weapons() -> void:
    weapon_stack.clear()  # Очищаем старый стек
    
    for weapon_scene in default_weapons:
        if !weapon_scene:
            push_error("Empty weapon scene in default_weapons!")
            continue
            
        # Загружаем ресурс НЕ создавая экземпляр
        var weapon_res: WeaponResource = null
        if weapon_scene.can_instantiate():
            var temp_instance = weapon_scene.instantiate()
            if temp_instance.has_method("get_weapon_resource"):
                weapon_res = temp_instance.get_weapon_resource()
            temp_instance.queue_free()
        
        if !weapon_res:
            push_error("Failed to load weapon resource from: ", weapon_scene.resource_path)
            continue
            
        # Создаем слот с копией ресурса
        var slot = WeaponSlot.new()
        slot.weapon = weapon_res.duplicate(true)  # Важно: создаем копию!
        slot.current_ammo = slot.weapon.magazine_size
        slot.reserve_ammo = slot.weapon.max_ammo - slot.weapon.magazine_size
        weapon_stack.append(slot)
