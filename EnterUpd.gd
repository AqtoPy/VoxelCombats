# Enter
func enter(target_slot: WeaponSlot) -> void:
    # 1. Проверка валидности слота
    if !is_instance_valid(target_slot) or !target_slot.weapon:
        push_error("Invalid weapon slot passed to enter()")
        return
    
    # 2. Проверка существования экземпляра
    if !weapon_instances.has(target_slot):
        push_error("Weapon instance not found for: ", target_slot.weapon.weapon_name)
        return
    
    # 3. Скрыть всё оружие
    for slot in weapon_instances:
        weapon_instances[slot].visible = false
    
    # 4. Показать текущее оружие
    var weapon_instance = weapon_instances[target_slot]
    weapon_instance.visible = true
    
    # 5. Обновить текущий слот
    current_weapon_slot = target_slot
    
    # 6. Анимация оружия
    if animation_player:
        animation_player.stop()
        animation_player.play(target_slot.weapon.pick_up_animation)
    
    # 7. Обновление HUD
    weapon_changed.emit(target_slot.weapon.weapon_name)
    update_ammo.emit([target_slot.current_ammo, target_slot.reserve_ammo])
    update_crosshair(target_slot.weapon.crosshair_type)
    
    # 8. Анимация рук
    if hands_instance:
        hands_instance.play_animation(
            target_slot.weapon.hands_draw_animation,
            target_slot.weapon.hands_animation_speed
        )

# initialize current weapon
func initialize_current_weapon():
    if weapon_stack.is_empty():
        return
    
    # Инициализация всех экземпляров
    for slot in weapon_stack:
        initialize_weapon(slot)
    
    # Активация первого оружия
    enter(weapon_stack[0])

# switch weapon
func switch_weapon(new_slot: WeaponSlot):
    if !weapon_stack.has(new_slot):
        return
    
    # Скрытие старого оружия
    if current_weapon_slot:
        weapon_instances[current_weapon_slot].visible = false
    
    # Показать новое
    enter(new_slot)

# input
func _input(event):
    if event.is_action_pressed("weapon_next"):
        var current_idx = weapon_stack.find(current_weapon_slot)
        var next_idx = (current_idx + 1) % weapon_stack.size()
        enter(weapon_stack[next_idx])
