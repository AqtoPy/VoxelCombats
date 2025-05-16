var is_reloading: bool = false
var reload_interrupted: bool = false

func reload() -> void:
    # Проверка условий для перезарядки
    if !check_valid_weapon_slot() or is_reloading:
        return
    
    # Проверка необходимости перезарядки
    if current_weapon_slot.current_ammo == current_weapon_slot.weapon.magazine_size:
        return
    
    # Проверка наличия патронов
    if current_weapon_slot.reserve_ammo <= 0:
        play_empty_reload_animation()
        return
    
    # Начинаем перезарядку
    start_reload_sequence()

func start_reload_sequence() -> void:
    is_reloading = true
    reload_interrupted = false
    
    # Проигрываем анимацию рук
    if hands_instance.has_method("play_animation"):
        hands_instance.play_animation(
            current_weapon_slot.weapon.hands_reload_animation,
            current_weapon_slot.weapon.hands_animation_speed
        )
    
    # Проигрываем анимацию оружия
    var weapon_instance = weapon_instances[current_weapon_slot]
    if weapon_instance.has_node("AnimationPlayer"):
        var weapon_anim = weapon_instance.get_node("AnimationPlayer")
        if weapon_anim.has_animation("reload"):
            weapon_anim.play("reload")
    
    # Для инкрементальной перезарядки
    if current_weapon_slot.weapon.incremental_reload:
        await get_tree().create_timer(current_weapon_slot.weapon.reload_time).timeout
        if !reload_interrupted:
            finish_incremental_reload()
    else:
        # Ждем завершения анимации для полной перезарядки
        if weapon_instance.has_node("AnimationPlayer"):
            await weapon_instance.get_node("AnimationPlayer").animation_finished
        if !reload_interrupted:
            finish_full_reload()

func finish_incremental_reload() -> void:
    # Добавляем один патрон
    if current_weapon_slot.reserve_ammo > 0:
        current_weapon_slot.current_ammo += 1
        current_weapon_slot.reserve_ammo -= 1
        update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    
    # Проверяем нужно ли продолжать
    if should_continue_reloading():
        start_reload_sequence()
    else:
        is_reloading = false

func finish_full_reload() -> void:
    # Полная перезарядка магазина
    var needed = current_weapon_slot.weapon.magazine_size - current_weapon_slot.current_ammo
    var can_add = min(needed, current_weapon_slot.reserve_ammo)
    
    current_weapon_slot.current_ammo += can_add
    current_weapon_slot.reserve_ammo -= can_add
    
    update_ammo.emit([current_weapon_slot.current_ammo, current_weapon_slot.reserve_ammo])
    is_reloading = false

func play_empty_reload_animation() -> void:
    var weapon_instance = weapon_instances[current_weapon_slot]
    if weapon_instance.has_node("AnimationPlayer"):
        var weapon_anim = weapon_instance.get_node("AnimationPlayer")
        if weapon_anim.has_animation("reload_empty"):
            weapon_anim.play("reload_empty")
    
    if hands_instance.has_method("play_animation"):
        hands_instance.play_animation(
            current_weapon_slot.weapon.hands_empty_reload_animation,
            current_weapon_slot.weapon.hands_animation_speed
        )

func interrupt_reload() -> void:
    if is_reloading:
        reload_interrupted = true
        is_reloading = false
        
        var weapon_instance = weapon_instances[current_weapon_slot]
        if weapon_instance.has_node("AnimationPlayer"):
            weapon_instance.get_node("AnimationPlayer").stop()
        
        if hands_instance.has_method("stop_animation"):
            hands_instance.stop_animation()

func should_continue_reloading() -> bool:
    return (
        !reload_interrupted and
        current_weapon_slot.current_ammo < current_weapon_slot.weapon.magazine_size and
        current_weapon_slot.reserve_ammo > 0 and
        Input.is_action_pressed("reload")  # Продолжать если игрок держит кнопку
    )
