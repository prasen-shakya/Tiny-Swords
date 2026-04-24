extends Node2D

@export var speed := 320.0
@export var fade_duration := 0.2
@export var max_travel_distance := 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox_area: Area2D = $HurtboxArea
@onready var hurtbox_shape: CollisionShape2D = $HurtboxArea/HurtboxShape

var fly_direction := Vector2.RIGHT
var spawn_position := Vector2.ZERO
var damage: int = 0
var is_exploding := false
var is_fading_out := false

func _ready() -> void:
	spawn_position = global_position

func fly(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return

	spawn_position = global_position
	fly_direction = direction.normalized()

func _physics_process(delta: float) -> void:
	if is_exploding or is_fading_out:
		return

	global_position += fly_direction * speed * delta

	if global_position.distance_squared_to(spawn_position) >= max_travel_distance * max_travel_distance:
		fade_away()

func explode() -> void:
	if is_exploding or is_fading_out:
		return

	is_exploding = true
	_disable_hitbox()
	animated_sprite.play("explosion")

func fade_away() -> void:
	if is_exploding or is_fading_out:
		return

	is_fading_out = true
	_disable_hitbox()

	var fade_tween := create_tween()
	fade_tween.tween_property(animated_sprite, "modulate:a", 0.0, fade_duration)
	fade_tween.finished.connect(queue_free)

func _on_hurtbox_area_area_entered(area: Area2D) -> void:
	if area.owner == self:
		return
	
	area.owner.take_damage(damage)
	explode()

func _on_hurtbox_area_body_entered(_body: Node2D) -> void:
	explode()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "explosion":
		queue_free()

func _disable_hitbox() -> void:
	hurtbox_area.set_deferred("monitoring" , false)
	hurtbox_area.set_deferred("monitorable" , false)
	hurtbox_shape.set_deferred("disabled", true)
