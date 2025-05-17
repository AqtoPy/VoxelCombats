extends CanvasLayer

signal team_selected(team)

func set_teams(teams_data):
    $Panel/MarginContainer/VBoxContainer/ButtonRed.modulate = teams_data.RED.color
    $Panel/MarginContainer/VBoxContainer/ButtonBlue.modulate = teams_data.BLUE.color

func _on_ButtonRed_pressed():
    team_selected.emit("Red")
    queue_free()

func _on_ButtonBlue_pressed():
    team_selected.emit("Blue")
    queue_free()

func _on_ButtonSpectator_pressed():
    team_selected.emit("Spectator")
    queue_free()
