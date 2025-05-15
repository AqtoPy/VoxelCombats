extends RigidBody3D

func _ready():
    # Настройка физики для части
    gravity_scale = 1.0
    linear_damp = 0.5
    angular_damp = 0.5
    contact_monitor = true
    max_contacts_reported = 1
