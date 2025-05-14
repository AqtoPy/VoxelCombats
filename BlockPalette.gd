extends ScrollContainer

signal block_selected(block_id: int)

var blocks = []

func setup(block_resources: Array):
    for resource in block_resources:
        var btn = TextureButton.new()
        btn.texture_normal = resource.icon
        btn.custom_minimum_size = Vector2(64, 64)
        btn.pressed.connect(_on_block_pressed.bind(resource.id))
        $GridContainer.add_child(btn)

func _on_block_pressed(block_id: int):
    block_selected.emit(block_id)
