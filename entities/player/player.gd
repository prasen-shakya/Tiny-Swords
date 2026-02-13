## A player orchestrator script

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

var player_state: PlayerState = PlayerState.IDLE

func _ready():
	# We need to activate the animation tree because it is disabled in the editor
	anim_tree.active = true

func _physics_process(delta):
	input_component.update_input()
	
	if input_component.attack_pressed:
		# If we're not allowed to attack, don't 
		if player_state == PlayerState.ATTACK or not attack_cooldown.is_stopped():
			return
		
		enter_attack()
		return

	# ----- STATE MACHINE -----
	match player_state:
		PlayerState.IDLE:
			state_idle()
		PlayerState.RUN:
			state_run()
		PlayerState.ATTACK:
			state_attack()

# ---------------- STATES ----------------
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


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		player_state = PlayerState.IDLE
		attack_cooldown.start()
