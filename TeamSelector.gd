extends Control

signal team_selected(team_name)
signal back_to_lobby

@onready var map_preview = $MapPreview
@onready var blue_team_button = $BlueTeam/JoinButton
@onready var red_team_button = $RedTeam/JoinButton

func setup(map_name: String, mode_settings: Dictionary):
    # Загружаем превью карты
    map_preview.texture = load("res://maps/previews/%s.png" % map_name)
    
    if not mode_settings["teams"]:
        # Для режима без команд скрываем выбор
        $BlueTeam.visible = false
        $RedTeam.visible = false
        $FreeRoamLabel.visible = true

func _on_blue_team_pressed():
    team_selected.emit("blue")
    queue_free()

func _on_red_team_pressed():
    team_selected.emit("red")
    queue_free()

func _on_back_button_pressed():
    back_to_lobby.emit()
    queue_free()
