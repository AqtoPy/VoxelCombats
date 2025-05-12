extends Node3D

signal weapon_changed(weapon_data)
signal ammo_updated(current, reserve)
signal scope_toggled(is_scoped)

@export var hands_scene: PackedScene
@export var default_fov: float = 75.0
@export var scope_fov: float = 40.0

enum WeaponSlot {
    PRIMARY,
    SECONDARY,
    MELEE,
    EXPLOSIVE
}

var current_hands: Node3D
var current_weapon: WeaponResource
var current_slot: WeaponSlot = WeaponSlot.PRIMARY
var is_reloading: bool = false
var is_scoped: bool = false

var weapon_slots: Dictionary = {
    WeaponSlot.PRIMARY: null,
    WeaponSlot.SECONDARY: null,
    WeaponSlot.MELEE: null,
    WeaponSlot.EXPLOSIVE: null
}

func _ready():
    load_player_loadout()
    spawn_hands()
    equip_weapon(current_slot)

func spawn_hands():
    if hands_scene:
        current_hands = hands_scene.instantiate()
        add_child(current_hands)

func load_player_loadout():
    # Загрузка сохранённой нагрузки из PlayerData
    var loadout = PlayerData.get_current_loadout()
    
    weapon_slots[WeaponSlot.PRIMARY] = load(loadout.primary)
    weapon_slots[WeaponSlot.SECONDARY] = load(loadout.secondary)
    weapon_slots[WeaponSlot.MELEE] = load(loadout.melee)
    weapon_slots[WeaponSlot.EXPLOSIVE] = load(loadout.explosive)
    
    apply_weapon_skins()

func apply_weapon_skins():
    for slot in weapon_slots:
        var weapon = weapon_slots[slot]
        if weapon and PlayerData.has_skin(weapon.weapon_id):
            var skin = PlayerData.get_skin(weapon.weapon_id)
            weapon.mesh_instance.get_active_material(0).albedo_texture = skin

func equip_weapon(slot: WeaponSlot):
    if weapon_slots[slot]:
        unequip_current_weapon()
        current_weapon = weapon_slots[slot]
        show_weapon_model()
        update_ui()
        play_hands_animation("draw")

func unequip_current_weapon():
    if current_weapon and current_weapon.weapon_model:
        current_weapon.weapon_model.visible = false

func show_weapon_model():
    if current_weapon.weapon_model:
        current_weapon.weapon_model.visible = true
        current_weapon.weapon_model.get_active_material(0).albedo_texture = current_weapon.texture_albedo

func update_ui():
    weapon_changed.emit({
        "name": current_weapon.weapon_name,
        "icon": current_weapon.ui_icon,
        "slot": WeaponSlot.keys()[current_slot]
    })
    ammo_updated.emit(current_weapon.current_ammo, current_weapon.reserve_ammo)

func _input(event):
    handle_weapon_switching(event)
    handle_fire_input(event)
    handle_reload_input(event)
    handle_scope_input(event)

func handle_weapon_switching(event):
    if event.is_action_pressed("slot1"):
        switch_weapon_slot(WeaponSlot.PRIMARY)
    elif event.is_action_pressed("slot2"):
        switch_weapon_slot(WeaponSlot.SECONDARY)
    elif event.is_action_pressed("slot3"):
        switch_weapon_slot(WeaponSlot.MELEE)
    elif event.is_action_pressed("slot4"):
        switch_weapon_slot(WeaponSlot.EXPLOSIVE)

func switch_weapon_slot(new_slot: WeaponSlot):
    if new_slot != current_slot and weapon_slots[new_slot]:
        current_slot = new_slot
        equip_weapon(current_slot)

func handle_fire_input(event):
    if event.is_action_pressed("shoot") and can_fire():
        start_firing()
    elif event.is_action_released("shoot"):
        stop_firing()

func can_fire() -> bool:
    return !is_reloading and current_weapon.current_ammo > 0

func start_firing():
    if current_weapon.auto_fire:
        while Input.is_action_pressed("shoot") and can_fire():
            fire_weapon()
            await get_tree().create_timer(current_weapon.fire_rate).timeout
    else:
        fire_weapon()

func fire_weapon():
    current_weapon.current_ammo -= 1
    play_hands_animation("fire")
    spawn_bullet()
    update_ui()

func stop_firing():
    pass  # Для оружия с непрерывным огнём

func handle_reload_input(event):
    if event.is_action_pressed("reload") and can_reload():
        start_reload()

func can_reload() -> bool:
    return !is_reloading and current_weapon.reserve_ammo > 0

func start_reload():
    is_reloading = true
    play_hands_animation("reload")
    await get_tree().create_timer(current_weapon.reload_time).timeout
    finish_reload()

func finish_reload():
    var ammo_needed = current_weapon.magazine_size - current_weapon.current_ammo
    var ammo_from_reserve = min(ammo_needed, current_weapon.reserve_ammo)
    
    current_weapon.current_ammo += ammo_from_reserve
    current_weapon.reserve_ammo -= ammo_from_reserve
    
    is_reloading = false
    update_ui()

func handle_scope_input(event):
    if event.is_action_pressed("scope") and current_weapon.has_scope:
        toggle_scope()

func toggle_scope():
    is_scoped = !is_scoped
    if is_scoped:
        get_viewport().get_camera_3d().fov = scope_fov
    else:
        get_viewport().get_camera_3d().fov = default_fov
    scope_toggled.emit(is_scoped)

func play_hands_animation(anim_type: String):
    var anim_name = current_weapon.hands_animations[anim_type]
    current_hands.animation_player.play(anim_name)

func spawn_bullet():
    var bullet = current_weapon.bullet_scene.instantiate()
    add_child(bullet)
    bullet.global_transform = $BulletSpawn.global_transform
    bullet.damage = current_weapon.damage
