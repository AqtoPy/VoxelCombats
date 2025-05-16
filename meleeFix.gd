var is_melee_attacking: bool = false
var melee_cooldown: bool = false

func melee() -> void:
    # Проверка базовых условий для удара
    if !check_valid_weapon_slot() or is_melee_attacking or melee_cooldown:
        return
    
    # Проверка, можно ли сейчас наносить удар (не во время стрельбы/перезарядки)
    if (animation_player.is_playing() and 
        (animation_player.current_animation == current_weapon_slot.weapon.shoot_animation or
         animation_player.current_animation == current_weapon_slot.weapon.reload_animation)):
        return
    
    # Начинаем атаку
    start_melee_attack()

func start_melee_attack() -> void:
    is_melee_attacking = true
    
    # Проигрываем анимацию оружия
    var weapon_instance = weapon_instances[current_weapon_slot]
    if weapon_instance.has_node("AnimationPlayer"):
        var weapon_anim = weapon_instance.get_node("AnimationPlayer")
        if weapon_anim.has_animation("melee"):
            weapon_anim.play("melee")
    
    # Проигрываем анимацию рук
    if hands_instance.has_method("play_animation"):
        hands_instance.play_animation(
            current_weapon_slot.weapon.hands_melee_animation,
            current_weapon_slot.weapon.hands_animation_speed
        )
    
    # Настройка хитбокса
    melee_hitbox.force_shapecast_update()
    
    # Проверка попадания с небольшой задержкой (чтобы совпало с анимацией)
    await get_tree().create_timer(0.2).timeout
    check_melee_hit()
    
    # Завершение атаки после анимации
    if weapon_instance.has_node("AnimationPlayer"):
        await weapon_instance.get_node("AnimationPlayer").animation_finished
    is_melee_attacking = false
    
    # КД перед следующим ударом
    melee_cooldown = true
    await get_tree().create_timer(0.5).timeout  # Базовая задержка между ударами
    melee_cooldown = false

func check_melee_hit() -> void:
    if !melee_hitbox.is_colliding():
        return
    
    # Обработка всех целей в радиусе удара
    for i in range(melee_hitbox.get_collision_count()):
        var target = melee_hitbox.get_collider(i)
        if target and target.is_in_group("Target") and target.has_method("hit_successful"):
            # Расчет направления и точки удара
            var direction = (target.global_position - global_position).normalized()
            var position = melee_hitbox.get_collision_point(i)
            
            # Наносим урон
            target.hit_successful(
                current_weapon_slot.weapon.melee_damage, 
                direction, 
                position
            )
            hit_successful.emit()
            
            # Эффект попадания (можно добавить партиклы/звук)
            spawn_melee_effect(position, direction)

func spawn_melee_effect(position: Vector3, direction: Vector3) -> void:
    var effect = preload("res://effects/melee_hit_effect.tscn").instantiate()
    get_tree().root.add_child(effect)
    effect.global_position = position
    effect.look_at(position + direction)
    effect.emitting = true
    await get_tree().create_timer(1.0).timeout
    effect.queue_free()
