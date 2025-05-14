extends HBoxContainer

@onready var cursor_label = $CursorPosition
@onready var tool_label = $CurrentTool
@onready var layer_label = $CurrentLayer

func update_cursor_position(pos: Vector3):
    cursor_label.text = "X: %d Y: %d Z: %d" % [pos.x, pos.y, pos.z]

func update_tool(tool_name: String):
    tool_label.text = "Tool: %s" % tool_name

func update_layer(layer_index: int, layer_name: String):
    layer_label.text = "Layer: %d (%s)" % [layer_index + 1, layer_name]
