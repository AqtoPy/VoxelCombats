extends Node

var weapons = {
    "pistol": {
        "cost": 100,
        "scene": preload("res://Weapons/Pistol.tscn"),
        "resource": preload("res://Weapons/Resources/PistolResource.tres")
    },
    "rifle": {
        "cost": 300,
        "scene": preload("res://Weapons/Rifle.tscn"),
        "resource": preload("res://Weapons/Resources/RifleResource.tres")
    },
    "shotgun": {
        "cost": 500,
        "scene": preload("res://Weapons/Shotgun.tscn"),
        "resource": preload("res://Weapons/Resources/ShotgunResource.tres")
    }
}

func initialize():
    # Можно добавить дополнительную инициализацию
    pass

func buy_weapon(weapon_name: String, player_money: int) -> bool:
    if weapons.has(weapon_name) and player_money >= weapons[weapon_name]["cost"]:
        return true
    return false

func get_weapon_cost(weapon_name: String) -> int:
    return weapons.get(weapon_name, {}).get("cost", 0)

func create_weapon_slot(weapon_name: String) -> WeaponSlot:
    var slot = WeaponSlot.new()
    slot.weapon = weapons[weapon_name]["resource"]
    slot.current_ammo = slot.weapon.magazine
    slot.reserve_ammo = slot.weapon.max_ammo
    return slot
