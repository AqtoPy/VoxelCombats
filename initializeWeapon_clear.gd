func initialize_weapon(weapon_slot: WeaponSlot) -> void:
    # Удаляем старый экземпляр если есть
    if weapon_instances.has(weapon_slot):
        var old_instance = weapon_instances[weapon_slot]
        if is_instance_valid(old_instance):
            old_instance.queue_free()
        weapon_instances.erase(weapon_slot)
    
    # Дальше ваша стандартная инициализация...
