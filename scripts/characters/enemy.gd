class_name Enemy
extends Entity

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var hitbox_area: Area2D = $HitboxArea
@onready var hitbox_shape: CollisionShape2D = $HitboxArea/HitboxShape

var is_attacking := false
var base_hitbox_position := Vector2.ZERO

func _ready() -> void:
	super._ready()
	anim_tree.active = true
	base_hitbox_position = hitbox_shape.position
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if player == null or is_dead or is_spawning:
		return

	var to_player := player.global_position - global_position
	_update_facing(to_player.x)

	if is_attacking:
		return

	if _is_player_in_attack_range() and attack_cooldown.is_stopped():
		is_attacking = true
		anim_playback.travel("attack")
	else:
		anim_playback.travel("idle")

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack"):
		is_attacking = false
		attack_cooldown.start()

func _on_hitbox_area_area_entered(area: Area2D) -> void:
	var entity: Entity = area.owner
	if entity == null or entity == self:
		return

	entity.take_damage(attack_damage)

func should_queue_free_on_death() -> bool:
	return true

func _update_facing(direction_x: float) -> void:
	if is_zero_approx(direction_x):
		return

	var facing_left := direction_x < 0
	sprite.flip_h = facing_left
	hitbox_shape.position.x = -abs(base_hitbox_position.x) if facing_left else abs(base_hitbox_position.x)

func _is_player_in_attack_range() -> bool:
	if hitbox_shape.shape == null:
		return false

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox_shape.shape
	query.transform = hitbox_shape.global_transform
	query.collision_mask = hitbox_area.collision_mask
	query.collide_with_areas = true
	query.exclude = [self]

	for result in get_world_2d().direct_space_state.intersect_shape(query):
		var collider := result.get("collider") as Area2D
		if collider == null:
			continue

		if collider.owner == player:
			return true

	return false
