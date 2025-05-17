extends CanvasLayer

signal send_message(message, is_team_chat)

var is_team_chat := false
var chat_visible := true

func _ready():
    $Panel/VBoxContainer/ButtonTeamChat.pressed.connect(_on_team_chat_toggled)
    $Panel/VBoxContainer/HBoxContainer/ButtonSend.pressed.connect(_on_send_pressed)
    $Panel/VBoxContainer/HBoxContainer/LineEdit.text_submitted.connect(_on_text_submitted)
    $Panel/VBoxContainer/ButtonToggle.pressed.connect(_on_toggle_chat)

func add_message(message: String):
    $Panel/VBoxContainer/RichTextLabel.append_text(message + "\n")

func update_chat(message: String):
    add_message(message)

func _on_team_chat_toggled():
    is_team_chat = $Panel/VBoxContainer/ButtonTeamChat.button_pressed

func _on_send_pressed():
    var text = $Panel/VBoxContainer/HBoxContainer/LineEdit.text.strip_edges()
    if text != "":
        send_message.emit(text, is_team_chat)
        $Panel/VBoxContainer/HBoxContainer/LineEdit.text = ""

func _on_text_submitted(new_text):
    _on_send_pressed()

func _on_toggle_chat():
    chat_visible = !chat_visible
    $Panel.visible = chat_visible
    $Panel/VBoxContainer/ButtonToggle.text = "Показать чат" if !chat_visible else "Скрыть чат"
