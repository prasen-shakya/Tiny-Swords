extends Node

@export var main_menu_packed: PackedScene
@export var game_scene_packed: PackedScene
@export var game_over_scene_packed: PackedScene

var current_game_scene: Node = null
var current_game_over_scene: Node = null

func _ready() -> void:
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
	
func exit_game(_origin: String) -> void:
	get_tree().quit()

func _on_game_lost()-> void:
	await get_tree().create_timer(1.5).timeout
	if current_game_scene:
		current_game_scene.queue_free()
		current_game_scene = null
	current_game_over_scene = game_over_scene_packed.instantiate()
	add_child(current_game_over_scene)
	
	current_game_over_scene.retry_pressed.connect(_on_retry_pressed)
	current_game_over_scene.main_menu_pressed.connect(_on_main_menu_pressed)
	
func _on_retry_pressed() -> void:
	start_game("end_game_screen")
	
func _on_main_menu_pressed() -> void:
	load_main_menu("end_game_screen")
