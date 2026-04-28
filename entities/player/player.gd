extends "res://scripts/characters/entity.gd"

signal player_died

enum PlayerState {
	IDLE,
	RUN,
	ATTACK
}

@export var input_component: InputComponent
@export var movement_component: MovementComponent

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var hitbox_shape: CollisionPolygon2D = $HitboxArea/HitboxShape

@export var game_ui: CanvasLayer
@onready var health_bar_ui: TextureProgressBar = game_ui.get_node("PlayerHealth/HealthBar")

var player_state: PlayerState = PlayerState.IDLE
var health_bar_tween: Tween

func _ready() -> void:
	super._ready()

	anim_tree.active = true
	game_ui.visible = true
	health_bar_ui.max_value = max_health
	health_bar_ui.value = health
	add_to_group("player")
	

func _physics_process(_delta: float) -> void:
	if is_dead or is_spawning:
		return
		
	input_component.update_input()
	
	if input_component.attack_pressed:
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
	face_direction(dir)

	if dir.length() <= 0.1:
		player_state = PlayerState.IDLE

func state_attack():
	movement_component.stop()

func enter_attack():
	player_state = PlayerState.ATTACK
	anim_playback.travel("attack")

func _on_health_changed() -> void:
	if health_bar_ui == null:
		return

	var target_value := float(health)
	var delta_value := absf(health_bar_ui.value - target_value)

	if is_zero_approx(delta_value):
		health_bar_ui.value = target_value
		return

	if health_bar_tween:
		health_bar_tween.kill()

	health_bar_tween = create_tween()
	health_bar_tween.set_trans(Tween.TRANS_SINE)
	health_bar_tween.set_ease(Tween.EASE_OUT)
	health_bar_tween.tween_property(
		health_bar_ui,
		"value",
		target_value,
		clampf(delta_value * 0.03, 0.12, 0.5)
	)

func _on_entity_died() -> void:
	player_died.emit()
	sprite.visible = false

func _get_facing_scale_nodes() -> Array[Node2D]:
	var nodes: Array[Node2D] = [hitbox_shape]
	return nodes

func get_death_effect_position() -> Vector2:
	return global_position + Vector2(0, -32)

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		player_state = PlayerState.IDLE
		attack_cooldown.start()


func _on_hitbox_area_area_entered(area: Area2D) -> void:
	var entity: Entity = area.owner
	
	entity.take_damage(attack_damage)
