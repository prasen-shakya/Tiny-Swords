extends CanvasLayer

@onready var round_label: Label = $MarginContainer/VBoxContainer/RoundLabel
@onready var enemies_left_label: Label = $MarginContainer/VBoxContainer/EnemiesLeftLabel

func set_round(round_number: int) -> void:
	round_label.text = "Round: %d" % round_number
	
func set_enemies_left(count: int) -> void:
	enemies_left_label.text = "Enemies Left: %d" % count
