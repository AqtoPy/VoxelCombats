extends Node3D
class_name WeaponManager

signal weapon_changed(weapon_data: Dictionary)
signal ammo_updated(current: int, reserve: int)
signal skin_updated(weapon_id: String, skin_id: String)
signal zoom_state_changed(is_zoomed: bool)

@export var max_weapons: int = 3
@export var hands_scene: PackedScene
@export var default_fov: float = 75.0

var current_weapon: Node3D = null
var weapons: Array = []
var current_slot: int = 0
var is_reloading: bool = false
var is_zoomed: bool = false
var current_skin: String = "default"

var weapon_slots: Dictionary = {
    "primary": null,
    "secondary": null,
    "melee": null
}

func _ready():
    load_player_loadout()
    spawn_hands()
    equip_weapon("primary")

func spawn_hands():
    if hands_scene:
        var hands = hands_scene.instantiate()
        add_child(hands)

func load_player_loadout():
    var loadout = PlayerData.get_current_loadout()
    
    for slot in loadout.weapons:
        var weapon_data = loadout.weapons[slot]
        var weapon = weapon_data.weapon_scene.instantiate()
        
        # Применяем сохраненный скин
        if weapon_data.has("skin"):
            weapon.apply_skin(weapon_data.skin)
            current_skin = weapon_data.skin
        
        weapon_slots[slot] = weapon
        add_child(weapon)
        weapon.hide()

func equip_weapon(slot: String):
    if weapon_slots[slot] == null:
        return
    
    if current_weapon:
        unequip_current_weapon()
    
    current_weapon = weapon_slots[slot]
    current_weapon.show()
    
    var weapon_data = {
        "name": current_weapon.weapon_name,
        "slot": slot,
        "skin": current_skin
    }
    
    emit_signal("weapon_changed", weapon_data)
    update_ammo_display()

func unequip_current_weapon():
    if current_weapon:
        current_weapon.hide()

func update_ammo_display():
    if current_weapon:
        emit_signal("ammo_updated", 
            current_weapon.current_ammo, 
            current_weapon.reserve_ammo)

func _input(event):
    handle_weapon_input(event)
    handle_zoom_input(event)

func handle_weapon_input(event):
    if event.is_action_pressed("slot1"):
        equip_weapon("primary")
    elif event.is_action_pressed("slot2"):
        equip_weapon("secondary")
    elif event.is_action_pressed("slot3"):
        equip_weapon("melee")
    elif event.is_action_pressed("reload"):
        start_reload()
    elif event.is_action_pressed("shoot"):
        start_firing()
    elif event.is_action_released("shoot"):
        stop_firing()

func handle_zoom_input(event):
    if event.is_action_pressed("zoom") and current_weapon.can_zoom:
        toggle_zoom()

func toggle_zoom():
    is_zoomed = !is_zoomed
    if is_zoomed:
        get_viewport().get_camera_3d().fov = current_weapon.zoom_fov
    else:
        get_viewport().get_camera_3d().fov = default_fov
    emit_signal("zoom_state_changed", is_zoomed)

func start_firing():
    if can_fire():
        current_weapon.fire()
        update_ammo_display()

func can_fire() -> bool:
    return !is_reloading && current_weapon.current_ammo > 0

func start_reload():
    if can_reload():
        is_reloading = true
        current_weapon.reload()
        await get_tree().create_timer(current_weapon.reload_time).timeout
        finish_reload()

func can_reload() -> bool:
    return !is_reloading && current_weapon.reserve_ammo > 0

func finish_reload():
    var ammo_needed = current_weapon.magazine_size - current_weapon.current_ammo
    var ammo_from_reserve = min(ammo_needed, current_weapon.reserve_ammo)
    
    current_weapon.current_ammo += ammo_from_reserve
    current_weapon.reserve_ammo -= ammo_from_reserve
    
    is_reloading = false
    update_ammo_display()

func change_weapon_skin(skin_id: String):
    if current_weapon:
        current_weapon.apply_skin(skin_id)
        current_skin = skin_id
        emit_signal("skin_updated", current_weapon.weapon_id, skin_id)
        PlayerData.set_weapon_skin(current_weapon.weapon_id, skin_id)
