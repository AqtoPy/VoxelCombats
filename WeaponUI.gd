extends Control
class_name WeaponUI

@onready var weapon_preview = $ViewportContainer/Viewport/WeaponPreview
@onready var skin_list = $SkinList

var current_weapon: WeaponBase = null
var available_weapons: Array = []

func _ready():
    load_available_weapons()
    setup_ui()

func load_available_weapons():
    var weapons_dir = "res://weapons/"
    var dir = DirAccess.open(weapons_dir)
    if dir:
        dir.list_dir_begin()
        var weapon_folder = dir.get_next()
        while weapon_folder != "":
            if dir.current_is_dir():
                var weapon_path = weapons_dir + weapon_folder + "/" + weapon_folder + ".tscn"
                if ResourceLoader.exists(weapon_path):
                    available_weapons.append(load(weapon_path))
            weapon_folder = dir.get_next()

func setup_ui():
    for weapon_scene in available_weapons:
        var btn = Button.new()
        btn.text = weapon_scene.weapon_name
        btn.connect("pressed", self, "_on_weapon_selected", [weapon_scene])
        $WeaponList.add_child(btn)

func _on_weapon_selected(weapon_scene: PackedScene):
    if current_weapon:
        current_weapon.queue_free()
    
    current_weapon = weapon_scene.instantiate()
    weapon_preview.add_child(current_weapon)
    update_skin_list()

func update_skin_list():
    for child in skin_list.get_children():
        child.queue_free()
    
    if current_weapon:
        for skin_id in current_weapon.skins:
            var btn = Button.new()
            btn.text = skin_id
            btn.connect("pressed", self, "_on_skin_selected", [skin_id])
            skin_list.add_child(btn)

func _on_skin_selected(skin_id: String):
    if current_weapon:
        current_weapon.apply_skin(skin_id)
        PlayerData.set_weapon_skin(current_weapon.weapon_id, skin_id)
