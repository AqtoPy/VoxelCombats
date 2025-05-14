func _ready():
    # Ждём завершения текущего кадра
    await get_tree().process_frame
    load_default_weapons()
    if !weapon_stack.is_empty():
        initialize_current_weapon()
    else:
        push_error("Weapon stack is empty!")

func load_default_weapons():
    for weapon_scene in default_weapons:
        if !weapon_scene:
            push_error("Empty weapon scene in default_weapons!")
            continue
            
        var weapon = weapon_scene.instantiate()
        
        # Если сцена не имеет ресурса, создаём временный
        if !weapon.has_method("get_weapon_resource"):
            push_error("Weapon scene missing get_weapon_resource()")
            weapon.queue_free()
            continue
            
        var weapon_res = weapon.get_weapon_resource()
        if !weapon_res:
            # Создаём временный ресурс если основной не загружен
            weapon_res = preload("res://weapons/Resources/Spas-12.tres")
            if weapon.has_method("set_weapon_resource"):
                weapon.set_weapon_resource(weapon_res)
        
        var slot = WeaponSlot.new()
        slot.weapon = weapon_res
        slot.current_ammo = weapon_res.magazine if weapon_res else 30
        weapon_stack.append(slot)
        weapon.queue_free()

func initialize_weapon(weapon_slot: WeaponSlot):
    if !weapon_slot or !weapon_slot.weapon:
        push_error("Invalid weapon slot in initialize_weapon!")
        return
    
    if !weapon_slot.weapon.weapon_scene:
        push_error("Missing weapon scene in resource!")
        return
    
    var weapon_scene = weapon_slot.weapon.weapon_scene.instantiate()
    
    # Критически важный момент!
    if weapon_scene.has_method("set_weapon_resource"):
        weapon_scene.set_weapon_resource(weapon_slot.weapon)
    else:
        push_error("Weapon scene missing set_weapon_resource()!")
    
    weapon_instances[weapon_slot] = weapon_scene
    add_child(weapon_scene)
    weapon_scene.visible = false
