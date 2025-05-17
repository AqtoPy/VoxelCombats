# server_creation_ui.gd
extends Control

@onready var name_edit = $Form/NameEdit
@onready var port_edit = $Form/PortEdit
@onready var players_slider = $Form/PlayersSlider
@onready var map_selector = $Form/MapSelector
@onready var custom_map_path = $Form/CustomMapPath

var default_maps = ["Dust", "Inferno", "Mirage"]
var custom_maps = []

func _ready():
    load_custom_maps()
    populate_map_selector()

func load_custom_maps():
    var dir = DirAccess.open("user://custom_content/maps/")
    if dir:
        custom_maps = dir.get_files()

func populate_map_selector():
    map_selector.clear()
    for map in default_maps + custom_maps:
        map_selector.add_item(map)

func _on_CreateButton_pressed():
    var config = {
        "name": name_edit.text,
        "port": port_edit.text.to_int(),
        "max_players": players_slider.value,
        "map": map_selector.get_item_text(map_selector.selected),
        "use_custom_map": map_selector.selected >= default_maps.size(),
        "map_path": "user://custom_content/maps/" + custom_maps[map_selector.selected - default_maps.size()] if map_selector.selected >= default_maps.size() else "",
        "password": $Form/PasswordEdit.text,
        "rules": get_custom_rules()
    }
    
    ServerSystem.create_custom_server(config)

func get_custom_rules():
    return {
        "friendly_fire": $Form/FriendlyFire.pressed,
        "round_time": $Form/RoundTime.value,
        "custom_gravity": $Form/Gravity.value
    }

func _on_CustomMapButton_pressed():
    $FileDialog.show()

func _on_FileDialog_file_selected(path):
    custom_map_path.text = path
