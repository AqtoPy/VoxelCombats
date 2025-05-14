extends StaticBody3D

@export var block_data := {
    "id": 0,
    "position": Vector3.ZERO,
    "layer": 0
}

var is_selected := false :
    set(value):
        is_selected = value
        _update_material()

func setup(data: Dictionary, library: Resource):
    block_data = data
    $MeshInstance3D.mesh = library.get_block(data.id).mesh
    $MeshInstance3D.material_override = library.get_block(data.id).material

func _update_material():
    if is_selected:
        $MeshInstance3D.material_override.albedo_color = Color(1, 0.5, 0)
    else:
        $MeshInstance3D.material_override.albedo_color = Color.WHITE
