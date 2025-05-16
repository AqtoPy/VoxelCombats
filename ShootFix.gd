func shoot() -> void:
    if !check_valid_weapon_slot() or hands_instance.is_busy:
        return

    # Проверка патронов
    if current_weapon_slot.current_ammo <= 0 && current_weapon_slot.weapon.has_ammo:
        if current_weapon_slot.reserve_ammo > 0:
            reload()
        return  # Можно добавить звук щелчка при пустом магазине

    # Запуск анимаций
    animation_player.play(current_weapon_slot.weapon.shoot_animation)
    hands_instance.play_animation(current_weapon_slot.weapon.arms_animations["shoot"], 
                                current_weapon_slot.weapon.hands_animation_speed)

    # Обновление патронов
    if current_weapon_slot.weapon.has_ammo:
        current_weapon_slot.current_ammo -= 1
        update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    
    # Логика выстрела
    load_projectile(Vector2.ZERO)
