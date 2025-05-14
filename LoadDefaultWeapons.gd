func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        var weapon = weapon_scene.instantiate()
        # Проверяем, что у оружия есть нужное свойство
        if weapon.has_method("get_weapon_resource"):
            var slot = WeaponSlot.new()
            slot.weapon = weapon.get_weapon_resource()  # Используем метод для получения ресурса
            slot.current_ammo = slot.weapon.magazine
            slot.reserve_ammo = slot.weapon.max_ammo
            weapon_stack.append(slot)
        else:
            push_error("Weapon scene %s doesn't have required weapon resource" % weapon_scene.resource_path)
        weapon.queue_free()
