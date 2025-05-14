func initialize_weapon(weapon_slot: WeaponSlot):
    if !weapon_slot or !weapon_slot.weapon:
        return

    var weapon_scene = weapon_slot.weapon.weapon_scene.instantiate()
    
    # Важно: передаем ресурс вручную!
    if weapon_scene.has_method("set_weapon_resource"):
        weapon_scene.set_weapon_resource(weapon_slot.weapon)
    
    weapon_slot.weapon_instance = weapon_scene
    add_child(weapon_scene)


func set_weapon_resource(res: WeaponResource) -> void:
    weapon_resource = res


func load_default_weapons() -> void:
    for weapon_scene in default_weapons:
        var weapon = weapon_scene.instantiate()
        if weapon.has_method("get_weapon_resource"):
            var weapon_res = weapon.get_weapon_resource()
            if weapon_res:  # Если ресурс загружен кодом (не через @export)
                var slot = WeaponSlot.new()
                slot.weapon = weapon_res  # Ресурс берется из WeaponBase
                slot.current_ammo = slot.weapon.magazine
                weapon_stack.append(slot)
        weapon.queue_free()
