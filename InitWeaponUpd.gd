# WeaponManager.gd
func initialize_weapon(weapon_slot: WeaponSlot):
    # ...
    if anim_player:
        var anim_name = weapon_slot.weapon.pick_up_animation
        if anim_player.has_animation(anim_name):
            anim_player.play(anim_name)
        else:
            push_error("Animation '%s' not found in %s" % [anim_name, weapon_slot.weapon.resource_path])
