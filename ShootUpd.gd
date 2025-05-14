func shoot() -> void:
    if !check_valid_weapon_slot():
        return

    # Проверка доступности стрельбы
    if current_weapon_slot.current_ammo <= 0 && current_weapon_slot.weapon.has_ammo:
        reload()
        return

    # Прерывание перезарядки
    if current_weapon_slot.weapon.incremental_reload:
        if animation_player.current_animation == current_weapon_slot.weapon.reload_animation:
            animation_player.stop()

    # Воспроизведение анимации стрельбы
    if !animation_player.is_playing():
        # Основная логика стрельбы
        animation_player.play(current_weapon_slot.weapon.shoot_animation)
        
        if current_weapon_slot.weapon.has_ammo:
            current_weapon_slot.current_ammo = max(current_weapon_slot.current_ammo - 1, 0)
            update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])

        # Управление разбросом
        var spread = Vector2.ZERO
        if current_weapon_slot.weapon.weapon_spray:
            _count += 1
        
            # Безопасный доступ к профилю разброса
            var weapon_name = current_weapon_slot.weapon.weapon_name
            if spray_profiles.has(weapon_name):
                var spray_profile = spray_profiles[weapon_name]
                if spray_profile.has_method("get_spray"):
                    spread = spray_profile.get_spray(
                        _count, 
                        current_weapon_slot.weapon.magazine
                    )
                else:
                    push_error("Spray profile for %s missing get_spray method" % weapon_name)
            else:
                push_warning("No spray profile found for weapon: ", weapon_name)

        # Создание снаряда
        load_projectile(spread)

        # Сброс счетчика разброса
        if shot_tween:
            shot_tween.kill()
        
        shot_tween = create_tween()
        shot_tween.tween_property(self, "_count", 0.0, 0.5)
