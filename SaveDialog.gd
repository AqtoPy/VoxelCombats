extends Panel

signal save_confirmed(file_name: String)

func show_dialog():
    show()
    $VBoxContainer/FileNameEdit.grab_focus()

func _on_save_pressed():
    var name = $VBoxContainer/FileNameEdit.text.strip_edges()
    if name.is_empty():
        $VBoxContainer/ErrorLabel.text = "Invalid file name!"
        return
    
    save_confirmed.emit(name)
    hide()

func _on_cancel_pressed():
    hide()
