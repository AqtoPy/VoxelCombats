func calculate_reload() -> void:
    # 1. Проверка валидности текущего оружия
    if !check_valid_weapon_slot():
        return
    
    # 2. Проверка необходимости перезарядки
    if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine_size:
        # Если магазин уже полный, пропускаем перезарядку
        if animation_player:
            var anim_length = animation_player.get_animation(current_weapon_slot.weapon.reload_animation).length
            animation_player.advance(anim_length)
        return
    
    # 3. Проверка наличия патронов
    if current_weapon_slot.reserve_ammo <= 0:
        play_empty_reload_animation()
        return
    
    # 4. Расчет количества патронов для перезарядки
    var reload_amount = 0
    
    if current_weapon_slot.weapon.incremental_reload:
        # Инкрементальная перезарядка (по одному патрону, например для дробовиков)
        reload_amount = 1
    else:
        # Полная перезарядка (замена всего магазина)
        var needed = current_weapon_slot.weapon.magazine_size - current_weapon_slot.current_ammo
        reload_amount = min(needed, current_weapon_slot.reserve_ammo)
    
    # 5. Обновление количества патронов
    current_weapon_slot.current_ammo += reload_amount
    current_weapon_slot.reserve_ammo -= reload_amount
    
    # 6. Синхронизация в мультиплеере
    if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
        rpc("remote_update_ammo", current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo)
    
    # 7. Обновление HUD
    update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    
    # 8. Сброс счетчика выстрелов для разброса
    shot_count_update()

@rpc("call_remote", "any_peer", "reliable")
func remote_update_ammo(current: int, reserve: int):
    if !check_valid_weapon_slot():
        return
    current_weapon_slot.current_ammo = current
    current_weapon_slot.reserve_ammo = reserve
    update_ammo.emit([current, reserve])
