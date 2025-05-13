extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_position: Marker3D = $RightHand/WeaponPosition

func play_animation(anim_name: String) -> void:
    if animation_player.has_animation(anim_name):
        animation_player.play(anim_name)

func get_weapon_position() -> Marker3D:
    return weapon_position

# Базовые анимации можно добавить в код или через редактор
func _ready():
    # Анимация idle
    var idle_anim = Animation.new()
    idle_anim.length = 1.0
    animation_player.add_animation("idle", idle_anim)
    
    # Анимация стрельбы
    var shoot_anim = Animation.new()
    shoot_anim.length = 0.2
    var track_idx = shoot_anim.add_track(Animation.TYPE_VALUE)
    shoot_anim.track_set_path(track_idx, "RightHand:position:z")
    shoot_anim.track_insert_key(track_idx, 0.0, 0.0)
    shoot_anim.track_insert_key(track_idx, 0.1, -0.1)  # Отдача
    shoot_anim.track_insert_key(track_idx, 0.2, 0.0)   # Возврат
    animation_player.add_animation("shoot", shoot_anim)
    
    # Анимация перезарядки
    var reload_anim = Animation.new()
    reload_anim.length = 1.5
    animation_player.add_animation("reload", reload_anim)
