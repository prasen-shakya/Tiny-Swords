extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if sprite == null:
		return

	position += Vector2(0, 4)
	rotation = randf_range(-0.18, 0.18)

	var start_scale := Vector2.ONE * randf_range(0.85, 1.05)
	sprite.scale = start_scale

	var start_modulate := sprite.modulate
	start_modulate.a = 0.95
	sprite.modulate = start_modulate

	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(sprite, "scale", start_scale * 1.6, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_property(self, "position:y", position.y - 12.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
