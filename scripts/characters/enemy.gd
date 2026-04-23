class_name Enemy
extends Entity

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var attack_cooldown: Timer = $AttackCooldown

@onready var hitbox_area: Area2D = $HitboxArea
@onready var hitbox_shape: CollisionShape2D = $HitboxArea/HitboxShape
@onready var attack_range_area: Area2D = $AttackRangeArea
@onready var attack_range_shape: CollisionShape2D = $AttackRangeArea/AttackRangeShape

var is_attacking := false
var player_in_attack_range := false
var base_attack_range_position := Vector2.ZERO
var base_hitbox_position := Vector2.ZERO

func _ready() -> void:
	super._ready()
	anim_tree.active = true
	
	base_attack_range_position = attack_range_shape.position
	
	if hitbox_area:
		base_hitbox_position = hitbox_shape.position
	
	_sync_attack_range_state()
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
	if player == null or is_dead or is_spawning:
		return

	var to_player := player.global_position - global_position
	_update_facing(to_player.x)

	if is_attacking:
		return

	if player_in_attack_range and attack_cooldown.is_stopped():
		is_attacking = true
		attack()
	else:
		anim_playback.travel("idle")

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		is_attacking = false
		attack_cooldown.start()

func attack() -> void:
	anim_playback.travel("attack")

func _on_hitbox_area_area_entered(area: Area2D) -> void:
	var entity: Entity = area.owner

	entity.take_damage(attack_damage)

func _on_attack_range_area_area_entered(area: Area2D) -> void:
	if area.owner == player:
		player_in_attack_range = true

func _on_attack_range_area_area_exited(area: Area2D) -> void:
	if area.owner == player:
		player_in_attack_range = false

func should_queue_free_on_death() -> bool:
	return true

func _update_facing(direction_x: float) -> void:
	if is_zero_approx(direction_x):
		return

	var facing_left := direction_x < 0
	sprite.flip_h = facing_left
	attack_range_shape.position.x = -abs(base_attack_range_position.x) if facing_left else abs(base_attack_range_position.x)
	
	if hitbox_area:
		hitbox_shape.position.x = -abs(base_hitbox_position.x) if facing_left else abs(base_hitbox_position.x)

# This function handles the edge case where already inside AttackRangeArea when the enemy becomes ready
func _sync_attack_range_state() -> void:
	player_in_attack_range = false
	for area in attack_range_area.get_overlapping_areas():
		if area.owner == player:
			player_in_attack_range = true
			return
