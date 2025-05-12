# В MainMenu.gd
var game_modes = {
    "FreeRoam": {
        "teams": false,
        "time_limit": 0,
        "description": "Свободное передвижение по карте"
    },
    "TeamDeathmatch": {
        "teams": true,
        "time_limit": 600,
        "description": "Командный бой до 50 убийств"
    }
}

func _on_create_server_pressed():
    var selected_mode = $ServerMenu/ModeOption.get_selected_id()
    current_server_info["mode"] = game_modes.keys()[selected_mode]
    # ... остальной код создания сервера
