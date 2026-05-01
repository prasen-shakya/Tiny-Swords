extends Control

signal start_game_pressed(origin: String)
signal exit_pressed(origin: String)

func _on_start_game_pressed() -> void:
	start_game_pressed.emit("main_menu")


func _on_quit_game_pressed() -> void:
	exit_pressed.emit("main_menu")
