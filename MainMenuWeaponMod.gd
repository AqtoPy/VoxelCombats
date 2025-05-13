extends Control

signal weapon_purchased(weapon_name: String)
signal weapon_selected(weapon_slot: WeaponSlot)

@onready var weapon_shop = preload("res://Weapons/WeaponShop.gd").new()
@onready var player_money: int = 1000 # Начальные деньги игрока
@onready var weapon_manager: WeaponManager # Будет установлен при подключении

var available_weapons: Array[WeaponSlot] = []
var purchased_weapons: Array[WeaponSlot] = []

func _ready():
    # Инициализация магазина
    weapon_shop.initialize()
    update_shop_ui()
    
    # Подключаем сигналы кнопок
    $Shop/PistolBuyButton.connect("pressed", buy_weapon.bind("pistol"))
    $Shop/RifleBuyButton.connect("pressed", buy_weapon.bind("rifle"))
    $Shop/ShotgunBuyButton.connect("pressed", buy_weapon.bind("shotgun"))
    
    # Кнопки выбора оружия
    $WeaponSelect/PistolSelectButton.connect("pressed", select_weapon.bind("pistol"))
    $WeaponSelect/RifleSelectButton.connect("pressed", select_weapon.bind("rifle"))
    $WeaponSelect/ShotgunSelectButton.connect("pressed", select_weapon.bind("shotgun"))

func buy_weapon(weapon_name: String):
    if weapon_shop.buy_weapon(weapon_name, player_money):
        player_money -= weapon_shop.get_weapon_cost(weapon_name)
        var weapon_slot = weapon_shop.create_weapon_slot(weapon_name)
        purchased_weapons.append(weapon_slot)
        update_shop_ui()
        update_weapon_select_ui()
        weapon_purchased.emit(weapon_name)

func select_weapon(weapon_name: String):
    for weapon_slot in purchased_weapons:
        if weapon_slot.weapon.weapon_name == weapon_name:
            weapon_selected.emit(weapon_slot)
            break

func update_shop_ui():
    $Shop/MoneyLabel.text = "Money: %d" % player_money
    $Shop/PistolBuyButton.disabled = player_money < weapon_shop.get_weapon_cost("pistol") or is_weapon_purchased("pistol")
    $Shop/RifleBuyButton.disabled = player_money < weapon_shop.get_weapon_cost("rifle") or is_weapon_purchased("rifle")
    $Shop/ShotgunBuyButton.disabled = player_money < weapon_shop.get_weapon_cost("shotgun") or is_weapon_purchased("shotgun")

func update_weapon_select_ui():
    $WeaponSelect/PistolSelectButton.visible = is_weapon_purchased("pistol")
    $WeaponSelect/RifleSelectButton.visible = is_weapon_purchased("rifle")
    $WeaponSelect/ShotgunSelectButton.visible = is_weapon_purchased("shotgun")

func is_weapon_purchased(weapon_name: String) -> bool:
    for weapon_slot in purchased_weapons:
        if weapon_slot.weapon.weapon_name == weapon_name:
            return true
    return false

func connect_to_weapon_manager(manager: WeaponManager):
    weapon_manager = manager
    weapon_purchased.connect(manager._on_weapon_purchased)
    weapon_selected.connect(manager._on_weapon_selected)
