var current_team: String = ""
var is_in_lobby: bool = true

func join_team(team: String):
    current_team = team
    is_in_lobby = false
    
    # Визуальное отображение команды
    if team == "blue":
        $TeamIndicator.material.albedo_color = Color.BLUE
    else:
        $TeamIndicator.material.albedo_color = Color.RED

func _input(event):
    if event.is_action_pressed("exit_to_lobby") and not is_in_lobby:
        show_escape_menu()

func show_escape_menu():
    var menu = preload("res://ui/EscapeMenu.tscn").instantiate()
    add_child(menu)
    menu.connect("exit_to_lobby", _on_exit_to_lobby)

func _on_exit_to_lobby():
    is_in_lobby = true
    current_team = ""
    get_tree().change_scene_to_file("res://ui/Lobby.tscn")
