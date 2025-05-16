func enter(target_slot: WeaponSlot) -> void:
    if !is_instance_valid(target_slot) or !weapon_instances.has(target_slot):
        return
    
    # Скрыть текущее оружие
    if current_weapon_slot and weapon_instances.has(current_weapon_slot):
        weapon_instances[current_weapon_slot].visible = false
    
    # Показать новое оружие
    var weapon_instance = weapon_instances[target_slot]
    weapon_instance.visible = true
    current_weapon_slot = target_slot
    
    # Проиграть анимацию ВЗЯТИЯ на самом оружии
    if weapon_instance.has_method("play_animation"):
        weapon_instance.play_animation("draw")
    elif weapon_instance.has_node("AnimationPlayer"):
        var weapon_anim_player = weapon_instance.get_node("AnimationPlayer")
        if weapon_anim_player.has_animation("draw"):
            weapon_anim_player.play("draw")
    
    # Проиграть анимацию рук
    hands_instance.play_animation(target_slot.weapon.hands_draw_animation, 
                               target_slot.weapon.hands_animation_speed)
    
    # Обновить HUD
    weapon_changed.emit(target_slot.weapon.weapon_name)
    update_ammo.emit([target_slot.current_ammo, target_slot.reserve_ammo])
