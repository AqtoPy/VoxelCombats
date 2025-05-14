# MapEditor.gd (дополнение)
func _ready():
    $UI/Toolbar.tool_selected.connect(_on_tool_selected)
    $UI/BlockPalette.block_selected.connect(_on_block_selected)
    $UI/SaveDialog.save_confirmed.connect(_on_save_confirmed)

func _on_tool_selected(tool: Tools):
    current_tool = tool
    update_cursor()

func _on_block_selected(block_id: int):
    selected_block = block_id
    _update_brush_preview()

func _on_save_confirmed(file_name: String):
    save_map(file_name)
