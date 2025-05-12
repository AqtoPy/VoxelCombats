extends Control

signal exit_to_lobby

func _ready():
    $ExitButton.grab_focus()

func _on_exit_button_pressed():
    exit_to_lobby.emit()
