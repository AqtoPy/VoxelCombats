# WeaponManager.gd
func equip_to_slot(slot: int, weapon_scene: PackedScene):
    if slot >= weapon_stack.size():
        weapon_stack.resize(slot + 1)
    
    var new_weapon = weapon_scene.instantiate()
    var weapon_slot = WeaponSlot.new()
    weapon_slot.weapon = new_weapon.weapon_resource
    weapon_stack[slot] = weapon_slot
    update_weapon_stack.emit(weapon_stack)
