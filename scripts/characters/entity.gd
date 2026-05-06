class_name Entity
extends CharacterBody2D

const SPAWN_START_OFFSET := Vector2(0, 8)
const SPAWN_START_SCALE := Vector2(0.38, 1.52)
const SPAWN_PEAK_SCALE := Vector2(1.06, 0.9)
const SPAWN_START_ALPHA := 0.6
const DAMAGE_FLASH_DURATION := 0.2
const SPAWN_FLASH_KEYFRAMES := [
	{ "from": 1.0, "to": 0.55, "duration": 0.1 },
	{ "from": 0.55, "to": 1.0, "duration": 0.06 },
	{ "from": 1.0, "to": 0.0, "duration": 0.5 },
]

signal died
signal health_changed(current_health: int, max_health: int)

# Entity Stats
@export var max_health := 100
@export var attack_damage: int = 2

var death_effect: PackedScene = preload("res://effects/death_effect/death_effect.tscn")
var smoke_effect: PackedScene = preload("res://effects/smoke_effect/smoke_effect.tscn")
var heal_effect: PackedScene = preload("res://effects/heal_effect/heal_effect.tscn")
var flash_shader = preload("res://shaders/flash.gdshader")

@onready var sprite: Sprite2D = $Sprite2D

var health: int
var is_dead := false
var is_spawning := true
var facing_position_nodes: Array[Dictionary] = []
var facing_scale_nodes: Array[Dictionary] = []


var flash_tween: Tween
var scale_tween: Tween
var spawn_position_tween: Tween
var spawn_scale_tween: Tween
var original_scale := Vector2.ONE
var original_sprite_position := Vector2.ZERO
var original_modulate := Color.WHITE

func _ready() -> void:
	health = max_health

	if sprite:
		original_scale = sprite.scale
		original_sprite_position = sprite.position
		original_modulate = sprite.modulate

		_setup_sprite_material()
		_cache_facing_nodes()

	_emit_health_changed()

	await get_tree().process_frame

	_start_spawn_effect()

func get_death_effect_position() -> Vector2:
	return global_position

func should_queue_free_on_death() -> bool:
	return false

func face_direction(direction: Vector2) -> void:
	if sprite == null or is_zero_approx(direction.x):
		return

	var facing_left := direction.x < 0
	sprite.flip_h = facing_left
	_apply_facing_nodes(facing_left)

func _get_facing_position_nodes() -> Array[Node2D]:
	return []

func _get_facing_scale_nodes() -> Array[Node2D]:
	return []

func _cache_facing_nodes() -> void:
	facing_position_nodes.clear()
	facing_scale_nodes.clear()

	for node in _get_facing_position_nodes():
		if node:
			facing_position_nodes.append({
				"node": node,
				"position": node.position,
			})

	for node in _get_facing_scale_nodes():
		if node:
			facing_scale_nodes.append({
				"node": node,
				"scale": node.scale,
			})

func _apply_facing_nodes(facing_left: bool) -> void:
	for entry in facing_position_nodes:
		var node: Node2D = entry["node"]
		var base_position: Vector2 = entry["position"]
		node.position.x = -abs(base_position.x) if facing_left else abs(base_position.x)

	for entry in facing_scale_nodes:
		var node: Node2D = entry["node"]
		var base_scale: Vector2 = entry["scale"]
		node.scale.x = -abs(base_scale.x) if facing_left else abs(base_scale.x)

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health = max(health - amount, 0)
	_play_damage_feedback()
	_emit_health_changed()

	if health == 0:
		die()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	
	_emit_health_changed()
	_spawn_heal_effect()

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

func _spawn_heal_effect() -> void:
	if heal_effect == null or get_parent() == null:
		return

	var heal_effect_scene := heal_effect.instantiate() as Node2D
	if heal_effect_scene == null:
		return

	heal_effect_scene.position = Vector2(0, 0)
	add_child(heal_effect_scene)

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
		_play_flash([{ "from": 1.0, "to": 0.0, "duration": DAMAGE_FLASH_DURATION }])

	_apply_hit_scale(sprite)

func _start_spawn_effect() -> void:
	var smoke = smoke_effect.instantiate()
	smoke.global_position = global_position
	get_parent().add_child(smoke)
	
	_play_spawn_effect()
	
	await smoke.tree_exited
	is_spawning = false
	
	

func _play_spawn_effect() -> void:
	if sprite == null:
		return

	if flash_tween:
		flash_tween.kill()

	if scale_tween:
		scale_tween.kill()

	if spawn_position_tween:
		spawn_position_tween.kill()

	if spawn_scale_tween:
		spawn_scale_tween.kill()

	sprite.visible = true
	sprite.position = original_sprite_position + SPAWN_START_OFFSET
	sprite.scale = original_scale * SPAWN_START_SCALE

	var spawn_modulate := original_modulate
	spawn_modulate.a = min(original_modulate.a, SPAWN_START_ALPHA)
	sprite.modulate = spawn_modulate

	if sprite.material:
		_play_flash(SPAWN_FLASH_KEYFRAMES)

	spawn_position_tween = create_tween()
	spawn_position_tween.tween_property(
		sprite,
		"position",
		original_sprite_position,
		0.26
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	spawn_scale_tween = create_tween()
	spawn_scale_tween.tween_property(
		sprite,
		"scale",
		original_scale * SPAWN_PEAK_SCALE,
		0.14
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	spawn_scale_tween.tween_property(
		sprite,
		"scale",
		original_scale,
		0.14
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var alpha_tween := create_tween()
	alpha_tween.tween_property(sprite, "modulate:a", original_modulate.a, 0.28)

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

func _setup_sprite_material() -> void:
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	else:
		var shader_material := ShaderMaterial.new()
		shader_material.shader = flash_shader
		shader_material.set_shader_parameter("flash_color", Color.WHITE)
		shader_material.set_shader_parameter("flash_value", 0.0)
		sprite.material = shader_material

func _play_flash(keyframes: Array) -> void:
	sprite.material.set_shader_parameter("flash_value", keyframes[0]["from"])

	flash_tween = create_tween()
	for keyframe in keyframes:
		flash_tween.tween_method(
			func(value: float): sprite.material.set_shader_parameter("flash_value", value),
			keyframe["from"],
			keyframe["to"],
			keyframe["duration"]
		)
