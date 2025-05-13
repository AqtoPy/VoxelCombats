extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_position: Marker3D = $RightHand/WeaponPosition

enum HandState {
    IDLE,
    DRAWING,
    HOLSTERING,
    AIMING,
    SHOOTING,
    RELOADING,
    MELEE
}

var current_state: HandState = HandState.IDLE

func _ready():
    _setup_animations()

func _setup_animations():
    # IDLE - базовая анимация покоя
    var idle_anim = Animation.new()
    idle_anim.length = 1.0
    animation_player.add_animation("idle", idle_anim)
    
    # DRAW - доставание оружия
    var draw_anim = Animation.new()
    draw_anim.length = 0.5
    var track_idx = draw_anim.add_track(Animation.TYPE_VALUE)
    draw_anim.track_set_path(track_idx, "RightHand:position")
    draw_anim.value_track_set_update_mode(track_idx, Animation.UPDATE_CONTINUOUS)
    draw_anim.track_insert_key(track_idx, 0.0, Vector3(0.5, 0.5, 0.0)) # Начальная позиция (рука у пояса)
    draw_anim.track_insert_key(track_idx, 0.5, Vector3(0.3, 0, 0))     # Конечная позиция
    animation_player.add_animation("draw", draw_anim)
    
    # HOLSTER - убирание оружия
    var holster_anim = draw_anim.duplicate()
    holster_anim.track_set_key_value(track_idx, 0, Vector3(0.3, 0, 0))
    holster_anim.track_set_key_value(track_idx, 1, Vector3(0.5, 0.5, 0.0))
    holster_anim.length = 0.4
    animation_player.add_animation("holster", holster_anim)
    
    # SHOOT - анимация стрельбы с отдачей
    var shoot_anim = Animation.new()
    shoot_anim.length = 0.2
    var shoot_track = shoot_anim.add_track(Animation.TYPE_VALUE)
    shoot_anim.track_set_path(shoot_track, "RightHand:position:z")
    shoot_anim.track_insert_key(shoot_track, 0.0, 0.0)
    shoot_anim.track_insert_key(shoot_track, 0.05, -0.15) # Отдача
    shoot_anim.track_insert_key(shoot_track, 0.2, 0.0)    # Возврат
    animation_player.add_animation("shoot", shoot_anim)
    
    # RELOAD - перезарядка
    var reload_anim = Animation.new()
    reload_anim.length = 2.0
    var reload_track = reload_anim.add_track(Animation.TYPE_VALUE)
    reload_anim.track_set_path(reload_track, "RightHand:rotation_degrees:x")
    reload_anim.track_insert_key(reload_track, 0.0, 0.0)
    reload_anim.track_insert_key(reload_track, 0.5, -45.0) # Наклон для перезарядки
    reload_anim.track_insert_key(reload_track, 1.5, -45.0)
    reload_anim.track_insert_key(reload_track, 2.0, 0.0)
    animation_player.add_animation("reload", reload_anim)
    
    # MELEE - удар прикладом
    var melee_anim = Animation.new()
    melee_anim.length = 0.7
    var melee_pos_track = melee_anim.add_track(Animation.TYPE_VALUE)
    melee_anim.track_set_path(melee_pos_track, "RightHand:position")
    melee_anim.track_insert_key(melee_pos_track, 0.0, Vector3(0.3, 0, 0))
    melee_anim.track_insert_key(melee_pos_track, 0.2, Vector3(0.6, -0.2, -0.4)) # Удар
    melee_anim.track_insert_key(melee_pos_track, 0.7, Vector3(0.3, 0, 0))
    animation_player.add_animation("melee", melee_anim)
    
    # AIM - прицеливание
    var aim_anim = Animation.new()
    aim_anim.length = 0.3
    var aim_track = aim_anim.add_track(Animation.TYPE_VALUE)
    aim_anim.track_set_path(aim_track, "RightHand:position")
    aim_anim.track_insert_key(aim_track, 0.0, Vector3(0.3, 0, 0))
    aim_anim.track_insert_key(aim_track, 0.3, Vector3(0.1, -0.1, 0.5)) # Позиция прицеливания
    animation_player.add_animation("aim_in", aim_anim)
    
    var aim_out_anim = aim_anim.duplicate()
    aim_out_anim.track_set_key_value(aim_track, 0, Vector3(0.1, -0.1, 0.5))
    aim_out_anim.track_set_key_value(aim_track, 1, Vector3(0.3, 0, 0))
    animation_player.add_animation("aim_out", aim_out_anim)

func play_animation(anim_name: String, speed: float = 1.0) -> void:
    if animation_player.has_animation(anim_name):
        animation_player.play(anim_name, -1, speed)
        match anim_name:
            "draw": current_state = HandState.DRAWING
            "holster": current_state = HandState.HOLSTERING
            "shoot": current_state = HandState.SHOOTING
            "reload": current_state = HandState.RELOADING
            "melee": current_state = HandState.MELEE
            "aim_in", "aim_out": current_state = HandState.AIMING
            _: current_state = HandState.IDLE

func get_weapon_position() -> Marker3D:
    return weapon_position

func is_busy() -> bool:
    return current_state != HandState.IDLE && current_state != HandState.AIMING

func _on_animation_finished(anim_name: String):
    if anim_name in ["draw", "holster", "reload", "melee", "aim_out"]:
        current_state = HandState.IDLE
    elif anim_name == "aim_in":
        current_state = HandState.AIMING
