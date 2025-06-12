extends PanelContainer


@onready var open_popup_button : Button = $VBoxContainer/Button


func _ready():
	open_popup_button.pressed.connect(_open_popup)


func _open_popup() -> void:
	get_parent().get_parent().get_parent().open_popup_window()
