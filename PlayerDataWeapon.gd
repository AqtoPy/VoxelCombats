# PlayerData.gd (автозагружаемый скрипт)
extends Node

var weapons_unlocked: Dictionary = {
    "ak47": true,
    "pistol": true,
    "knife": true
}

var weapon_skins: Dictionary = {
    "ak47": "default",
    "pistol": "default"
}

func unlock_weapon(weapon_id: String):
    weapons_unlocked[weapon_id] = true

func set_weapon_skin(weapon_id: String, skin_id: String):
    weapon_skins[weapon_id] = skin_id
    save_data()

func get_weapon_skin(weapon_id: String) -> String:
    return weapon_skins.get(weapon_id, "default")
