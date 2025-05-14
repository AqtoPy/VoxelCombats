extends Node3D
class_name WeaponManager

# Словарь для хранения экземпляров оружия (Key: WeaponSlot, Value: Node3D)
var weapon_instances: Dictionary = {}

# Вместо weapon_instance в WeaponSlot, используем:
func initialize_weapon(weapon_slot: WeaponSlot):
    if !weapon_slot or !weapon_slot.weapon:
        return

    # Создаем экземпляр оружия
    var weapon_scene = weapon_slot.weapon.weapon_scene.instantiate()
    
    # Сохраняем в словарь
    weapon_instances[weapon_slot] = weapon_scene
    add_child(weapon_scene)
    
    # Настраиваем оружие
    if weapon_scene.has_method("set_weapon_resource"):
        weapon_scene.set_weapon_resource(weapon_slot.weapon)

# Пример использования в других методах:
func set_weapon_visibility(slot: WeaponSlot, visible: bool):
    if slot in weapon_instances:
        weapon_instances[slot].visible = visible

func get_weapon_instance(slot: WeaponSlot) -> Node3D:
    return weapon_instances.get(slot)
