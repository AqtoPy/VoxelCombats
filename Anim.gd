enum WeaponCategory {
    PRIMARY,
    SECONDARY,
    MELEE,
    EXPLOSIVE
}

var current_category: WeaponCategory = WeaponCategory.PRIMARY
var weapon_categories: Dictionary = {
    WeaponCategory.PRIMARY: null,
    WeaponCategory.SECONDARY: null,
    WeaponCategory.MELEE: null,
    WeaponCategory.EXPLOSIVE: null
}

# Переписанная функция enter с учетом категорий
func enter(target_slot: WeaponSlot, category: WeaponCategory) -> void:
    if !is_instance_valid(target_slot) or !target_slot.weapon:
        push_error("Invalid weapon slot")
        return
    
    # Выход из текущего оружия если нужно
    if current_weapon_slot and current_weapon_slot != target_slot:
        exit(current_weapon_slot)
    
    # Скрываем все оружие
    for slot in weapon_instances:
        weapon_instances[slot].visible = false
    
    # Показываем выбранное оружие
    weapon_instances[target_slot].visible = true
    current_weapon_slot = target_slot
    current_category = category
    
    # Анимации в зависимости от категории
    match category:
        WeaponCategory.PRIMARY, WeaponCategory.SECONDARY:
            play_firearm_animations(target_slot)
        WeaponCategory.MELEE:
            play_melee_draw_animation(target_slot)
        WeaponCategory.EXPLOSIVE:
            play_explosive_draw_animation(target_slot)
    
    update_hud(target_slot)

func play_firearm_animations(slot: WeaponSlot) -> void:
    if animation_player:
        animation_player.stop()
        animation_player.play(slot.weapon.pick_up_animation)
    
    if hands_instance:
        hands_instance.play_animation(
            slot.weapon.hands_draw_animation,
            slot.weapon.hands_animation_speed
        )

func play_melee_draw_animation(slot: WeaponSlot) -> void:
    if animation_player:
        animation_player.stop()
        animation_player.play("melee_draw")
    
    if hands_instance:
        hands_instance.play_animation(
            "hands_melee_draw",
            slot.weapon.hands_animation_speed
        )

func play_explosive_draw_animation(slot: WeaponSlot) -> void:
    if animation_player:
        animation_player.stop()
        animation_player.play("explosive_draw")
    
    if hands_instance:
        hands_instance.play_animation(
            "hands_explosive_draw",
            slot.weapon.hands_animation_speed
        )

# Переписанная функция exit
func exit(current_slot: WeaponSlot) -> void:
    if !current_slot: return
    
    match current_category:
        WeaponCategory.PRIMARY, WeaponCategory.SECONDARY:
            animation_player.queue(current_slot.weapon.change_animation)
            hands_instance.play_animation(
                current_slot.weapon.hands_holster_animation,
                current_slot.weapon.hands_animation_speed
            )
        WeaponCategory.MELEE:
            animation_player.queue("melee_holster")
            hands_instance.play_animation("hands_melee_holster", 1.0)
        WeaponCategory.EXPLOSIVE:
            animation_player.queue("explosive_holster")
            hands_instance.play_animation("hands_explosive_holster", 1.0)

# Инициализация слотов
func setup_weapon_categories() -> void:
    for slot in weapon_stack:
        match slot.weapon.slot_type:
            "primary":
                weapon_categories[WeaponCategory.PRIMARY] = slot
            "secondary":
                weapon_categories[WeaponCategory.SECONDARY] = slot
            "melee":
                weapon_categories[WeaponCategory.MELEE] = slot
            "explosive":
                weapon_categories[WeaponCategory.EXPLOSIVE] = slot

# Обработка ввода
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("weapon_1"):
        switch_to_weapon(WeaponCategory.PRIMARY)
    elif event.is_action_pressed("weapon_2"):
        switch_to_weapon(WeaponCategory.SECONDARY)
    elif event.is_action_pressed("weapon_3"):
        switch_to_weapon(WeaponCategory.MELEE)
    elif event.is_action_pressed("weapon_4"):
        switch_to_weapon(WeaponCategory.EXPLOSIVE)

func switch_to_weapon(category: WeaponCategory) -> void:
    if category == current_category: 
        return
    
    var target_slot = weapon_categories.get(category)
    if target_slot:
        exit(current_weapon_slot)
        enter(target_slot, category)

# Обновленный HUD
func update_hud(slot: WeaponSlot) -> void:
    weapon_changed.emit(slot.weapon.weapon_name)
    
    match current_category:
        WeaponCategory.PRIMARY, WeaponCategory.SECONDARY:
            update_ammo.emit([slot.current_ammo, slot.reserve_ammo])
            update_crosshair(slot.weapon.crosshair_type)
        WeaponCategory.MELEE:
            update_ammo.emit([0, 0])  # Нет патронов для ножа
            update_crosshair("melee")
        WeaponCategory.EXPLOSIVE:
            update_ammo.emit([slot.current_ammo, 0])  # Только текущие заряды
            update_crosshair("explosive")
