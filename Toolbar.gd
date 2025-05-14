extends HBoxContainer

signal tool_selected(tool: MapEditor.Tools)
signal brush_size_changed(size: int)
signal grid_snap_toggled(enabled: bool)

func _ready():
    $BrushSizeSpinBox.value_changed.connect(func(v): brush_size_changed.emit(v))
    $GridSnapCheckBox.toggled.connect(grid_snap_toggled)

func _on_button_pressed(tool: int):
    tool_selected.emit(tool)
