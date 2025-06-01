extends Control

const EMPTY : String = ""
const DEFAULT_TEXT_SIZE : int = 18
const HIGHLIGHTED_TEXT_SIZE : int = 30
const DEFAULT_TAB_RATIO : float = 1.0
const HIGHLIGHTED_TAB_RATIO : float = 1.5
@onready var tab_buttons : HBoxContainer = $TabButtons
@onready var tab_buttons_overlay : HBoxContainer = $TabButtonsOverlay
@onready var tab_buttons_highlight: Node = $TabButtonsOverlay/HighlightMark
@onready var pages_container : Control = $TabPages

var swipe_start_pos := Vector2.ZERO
var swipe_direction_locked : String = EMPTY
var is_dragging : bool = false
var page_width : float = 0
var current_page : int = 0
var swipe_threshold : int = 50  # Minimum swipe distance to trigger page change
var direction_lock_threshold : int = 10  # Minimum movement to lock direction
var tween : Tween


func _ready():
	var page_width = get_viewport_rect().size.x
	var page_height = get_viewport_rect().size.y
	var page_count = pages_container.get_child_count()
	pages_container.size = Vector2(page_width * page_count, page_height)
	
	for i in range(page_count):
		var page = pages_container.get_child(i)
		page.size = Vector2(page_width, page_height)
		page.position = Vector2(i * page_width, 0)
	
	# Hook up tab button signals
	for i in range(tab_buttons.get_child_count()):
		var button = tab_buttons.get_child(i)
		button.pressed.connect(_on_tab_button_pressed.bind(i))
	
	_on_tab_button_pressed(0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start_pos = event.position
			swipe_direction_locked = EMPTY
			is_dragging = true
			page_width = get_viewport_rect().size.x
		else:
			is_dragging = false
			if swipe_direction_locked == "horizontal":
				var delta = event.position - swipe_start_pos
				var swipe_amount = delta.x
				
				if abs(swipe_amount) > swipe_threshold:
					if swipe_amount < 0 and current_page < pages_container.get_child_count() - 1:
						current_page += 1
					elif swipe_amount > 0 and current_page > 0:
						current_page -= 1
				
				snap_to_page(current_page)
	
	elif event is InputEventScreenDrag and is_dragging:
		var delta = event.position - swipe_start_pos
	
		if swipe_direction_locked == EMPTY:
			if abs(delta.x) > direction_lock_threshold or abs(delta.y) > direction_lock_threshold:
				var direction_bias = 1.5
				if abs(delta.x) > direction_bias * abs(delta.y):
					swipe_direction_locked = "horizontal"
				elif abs(delta.y) > direction_bias * abs(delta.x):
					swipe_direction_locked = "vertical"
	
		if swipe_direction_locked == "horizontal":
			var offset = -current_page * page_width + delta.x
			pages_container.position.x = offset


func snap_to_page(page_index: int) -> void:
	var target_x = -page_index * page_width
	if tween:
		tween.kill()
	
	tween = get_tree().create_tween()
	tween.tween_property(pages_container, "position:x", target_x, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
	
	if tween:
		tween.kill()
	
	tween = get_tree().create_tween()
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
