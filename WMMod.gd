func _on_weapon_purchased(weapon_name: String):
    print("Weapon purchased: ", weapon_name)
    # Можно добавить логику обработки купленного оружия

func _on_weapon_selected(weapon_slot: WeaponSlot):
    if weapon_stack.size() >= max_weapons:
        weapon_stack[0] = weapon_slot
    else:
        weapon_stack.append(weapon_slot)
    
    initialize_weapon(weapon_slot)
    exit(weapon_slot)
