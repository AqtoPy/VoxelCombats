func initialize_weapon(weapon_slot: WeaponSlot) -> void:
    if weapon_instances.has(weapon_slot):
        return  # Уже инициализировано
    
    if !weapon_slot.weapon or !weapon_slot.weapon.weapon_scene:
        push_error("Invalid weapon resource or scene for slot: ", weapon_slot)
        return
    
    var weapon_instance = weapon_slot.weapon.weapon_scene.instantiate()
    add_child(weapon_instance)
    
    # Привязываем оружие к рукам
    if hands_instance:
        weapon_instance.global_transform = hands_instance.get_node("WeaponPosition").global_transform
    
    # Настраиваем видимость
    weapon_instance.visible = false
    weapon_instances[weapon_slot] = weapon_instance
    
    # Передаём ресурс оружия в его экземпляр
    if weapon_instance.has_method("set_weapon_resource"):
        weapon_instance.set_weapon_resource(weapon_slot.weapon)
