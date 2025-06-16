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
const NOR_DRAG_RESISTANCE : float = 0.6
const PAGE_MARGIN : float = 35.0
@onready var tab_buttons : HBoxContainer = $MainContainer/TabButtonsContainer/TabButtons
@onready var tab_highlight : Button = $MainContainer/TabButtonsContainer/TabHighlight
@onready var tab_pages : Control = $MainContainer/TabPages
@onready var tab_buttons_container : Control = $MainContainer/TabButtonsContainer

var page_scenes := [
	preload("res://Scenes/tab_pages/tab_page1.tscn"),
	preload("res://Scenes/tab_pages/tab_page2.tscn"),
	preload("res://Scenes/tab_pages/tab_page3.tscn"),
	preload("res://Scenes/tab_pages/tab_page4.tscn"),
	preload("res://Scenes/tab_pages/tab_page5.tscn"),
]
var swipe_start_pos := Vector2.ZERO
var swipe_direction_locked : String = EMPTY
var is_dragging : bool = false
var page_width : float = 0
var current_page_index : int = 0
var next_page_index : int = 0
var current_scroll_container : Control
var swipe_threshold : float
var page_gap : float
var popup_window_opened : bool = false


func _ready():
	page_width = get_viewport_rect().size.x
	var page_height = get_viewport_rect().size.y
	var page_count = page_scenes.size()
	
	$MainContainer.size = Vector2((page_width + PAGE_MARGIN * 2) * page_count, page_height)
	tab_buttons_container.custom_minimum_size = Vector2(page_width, 100.0)
	swipe_threshold = page_width * 0.7
	page_gap = page_width + PAGE_MARGIN * 2
	
	_load_tab_pages()
	await get_tree().process_frame
	await get_tree().process_frame
	
	for i in range(tab_buttons.get_child_count()):
		var button = tab_buttons.get_child(i)
		button.pressed.connect(_on_tab_button_pressed.bind(i))
	
	current_page_index = page_count / 2
	next_page_index = current_page_index
	tab_pages.position.x = -current_page_index * page_gap
	
	for i in range(tab_buttons.get_child_count()):
		var btn = tab_buttons.get_child(i)
		btn.size_flags_stretch_ratio = DEFAULT_TAB_RATIO
		btn.add_theme_font_size_override("font_size", DEFAULT_TEXT_SIZE)
	
	var selected_btn = tab_buttons.get_child(current_page_index)
	selected_btn.size_flags_stretch_ratio = HIGHLIGHTED_TAB_RATIO
	selected_btn.add_theme_font_size_override("font_size", HIGHLIGHTED_TEXT_SIZE)
	await get_tree().process_frame
	await get_tree().process_frame
	tab_highlight.position.x = tab_buttons.get_child(current_page_index).position.x



func _input(event: InputEvent) -> void:
	if popup_window_opened:
		return
	
	current_scroll_container = tab_pages.get_child(current_page_index).get_node_or_null("ScrollContainer")
	
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
			else:
				offset_x *= NOR_DRAG_RESISTANCE
			
			var page_offset = -current_page_index * page_gap + offset_x
			tab_pages.position.x = page_offset
			
			if (current_page_index == 0 and offset_x < 0 or 
					(current_page_index == tab_pages.get_child_count() - 1) and offset_x > 0 or 
					current_page_index != 0 and (current_page_index != tab_pages.get_child_count() - 1)):
				var current_tab = tab_buttons.get_child(current_page_index)
				var next_index = current_page_index
				
				if offset_x < 0 and current_page_index < tab_buttons.get_child_count() - 1:
					next_index = current_page_index + 1
				elif offset_x > 0 and current_page_index > 0:
					next_index = current_page_index - 1
				
				var next_tab = tab_buttons.get_child(next_index)
				var progress = abs(offset_x) / page_width
				progress = clamp(progress, 0, 1)
				
				var start_pos = current_tab.position.x
				var end_pos = next_tab.position.x
				tab_highlight.position.x = lerp(start_pos, end_pos, progress)
			
			if current_scroll_container:
				current_scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			if current_scroll_container:
				current_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS


func _load_tab_pages() -> void:
	for i in range(page_scenes.size()):
		var page = page_scenes[i].instantiate()
		page.size = Vector2(page_width, get_viewport_rect().size.y)
		page.position = Vector2(i * (page_width + PAGE_MARGIN * 2), 0)
		tab_pages.add_child(page)


func snap_to_page(page_index: int) -> void:
	_animate_tab_icon(page_index)
	await get_tree().process_frame
	await get_tree().process_frame
	var page_target_x = -page_index * page_gap
	var highlight_target_x = tab_buttons.get_child(page_index).position.x
	
	get_tree().create_tween().tween_property(
			tab_pages, 
			"position:x", 
			page_target_x, 
			0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	get_tree().create_tween().tween_property(
			tab_highlight, 
			"position:x", 
			highlight_target_x, 
			0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	current_page_index = page_index


func _on_tab_button_pressed(target_index : int) -> void:
	if target_index == current_page_index:
		return
	
	snap_to_page(target_index)


func _animate_tab_icon(target_index : int) -> void: 
	var old_button : Button = tab_buttons.get_child(current_page_index)
	var new_button : Button = tab_buttons.get_child(target_index)
	
	old_button.size_flags_stretch_ratio = DEFAULT_TAB_RATIO
	new_button.size_flags_stretch_ratio = HIGHLIGHTED_TAB_RATIO
	
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
		0.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)



func open_popup_window() -> void:
	$PopupWindow.open_window()
	popup_window_opened = true
