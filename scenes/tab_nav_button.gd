extends Button

@onready var tab_icon: TextureRect = $Icon
@onready var tab_label: Label = $Label

var highlighted_icon_offset : float = 20.0
var default_scale: float = 0.5
var enlarged_scale: float = 0.6
var label_margin: float = 50.0
var default_pos_y: float = 0.0


func _ready():
	tab_icon.anchor_left = 0.5
	tab_icon.anchor_top = 0.5
	tab_icon.anchor_right = 0.5
	tab_icon.anchor_bottom = 0.5
	tab_icon.set_anchors_preset(Control.PRESET_CENTER)
	tab_icon.pivot_offset = tab_icon.texture.get_size() / 2
	tab_icon.scale = Vector2(default_scale, default_scale)
	
	tab_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tab_label.custom_minimum_size.x = tab_icon.texture.get_size().x
	tab_label.visible = false
	tab_label.modulate.a = 0.0
	_update_label_position()
	default_pos_y = tab_icon.position.y


func set_selected(selected: bool):
	if selected:
		get_tree().create_tween().tween_property(
			tab_icon, "scale", Vector2(enlarged_scale, enlarged_scale), 0.3
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		get_tree().create_tween().tween_property(
			tab_icon, "position:y", default_pos_y - highlighted_icon_offset, 0.3
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		tab_label.visible = true
		get_tree().create_tween().tween_property(
			tab_label, "modulate:a", 1.0, 0.25
		)
	
	else:
		get_tree().create_tween().tween_property(
			tab_icon, "scale", Vector2(default_scale, default_scale), 0.3
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		get_tree().create_tween().tween_property(
			tab_icon, "position:y", tab_icon.position.y + highlighted_icon_offset, 0.3
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		var t = get_tree().create_tween()
		t.tween_property(tab_label, "modulate:a", 0.0, 0.05)
		t.finished.connect(func(): tab_label.visible = false)
	
	_update_label_position()


func _update_label_position():
	var icon_size = tab_icon.texture.get_size() * tab_icon.scale
	tab_label.position = tab_icon.position + Vector2(0, icon_size.y + tab_label.size.y)
