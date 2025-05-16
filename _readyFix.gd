func _ready() -> void:
    # Инициализация рук
    if hands_scene and !hands_instance:
        hands_instance = hands_scene.instantiate()
        add_child(hands_instance)
        hands_instance.owner = self
        
        # Переносим руки на верхний уровень иерархии
        move_child(hands_instance, 0)
    
    # Загрузка оружия
    load_default_weapons()
    
    # Инициализация текущего оружия
    if !weapon_stack.is_empty():
        for slot in weapon_stack:
            initialize_weapon(slot)
        enter(weapon_stack[0])
