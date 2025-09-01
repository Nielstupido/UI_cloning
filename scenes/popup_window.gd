extends Panel


@onready var content_container : PanelContainer = $MarginContainer/PanelContainer
@onready var close_button : Button = $MarginContainer/PanelContainer/VBoxContainer/Button
@onready var tween : Tween


func _ready():
	content_container.pivot_offset = size/2
	close_window()
	close_button.pressed.connect(close_window)


func open_window():
	self.visible = true
	content_container.scale = Vector2(0.8, 0.8)
	content_container.visible = true
		
	if tween:
		tween.kill()  
	
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(
					content_container, 
					"scale", 
					Vector2(1, 1), 
					0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func close_window():
	tween = create_tween()
	await tween.tween_property(
							content_container, 
							"scale", 
							Vector2(0, 0), 
							0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN).finished
	self.visible = false
	self.modulate.a = 0.0
	get_parent().popup_window_opened = false
