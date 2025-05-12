extends Node
class_name Spray_Profile

@export_category("CSGO AK-47 Settings")
@export var vertical_climb: float = 0.8    # Вертикальный подъем ствола
@export var horizontal_shift: float = 0.3  # Горизонтальное смещение вправо
@export var pattern_scale: float = 1.2     # Масштаб всего паттерна
@export var recoil_reset_speed: float = 2.5 # Скорость восстановления прицела

# Настройки специфичные для AK-47
var csgo_pattern = [
    Vector2(0.00, 0.00),
    Vector2(-0.10, 0.50),
    Vector2(0.20, 1.00),
    Vector2(0.40, 1.40),
    Vector2(0.60, 1.80),
    Vector2(0.80, 2.20),
    Vector2(1.00, 2.60),
    Vector2(1.20, 3.00),
    Vector2(1.40, 3.40),
    Vector2(1.60, 3.80),
    Vector2(1.80, 4.20),
    Vector2(2.00, 4.60),
    Vector2(2.20, 5.00),
    Vector2(2.40, 5.40),
    Vector2(2.60, 5.80),
    Vector2(2.80, 6.20),
    Vector2(3.00, 6.60),
    Vector2(3.20, 7.00),
    Vector2(3.40, 7.40),
    Vector2(3.60, 7.80),
    Vector2(3.80, 8.20),
    Vector2(4.00, 8.60),
    Vector2(4.20, 9.00),
    Vector2(4.40, 9.40),
    Vector2(4.60, 9.80),
    Vector2(4.80, 10.20),
    Vector2(5.00, 10.60),
    Vector2(5.20, 11.00),
    Vector2(5.40, 11.40),
    Vector2(5.60, 11.80)
]

func Get_Spray(count: int, _max_count: int) -> Vector2:
    var pattern_index = min(count, csgo_pattern.size() - 1)
    var base_spray = csgo_pattern[pattern_index]
    
    # Применяем настройки
    var adjusted_spray = Vector2(
        base_spray.x * horizontal_shift * pattern_scale,
        base_spray.y * vertical_climb * pattern_scale
    )
    
    # Добавляем небольшую случайную составляющую как в оригинале
    var random_offset = Vector2(
        randf_range(-0.05, 0.05) * pattern_scale,
        randf_range(-0.02, 0.02) * pattern_scale
    )
    
    # Плавное восстановление прицела
    var recoil_recovery = 1.0 - clamp(float(count) / _max_count, 0.0, 1.0)
    var final_spray = (adjusted_spray + random_offset) * recoil_recovery
    
    return final_spray
