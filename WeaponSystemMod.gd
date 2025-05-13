# WeaponResource

@export_group("Hand Animations")
## Анимация доставания оружия для рук
@export var hands_draw_animation: String = "draw"
## Анимация убирания оружия для рук
@export var hands_holster_animation: String = "holster"
## Анимация прицеливания для рук
@export var hands_aim_in_animation: String = "aim_in"
## Анимация выхода из прицеливания для рук
@export var hands_aim_out_animation: String = "aim_out"
## Анимация удара прикладом для рук
@export var hands_melee_animation: String = "melee"
## Скорость проигрывания анимаций рук
@export var hands_animation_speed: float = 1.0

# WeaponManager

# В метод enter() добавьте:
hands.play_animation(current_weapon_slot.weapon.hands_draw_animation, 
                   current_weapon_slot.weapon.hands_animation_speed)

# В метод exit() добавьте:
hands.play_animation(current_weapon_slot.weapon.hands_holster_animation,
                   current_weapon_slot.weapon.hands_animation_speed)

# Новый метод для прицеливания:
func aim(is_aiming: bool):
    if is_aiming:
        hands.play_animation(current_weapon_slot.weapon.hands_aim_in_animation,
                          current_weapon_slot.weapon.hands_animation_speed)
    else:
        hands.play_animation(current_weapon_slot.weapon.hands_aim_out_animation,
                          current_weapon_slot.weapon.hands_animation_speed)

# В метод melee() добавьте:
hands.play_animation(current_weapon_slot.weapon.hands_melee_animation,
                   current_weapon_slot.weapon.hands_animation_speed)

# В метод _on_animation_finished() добавьте обработку анимаций рук:
match anim_name:
    current_weapon_slot.weapon.hands_draw_animation:
        # Оружие полностью достато
        pass
    current_weapon_slot.weapon.hands_holster_animation:
        # Оружие полностью убрано
        pass

# Hands

# В _setup_animations() добавьте вариации анимаций для разного оружия:

# Для винтовки
func _setup_rifle_animations():
    var rifle_draw = draw_anim.duplicate()
    rifle_draw.length = 0.6
    animation_player.add_animation("rifle_draw", rifle_draw)
    
    var rifle_aim = aim_anim.duplicate()
    rifle_aim.track_set_key_value(aim_track, 1, Vector3(0.05, -0.15, 0.6))
    animation_player.add_animation("rifle_aim_in", rifle_aim)

# Для пистолета
func _setup_pistol_animations():
    var pistol_draw = draw_anim.duplicate()
    pistol_draw.length = 0.4
    animation_player.add_animation("pistol_draw", pistol_draw)

# integration

# В WeaponManager добавьте проверки:
func _process(delta):
    if hands.is_busy() and not current_weapon_slot.weapon.can_interrupt_animations:
        return
        
    # Остальная логика обработки ввода
