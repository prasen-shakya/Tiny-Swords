extends CharacterBody2D

enum PlayerState {
	IDLE,
	RUN,
	ATTACK
}

@export var input_component: InputComponent
@export var movement_component: MovementComponent

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var attack_cooldown: Timer = $AttackCooldown

@export var game_ui: CanvasLayer
@onready var health_bar_ui: TextureProgressBar = game_ui.get_node("PlayerHealth/HealthBar")

var max_player_health := 100
var player_health := 100

signal died

var player_state: PlayerState = PlayerState.IDLE

var flash_tween: Tween
var scale_tween: Tween

var original_scale := Vector2.ONE

func _ready():
	anim_tree.active = true
	game_ui.visible = true

	original_scale = player_sprite.scale

	if player_sprite.material:
		player_sprite.material = player_sprite.material.duplicate()

func _physics_process(delta):
	input_component.update_input()

	if input_component.attack_pressed:
		take_damage(1)

		if player_state == PlayerState.ATTACK or not attack_cooldown.is_stopped():
			return

		enter_attack()
		return

	match player_state:
		PlayerState.IDLE:
			state_idle()
		PlayerState.RUN:
			state_run()
		PlayerState.ATTACK:
			state_attack()

func state_idle():
	velocity = Vector2.ZERO
	move_and_slide()

	anim_playback.travel("idle")

	if input_component.move_dir.length() > 0.1:
		player_state = PlayerState.RUN

func state_run():
	var dir := input_component.move_dir

	movement_component.apply_movement(dir)

	anim_playback.travel("run")

	if dir.x != 0:
		player_sprite.flip_h = dir.x < 0

	if dir.length() <= 0.1:
		player_state = PlayerState.IDLE

func state_attack():
	movement_component.stop()

func enter_attack():
	player_state = PlayerState.ATTACK

	player_sprite.flip_h = input_component.attack_dir.x < 0

	anim_tree.set(
		"parameters/attack/BlendSpace2D/blend_position",
		input_component.attack_dir
	)

	anim_playback.travel("attack")

func take_damage(damage):
	if player_sprite.material == null:
		return

	if flash_tween:
		flash_tween.kill()

	if scale_tween:
		scale_tween.kill()

	player_sprite.material.set_shader_parameter("flash_value", 1.0)

	flash_tween = create_tween()
	flash_tween.tween_method(
		func(v): player_sprite.material.set_shader_parameter("flash_value", v),
		1.0,
		0.0,
		0.2
	)

	apply_hit_scale()

	player_health -= damage

	var tween := create_tween()
	tween.tween_property(
		health_bar_ui,
		"value",
		player_health,
		0.3
	)

	if player_health <= 0:
		died.emit()

func apply_hit_scale():
	player_sprite.scale = original_scale * Vector2(1.25, 0.75)

	scale_tween = create_tween()

	scale_tween.tween_property(
		player_sprite,
		"scale",
		original_scale * Vector2(0.9, 1.1),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	scale_tween.tween_property(
		player_sprite,
		"scale",
		original_scale,
		0.12
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		player_state = PlayerState.IDLE
		attack_cooldown.start()
