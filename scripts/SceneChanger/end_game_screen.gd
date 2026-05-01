extends Control

signal retry_pressed
signal main_menu_pressed



func _on_replay_pressed() -> void:
	retry_pressed.emit()


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()
