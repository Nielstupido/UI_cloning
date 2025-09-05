extends Panel


@onready var content_container : PanelContainer = $PanelContainer
@onready var close_button : Button = $PanelContainer/VBoxContainer/Button


func _ready():
	content_container.anchor_left = 0.5
	content_container.anchor_top = 0.5
	content_container.anchor_right = 0.5
	content_container.anchor_bottom = 0.5
	content_container.set_anchors_preset(Control.PRESET_CENTER)
	content_container.pivot_offset = size/2
	content_container.scale = Vector2(0.5, 0.5)
	close_window()
	close_button.pressed.connect(close_window)


func open_window():
	self.visible = true
	content_container.visible = true
	content_container.scale = Vector2.ZERO

	var tween = get_tree().create_tween()
	tween.tween_property(
		content_container,
		"scale",
		Vector2(1, 1),
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)


func close_window():
	var tween = get_tree().create_tween()
	tween.tween_property(
		content_container,
		"scale",
		Vector2(0, 0),
		0.2
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		self.visible = false
		get_parent().popup_window_opened = false
	)
