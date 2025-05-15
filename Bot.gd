extends CharacterBody3D

@export var health := 100
@export var destroy_parts : Array[Node3D]  # Добавьте сюда все части тела в инспекторе
@export var standing_animation : AnimationPlayer  # Анимация "стояния"

var is_alive := true
var original_positions := {}

func _ready():
    # Сохраняем оригинальные позиции частей
    for part in destroy_parts:
        original_positions[part] = part.transform
    
    # Проигрываем анимацию стояния
    if standing_animation:
        standing_animation.play("stand")

func take_damage(damage: int):
    if !is_alive:
        return
    
    health -= damage
    if health <= 0:
        die()

func die():
    is_alive = false
    
    # Отключаем основное тело
    $CollisionShape3D.disabled = true
    visible = false
    
    # Включаем физику для частей
    for part in destroy_parts:
        part.visible = true
        part.set_script(preload("res://scripts/physics_part.gd"))
        
        # Добавляем случайную силу для эффекта разлета
        var rigid_body = part as RigidBody3D
        if rigid_body:
            rigid_body.apply_impulse(
                Vector3(randf_range(-5, 5), 
                Vector3(randf_range(-2, 2), 
                randf_range(5, 10))
    
    # Удаляем части через 5 секунд
    await get_tree().create_timer(5.0).timeout
    queue_free()

func reset_mannequin():
    # Сброс манекена в исходное состояние (если нужно)
    is_alive = true
    health = 100
    visible = true
    $CollisionShape3D.disabled = false
    
    for part in destroy_parts:
        part.transform = original_positions[part]
        part.visible = false
        part.set_script(null)
    
    if standing_animation:
        standing_animation.play("stand")
