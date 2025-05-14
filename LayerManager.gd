extends VBoxContainer

signal layer_added
signal layer_removed(index: int)
signal layer_visibility_changed(index: int, visible: bool)
signal layer_selected(index: int)

var layers = []

func _ready():
    _create_layer_item(0, "Base", true)

func add_layer(name: String):
    var index = layers.size()
    _create_layer_item(index, name, true)
    layers.append({"name": name, "visible": true})
    layer_added.emit()

func _create_layer_item(index: int, name: String, visible: bool):
    var hbox = HBoxContainer.new()
    
    var vis_btn = CheckBox.new()
    vis_btn.button_pressed = visible
    vis_btn.toggled.connect(func(v): layer_visibility_changed.emit(index, v))
    
    var label = Label.new()
    label.text = "Layer %d: %s" % [index + 1, name]
    
    var select_btn = Button.new()
    select_btn.text = "Select"
    select_btn.pressed.connect(func(): layer_selected.emit(index))
    
    hbox.add_child(vis_btn)
    hbox.add_child(label)
    hbox.add_child(select_btn)
    add_child(hbox)

func _on_remove_layer_pressed(index: int):
    if layers.size() > 1:
        layers.remove_at(index)
        get_child(index).queue_free()
        layer_removed.emit(index)
