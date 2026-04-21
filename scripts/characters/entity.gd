class_name Entity
extends CharacterBody2D


signal died
signal health_changed(current_health: int, max_health: int)

@export var max_health := 100
var death_effect: PackedScene = preload("res://effects/death_effect/death_effect.tscn")

@onready var sprite: Sprite2D = $Sprite2D

var health: int
var is_dead := false

var flash_tween: Tween
var scale_tween: Tween
var original_scale := Vector2.ONE

func _ready() -> void:
	health = max_health

	if sprite:
		original_scale = sprite.scale

		if sprite.material:
			sprite.material = sprite.material.duplicate()

	_emit_health_changed()

func get_death_effect_position() -> Vector2:
	return global_position

func should_queue_free_on_death() -> bool:
	return false

func face_direction(direction: Vector2) -> void:
	if sprite == null or is_zero_approx(direction.x):
		return

	sprite.flip_h = direction.x < 0

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health = max(health - amount, 0)
	_play_damage_feedback()
	_emit_health_changed()

	if health == 0:
		die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	_spawn_death_effect()
	_on_entity_died()
	died.emit()

	if should_queue_free_on_death():
		queue_free()

func _emit_health_changed() -> void:
	health_changed.emit(health, max_health)
	_on_health_changed()

func _on_health_changed() -> void:
	pass

func _on_entity_died() -> void:
	pass

func _spawn_death_effect() -> void:
	if death_effect == null or get_parent() == null:
		return

	var death_effect_scene := death_effect.instantiate() as Node2D
	if death_effect_scene == null:
		return

	death_effect_scene.global_position = get_death_effect_position()
	get_parent().add_child(death_effect_scene)

func _play_damage_feedback() -> void:
	if sprite == null:
		return

	if flash_tween:
		flash_tween.kill()

	if scale_tween:
		scale_tween.kill()

	if sprite.material:
		sprite.material.set_shader_parameter("flash_value", 1.0)

		flash_tween = create_tween()
		flash_tween.tween_method(
			func(value: float): sprite.material.set_shader_parameter("flash_value", value),
			1.0,
			0.0,
			0.2
		)

	_apply_hit_scale(sprite)

func _apply_hit_scale(target_sprite: Sprite2D) -> void:
	target_sprite.scale = original_scale * Vector2(1.25, 0.75)

	scale_tween = create_tween()
	scale_tween.tween_property(
		target_sprite,
		"scale",
		original_scale * Vector2(0.9, 1.1),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	scale_tween.tween_property(
		target_sprite,
		"scale",
		original_scale,
		0.12
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
