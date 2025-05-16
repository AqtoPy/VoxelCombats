func shoot() -> void:
    # 1. Проверка возможности выстрела
    if !check_valid_weapon_slot():
        return
    
    # 2. Проверка состояния анимаций
    if hands_instance.is_busy:
        return
    
    # 3. Проверка патронов
    if current_weapon_slot.current_ammo <= 0:
        if current_weapon_slot.reserve_ammo > 0:
            reload()
        else:
            # Воспроизведение звука/анимации пустого магазина
            if animation_player.has_animation(current_weapon_slot.weapon.out_of_ammo_animation):
                animation_player.play(current_weapon_slot.weapon.out_of_ammo_animation)
        return
    
    # 4. Получаем экземпляр оружия и его AnimationPlayer
    var weapon_instance = weapon_instances[current_weapon_slot]
    var weapon_anim_player: AnimationPlayer = weapon_instance.get_node("AnimationPlayer") if weapon_instance.has_node("AnimationPlayer") else null
    
    # 5. Проверяем возможность воспроизведения анимации
    if weapon_anim_player and weapon_anim_player.is_playing():
        return
    
    # 6. Воспроизведение анимации выстрела на оружии
    if weapon_anim_player and weapon_anim_player.has_animation("fire"):
        weapon_anim_player.play("fire")
    else:
        push_error("Missing fire animation in weapon: ", current_weapon_slot.weapon.weapon_name)
    
    # 7. Анимация рук
    if hands_instance.has_method("play_animation"):
        hands_instance.play_animation(
            current_weapon_slot.weapon.hands_fire_animation,
            current_weapon_slot.weapon.hands_animation_speed
        )
    
    # 8. Логика выстрела
    current_weapon_slot.current_ammo -= 1
    update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    
    # 9. Создание снаряда
    var spread = Vector2.ZERO
    if current_weapon_slot.weapon.weapon_spray:
        _count += 1
        if spray_profiles.has(current_weapon_slot.weapon.weapon_name):
            var spray_profile = spray_profiles[current_weapon_slot.weapon.weapon_name]
            if spray_profile.has_method("get_spray"):
                spread = spray_profile.get_spray(_count, current_weapon_slot.weapon.magazine_size)
    
    load_projectile(spread)
    
    # 10. Обработка автоматического огня
    if current_weapon_slot.weapon.is_automatic and Input.is_action_pressed("shoot"):
        var fire_delay = 1.0 / current_weapon_slot.weapon.fire_rate
        await get_tree().create_timer(fire_delay).timeout
        if current_weapon_slot.current_ammo > 0:
            shoot()
