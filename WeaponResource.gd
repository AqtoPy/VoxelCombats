extends Resource
class_name WeaponResource

@export_category("Base Settings")
@export var weapon_id: String
@export var weapon_name: String
@export var slot_type: int  # WeaponManager.WeaponSlot

@export_category("Combat Settings")
@export var damage: int
@export var fire_rate: float
@export var magazine_size: int
@export var max_reserve_ammo: int
@export var reload_time: float

@export_category("Visual Settings")
@export var weapon_model: PackedScene
@export var texture_albedo: Texture2D
@export var has_scope: bool
@export var scope_texture: Texture2D

@export_category("Animations")
@export var hands_animations: Dictionary = {
    "draw": "draw_rifle",
    "fire": "fire_rifle",
    "reload": "reload_rifle"
}

@export_category("Ballistics")
@export var bullet_scene: PackedScene
@export var bullet_speed: float
@export var bullet_drop: float
