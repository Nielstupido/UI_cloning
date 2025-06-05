extends Control

const HORIZONTAL : String = "horizontal"
const VERTICAL : String = "vertical"
const EMPTY : String = ""
const DEFAULT_TEXT_SIZE : int = 18
const HIGHLIGHTED_TEXT_SIZE : int = 30
const DEFAULT_TAB_RATIO : float = 1.0
const HIGHLIGHTED_TAB_RATIO : float = 1.5
const DIRECTION_BIAS : int = 5
const DIRECTION_LOCK_THRESHOLD : int = 10
const DRAG_RESISTANCE : float = 0.35
@onready var tab_buttons : HBoxContainer = $MainContainer/TabButtonsContainer/TabButtons
@onready var tab_buttons_overlay : HBoxContainer = $MainContainer/TabButtonsContainer/TabButtonsOverlay
@onready var tab_buttons_highlight: Node = $MainContainer/TabButtonsContainer/TabButtonsOverlay/HighlightMark
@onready var tab_pages : Control = $MainContainer/TabPages
@onready var tab_buttons_container : PanelContainer = $MainContainer/TabButtonsContainer

var swipe_start_pos := Vector2.ZERO
var swipe_direction_locked : String = EMPTY
var is_dragging : bool = false
var page_width : float = 0
var current_page_index : int = 0
var next_page_index : int = 0
var tween : Tween
var current_scroll_container : Control
var swipe_threshold : float


func _ready():
	var page_width = get_viewport_rect().size.x
	var page_height = get_viewport_rect().size.y
	var page_count = tab_pages.get_child_count()
	$MainContainer.size = Vector2(page_width * page_count, page_height)
	tab_buttons_container.custom_minimum_size = Vector2(page_width, 100.0)
	swipe_threshold = get_viewport_rect().size.x * 0.5
	
	for i in range(page_count):
		var page = tab_pages.get_child(i)
		page.size = Vector2(page_width, page_height)
		page.position = Vector2(i * page_width, 0)
	
	# Hook up tab button signals
	for i in range(tab_buttons.get_child_count()):
		var button = tab_buttons.get_child(i)
		button.pressed.connect(_on_tab_button_pressed.bind(i))
	
	_on_tab_button_pressed(0)


func _input(event: InputEvent) -> void:
	current_scroll_container = tab_pages.get_child(current_page_index).get_node("ScrollContainer")
	
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start_pos = event.position
			swipe_direction_locked = EMPTY
			is_dragging = true
			page_width = get_viewport_rect().size.x
		else:
			is_dragging = false
			if swipe_direction_locked == HORIZONTAL:
				var delta = event.position - swipe_start_pos
				var swipe_amount = delta.x
				next_page_index = current_page_index
				
				if abs(swipe_amount) > swipe_threshold:
					if swipe_amount < 0 and current_page_index < tab_pages.get_child_count() - 1:
						next_page_index = current_page_index + 1
					elif swipe_amount > 0 and current_page_index > 0:
						next_page_index = current_page_index - 1
				
				snap_to_page(next_page_index)
	
	elif event is InputEventScreenDrag and is_dragging:
		var delta = event.position - swipe_start_pos
		if swipe_direction_locked == EMPTY:
			if abs(delta.x) > DIRECTION_LOCK_THRESHOLD or abs(delta.y) > DIRECTION_LOCK_THRESHOLD:
				if abs(delta.x) > DIRECTION_BIAS * abs(delta.y):
					swipe_direction_locked = HORIZONTAL
				elif abs(delta.y) > DIRECTION_BIAS * abs(delta.x):
					swipe_direction_locked = VERTICAL
		
		if swipe_direction_locked == HORIZONTAL:
			var offset_x = delta.x
			
			if ((current_page_index == 0 and offset_x > 0) or 
					((current_page_index == tab_pages.get_child_count() - 1) and offset_x < 0)):
				offset_x *= DRAG_RESISTANCE 
			
			var offset = -current_page_index * page_width + offset_x
			tab_pages.position.x = offset
			current_scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			current_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS


func snap_to_page(page_index: int) -> void:
	var target_x = -page_index * page_width
	_animate_tab_icon(page_index)
	_animate_tab_highlight(page_index)
	
	if tween:
		tween.kill()
	
	tween = get_tree().create_tween()
	tween.tween_property(tab_pages, "position:x", target_x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_page_index = page_index


func _on_tab_button_pressed(target_index : int) -> void:
	if target_index == current_page_index:
		return
	
	snap_to_page(target_index)


func _on_tab_animation_finished(old_page : Node) -> void:
	old_page.visible = false
	old_page.position.x = 0 


func _animate_tab_highlight(target_index) -> void:
	tab_buttons.get_child(current_page_index).size_flags_stretch_ratio = DEFAULT_TAB_RATIO
	tab_buttons.get_child(target_index).size_flags_stretch_ratio = HIGHLIGHTED_TAB_RATIO
	tab_buttons_overlay.move_child(tab_buttons_highlight, target_index)


func _animate_tab_icon(target_index : int) -> void:
	var old_button : Button = tab_buttons.get_child(current_page_index)
	var new_button : Button = tab_buttons.get_child(target_index)
	
	if target_index != current_page_index:
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
