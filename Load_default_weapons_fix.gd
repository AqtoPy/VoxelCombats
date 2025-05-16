func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        if !weapon_scene:
            continue
            
        # Создаём КОПИЮ ресурса для каждого оружия
        var weapon = weapon_scene.instantiate()
        var weapon_res = weapon.get_weapon_resource().duplicate(true) if weapon.has_method("get_weapon_resource") else null
        
        if !weapon_res:
            push_error("Failed to get weapon resource for: ", weapon_scene.resource_path)
            weapon.queue_free()
            continue
            
        var slot = WeaponSlot.new()
        slot.weapon = weapon_res
        slot.current_ammo = weapon_res.magazine_size
        slot.reserve_ammo = weapon_res.max_ammo - weapon_res.magazine_size
        
        weapon_stack.append(slot)
        weapon.queue_free()  # Удаляем временный экземпляр
