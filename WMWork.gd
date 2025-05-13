func initialize_weapon(weapon_slot: WeaponSlot):
    if !weapon_slot or !weapon_slot.weapon:
        return
    
    # Загружаем сцену оружия (например Rifle.tscn)
    var weapon_scene = weapon_slot.weapon.weapon_scene.instantiate()
    weapon_slot.weapon_instance = weapon_scene
    add_child(weapon_scene)
    
    # Применяем параметры из ресурса
    weapon_scene.get_node("AnimationPlayer").play(weapon_slot.weapon.pick_up_animation)
