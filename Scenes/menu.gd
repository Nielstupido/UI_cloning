extends Control

const DEFAULT_TEXT_SIZE : int = 18
const HIGHLIGHTED_TEXT_SIZE : int = 30
const DEFAULT_TAB_RATIO : float = 1.0
const HIGHLIGHTED_TAB_RATIO : float = 1.5
@onready var tab_buttons : HBoxContainer = $TabButtons
@onready var tab_buttons_overlay : HBoxContainer = $TabButtonsOverlay
@onready var tab_buttons_highlight: Node = $TabButtonsOverlay/HighlightMark
@onready var pages_container : Control = $TabPages

var current_page :int = 0
var tween : Tween = null
var swipe_start_pos : Vector2
var swipe_threshold : float = 50.0 
var swipe_direction_locked = null
var direction_lock_threshold := 10


func _ready():
	# Hook up tab button signals
	for i in range(tab_buttons.get_child_count()):
		var button = tab_buttons.get_child(i)
		button.pressed.connect(_on_tab_button_pressed.bind(i))
	
	# Show only the first page at start
	for i in range(pages_container.get_child_count()):
		var page = pages_container.get_child(i)
		page.visible = (i == current_page)
	
	_on_tab_button_pressed(0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start_pos = event.position
			swipe_direction_locked = null  # Reset lock on new touch
		else:
			# On release
			if swipe_direction_locked == "horizontal":
				var delta = event.position - swipe_start_pos
				if abs(delta.x) > swipe_threshold:
					if delta.x < 0 and current_page < pages_container.get_child_count() - 1:
						_on_tab_button_pressed(current_page + 1)  # Swipe left
					elif delta.x > 0 and current_page > 0:
						_on_tab_button_pressed(current_page - 1)  # Swipe right
	
	elif event is InputEventScreenDrag:
		if swipe_direction_locked == null:
			var delta = event.position - swipe_start_pos
			if abs(delta.x) > direction_lock_threshold or abs(delta.y) > direction_lock_threshold:
				swipe_direction_locked = "horizontal" if abs(delta.x) > abs(delta.y) else "vertical"
		
		if swipe_direction_locked == "horizontal":
			# Handle horizontal swipe animation preview here...
			pass
		elif swipe_direction_locked == "vertical":
			pass


func _on_tab_button_pressed(target_index : int) -> void:
	_animate_tab_icon(target_index)
	tab_buttons.get_child(current_page).size_flags_stretch_ratio = DEFAULT_TAB_RATIO
	tab_buttons.get_child(target_index).size_flags_stretch_ratio = HIGHLIGHTED_TAB_RATIO
	tab_buttons_overlay.move_child(tab_buttons_highlight, target_index)
	
	if target_index == current_page:
		return
	
	var direction = 1 if target_index > current_page else -1
	
	var old_page = pages_container.get_child(current_page)
	var new_page = pages_container.get_child(target_index)
	
	new_page.visible = true
	new_page.position.x = direction * pages_container.size.x
	old_page.position.x = 0
	
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(old_page, "position:x", -direction * pages_container.size.x, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(new_page, "position:x", 0, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_tab_animation_finished").bind(old_page))
	current_page = target_index


func _on_tab_animation_finished(old_page : Node) -> void:
	old_page.visible = false
	old_page.position.x = 0 


func _animate_tab_icon(target_index : int) -> void:
	var old_button : Button = tab_buttons.get_child(current_page)
	var new_button : Button = tab_buttons.get_child(target_index)
	
	if target_index != current_page:
		get_tree().create_tween().tween_method(
			func(value):
				old_button.add_theme_font_size_override("font_size", round(value)),
			HIGHLIGHTED_TEXT_SIZE,
			DEFAULT_TEXT_SIZE,
			0.2
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	get_tree().create_tween().tween_method(
		func(value):
			new_button.add_theme_font_size_override("font_size", round(value)),
		DEFAULT_TEXT_SIZE,
		HIGHLIGHTED_TEXT_SIZE,
		0.3
	).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
