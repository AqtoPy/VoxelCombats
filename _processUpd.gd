func _process(delta: float) -> void:
    if !is_instance_valid(current_weapon_slot) or !hands_instance:
        return

    # Не обрабатываем ввод, если руки заняты анимацией
    if hands_instance.is_busy:
        return

    # Проверка действий с оружием
    if Input.is_action_pressed("shoot"):
        if check_valid_weapon_slot() and current_weapon_slot.current_ammo > 0:
            shoot()
        else:
            # Попытка стрельбы при пустом магазине
            if check_valid_weapon_slot() and current_weapon_slot.reserve_ammo > 0:
                reload()

    # Автоматическая перезарядка
    if check_valid_weapon_slot() and current_weapon_slot.current_ammo <= 0:
        if current_weapon_slot.reserve_ammo > 0:
            reload()

    # Переключение оружия колесом мыши
    handle_weapon_switch_input()

    # Обновление позиции оружия в руках
    if weapon_instances.has(current_weapon_slot):
        var weapon_node = weapon_instances[current_weapon_slot]
        if weapon_node:
            weapon_node.global_transform = hands_instance.get_node("WeaponPosition").global_transform


# other

func handle_weapon_switch_input() -> void:
    var scroll_value = Input.get_axis("weapon_prev", "weapon_next")
    if scroll_value != 0:
        var current_index = weapon_stack.find(current_weapon_slot)
        var new_index = wrapi(current_index + scroll_value, 0, weapon_stack.size())
        var new_slot = weapon_stack[new_index]
        
        if new_slot != current_weapon_slot:
            exit(current_weapon_slot)
            enter(new_slot)

func check_valid_weapon_slot() -> bool:
    return (
        is_instance_valid(current_weapon_slot) and 
        is_instance_valid(current_weapon_slot.weapon) and 
        weapon_instances.has(current_weapon_slot)
    )
