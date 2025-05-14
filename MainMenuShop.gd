# MainMenu.gd
extends Control

class WeaponCategory:
    enum {
        PRIMARY,
        SECONDARY,
        EXPLOSIVE
    }

var player_weapons: Dictionary = {
    WeaponCategory.PRIMARY: null,
    WeaponCategory.SECONDARY: null,
    WeaponCategory.EXPLOSIVE: null
}

var weapon_shop = {
    "AK-47": {
        "category": WeaponCategory.PRIMARY,
        "cost": 3000,
        "texture": preload("res://icons/ak47.png"),
        "scene": preload("res://weapons/ak47.tscn")
    },
    "Glock": {
        "category": WeaponCategory.SECONDARY,
        "cost": 500,
        "texture": preload("res://icons/glock.png"),
        "scene": preload("res://weapons/glock.tscn")
    },
    "C4": {
        "category": WeaponCategory.EXPLOSIVE,
        "cost": 1500,
        "texture": preload("res://icons/c4.png"),
        "scene": preload("res://weapons/c4.tscn")
    }
}

func _ready():
    # Загрузка стандартного оружия
    equip_default_weapons()

func equip_default_weapons():
    player_weapons[WeaponCategory.PRIMARY] = preload("res://weapons/m4a1.tscn")
    player_weapons[WeaponCategory.SECONDARY] = preload("res://weapons/pistol.tscn")

func buy_weapon(weapon_name: String, player_money: int) -> bool:
    if !weapon_shop.has(weapon_name):
        push_error("Weapon %s not found in shop!" % weapon_name)
        return false
    
    var weapon_data = weapon_shop[weapon_name]
    if player_money >= weapon_data["cost"]:
        var category = weapon_data["category"]
        player_weapons[category] = weapon_data["scene"]
        save_weapons()
        update_weapon_ui()
        return true
    return false

func equip_weapon(category: int, slot: int):
    var weapon_scene = player_weapons.get(category)
    if weapon_scene:
        # Отправляем оружие в WeaponManager
        var weapon_manager = get_node("/root/Main/Player/WeaponManager")
        weapon_manager.equip_to_slot(slot, weapon_scene)

func save_weapons():
    var save_data = {}
    for category in player_weapons:
        if player_weapons[category]:
            save_data[category] = player_weapons[category].resource_path
    # Сохраняем в FileSystem или PlayerPrefs

func update_weapon_ui():
    # Обновляем UI магазина
    $WeaponShop.update_weapons(player_weapons)
