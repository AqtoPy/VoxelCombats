extends Node3D
class_name WeaponBase

# Ссылка на ресурс оружия (должен быть назначен в инспекторе или через код)
@export var weapon_resource: WeaponResource

# Метод для получения ресурса (используется в WeaponSystem)
func get_weapon_resource() -> WeaponResource:
    return weapon_resource
