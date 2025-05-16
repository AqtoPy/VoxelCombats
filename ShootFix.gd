func shoot() -> void:
    # 1. Проверка возможности выстрела
    if !check_valid_weapon_slot():
        return
    
    # 2. Проверка состояния анимаций и занятости рук
    if hands_instance.is_busy || animation_player.is_playing():
        return
    
    # 3. Проверка патронов в магазине
    if current_weapon_slot.current_ammo <= 0:
        if current_weapon_slot.reserve_ammo > 0:
            reload()
        else:
            # Воспроизведение звука/анимации пустого магазина
            if animation_player.has_animation(current_weapon_slot.weapon.out_of_ammo_animation):
                animation_player.play(current_weapon_slot.weapon.out_of_ammo_animation)
        return
    
    # 4. Прерывание перезарядки, если она была
    if animation_player.current_animation == current_weapon_slot.weapon.reload_animation:
        animation_player.stop()
    
    # 5. Воспроизведение анимации выстрела
    var shoot_anim = current_weapon_slot.weapon.shoot_animation
    if animation_player.has_animation(shoot_anim):
        animation_player.play(shoot_anim)
    
    # 6. Анимация рук
    if current_weapon_slot.weapon.arms_animations.has("shoot"):
        var hands_anim = current_weapon_slot.weapon.arms_animations["shoot"]
        hands_instance.play_animation(hands_anim, current_weapon_slot.weapon.hands_animation_speed)
    
    # 7. Обновление боеприпасов
    current_weapon_slot.current_ammo -= 1
    update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    
    # 8. Создание снаряда/выстрела
    var spread = calculate_spread()
    load_projectile(spread)
    
    # 9. Обработка автоматического огня
    if current_weapon_slot.weapon.is_automatic:
        # Запланировать следующий выстрел согласно скорострельности
        var fire_delay = 1.0 / current_weapon_slot.weapon.fire_rate
        await get_tree().create_timer(fire_delay).timeout
        if Input.is_action_pressed("Shoot"):
            shoot()

func calculate_spread() -> Vector2:
    var spread = Vector2.ZERO
    if current_weapon_slot.weapon.weapon_spray:
        _count += 1
        var weapon_name = current_weapon_slot.weapon.weapon_name
        if spray_profiles.has(weapon_name):
            var spray_profile = spray_profiles[weapon_name]
            if spray_profile.has_method("get_spray"):
                spread = spray_profile.get_spray(
                    _count, 
                    current_weapon_slot.weapon.magazine_size
                )
    
    # Сброс счетчика разброса через tween
    if shot_tween:
        shot_tween.kill()
    shot_tween = create_tween()
    shot_tween.tween_property(self, "_count", 0.0, 0.5)
    
    return spread
