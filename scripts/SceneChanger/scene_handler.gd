extends Node

@export var main_menu_packed: PackedScene
@export var game_scene_packed: PackedScene
@export var game_over_scene_packed: PackedScene
@export var fade_duration := 0.45

var current_game_scene: Node = null
var current_game_over_scene: Node = null
var is_transitioning := false

@onready var fade_layer := CanvasLayer.new()
@onready var fade_rect := ColorRect.new()

func _ready() -> void:
	_setup_fade_overlay()
	load_main_menu("game_start")
	
	
func load_main_menu(_origin: String) -> void:
	if _origin == "end_game_screen" and current_game_over_scene:
		current_game_over_scene.queue_free()
		current_game_scene = null
	var main_menu: Control = main_menu_packed.instantiate()
	main_menu.start_game_pressed.connect(start_game)
	main_menu.exit_pressed.connect(exit_game)
	add_child(main_menu)
	
func start_game(_origin: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	await _fade_to_black()
	
	if _origin == "main_menu":
		get_node("MainMenu").queue_free()
	if _origin == "end_game_screen" and current_game_over_scene:
		current_game_over_scene.queue_free()
		current_game_over_scene = null
		await get_tree().process_frame
		
	current_game_scene = game_scene_packed.instantiate()
	add_child(current_game_scene)
	
	var round_manager = current_game_scene.get_node("RoundManager")
	round_manager.game_lost.connect(_on_game_lost)
	
	await _fade_from_black()
	is_transitioning = false
	
func exit_game(_origin: String) -> void:
	get_tree().quit()

func _on_game_lost()-> void:
	await get_tree().create_timer(1.5).timeout
	if is_transitioning:
		return
	is_transitioning = true
	await _fade_to_black()
	
	if current_game_scene:
		current_game_scene.queue_free()
		current_game_scene = null
	current_game_over_scene = game_over_scene_packed.instantiate()
	add_child(current_game_over_scene)
	
	current_game_over_scene.retry_pressed.connect(_on_retry_pressed)
	current_game_over_scene.main_menu_pressed.connect(_on_main_menu_pressed)
	
	await _fade_from_black()
	is_transitioning = false
	
func _on_retry_pressed() -> void:
	start_game("end_game_screen")
	
func _on_main_menu_pressed() -> void:
	load_main_menu("end_game_screen")

func _setup_fade_overlay() -> void:
	fade_layer.layer = 100
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.visible = false
	add_child(fade_layer)
	fade_layer.add_child(fade_rect)

func _fade_to_black() -> void:
	fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished

func _fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
	fade_rect.visible = false
