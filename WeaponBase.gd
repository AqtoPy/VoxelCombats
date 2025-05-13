extends Node3D
class_name WeaponBase

# Основные свойства
@export var weapon_id: String
@export var weapon_name: String
@export var current_ammo: int
@export var reserve_ammo: int
@export var skins: Dictionary = {}

# Ссылки на узлы
@onready var animation_player = $AnimationPlayer
@onready var muzzle = $Muzzle
@onready var mesh = $MeshInstance3D

func _ready():
    current_ammo = get_magazine_size()
    reserve_ammo = get_max_ammo() - current_ammo

func fire():
    if can_fire():
        animation_player.play("shoot")
        current_ammo -= 1
        spawn_projectile()
        return true
    return false

func reload():
    animation_player.play("reload")
    await animation_player.animation_finished
    finish_reload()

func apply_skin(skin_id: String):
    if skins.has(skin_id):
        mesh.material_override = skins[skin_id]

func spawn_projectile():
    var projectile = get_projectile_scene().instantiate()
    get_tree().root.add_child(projectile)
    projectile.global_transform = muzzle.global_transform
