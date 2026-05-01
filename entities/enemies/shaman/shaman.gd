extends "res://scripts/characters/enemy.gd"

@export var projectile_effect: PackedScene
@onready var retreat_area: Area2D = $RetreatArea
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var projectile_container: Node = get_tree().current_scene.get_node("Main/Projectiles")
@onready var base_projectile_spawn := projectile_spawn.position

var player_in_retreat_area := false

func _ready() -> void:
	print(get_tree().current_scene.get_children())
	super._ready()
	_sync_retreat_area_state()

func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		velocity = Vector2.ZERO
		nav_agent.velocity = Vector2.ZERO
		anim_playback.travel("idle")
		move_and_slide()
		return

	if is_dead or is_spawning:
		return

	repath_timer -= delta

	var to_player := player.global_position - global_position
	face_direction(Vector2(to_player.x if is_zero_approx(velocity.x) else velocity.x, 0))

	if is_attacking:
		velocity = Vector2.ZERO
		return

	if player_in_retreat_area:
		_retreat_from_player(to_player)
		anim_playback.travel("run")
	elif player_in_attack_range and attack_cooldown.is_stopped():
		velocity = Vector2.ZERO
		is_attacking = true
		attack()
	elif player_in_attack_range:
		velocity = Vector2.ZERO
		anim_playback.travel("idle")
	else:
		_chase_player()
		anim_playback.travel("run")

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead or is_spawning or is_attacking:
		return

	if player_in_attack_range and not player_in_retreat_area:
		return

	velocity = safe_velocity
	move_and_slide()

func spawn_projectile() -> void:
	var projectile_scene := projectile_effect.instantiate()
	var shot_direction := (player.global_position - projectile_spawn.global_position).normalized()
	projectile_scene.global_position = projectile_spawn.global_position
	projectile_scene.max_travel_distance = _get_projectile_max_travel_distance(shot_direction)
	projectile_scene.fly(shot_direction)
	projectile_scene.damage = attack_damage
	projectile_container.add_child(projectile_scene)

func face_direction(direction: Vector2) -> void:
	if is_zero_approx(direction.x):
		return

	super.face_direction(direction)

	var facing_left := direction.x < 0
	projectile_spawn.position.x = abs(base_projectile_spawn.x) if facing_left else -abs(base_projectile_spawn.x)

func _get_projectile_max_travel_distance(shot_direction: Vector2) -> float:
	var range_shape := attack_range_shape.shape as CircleShape2D

	if range_shape:
		var range_center := attack_range_shape.global_position
		var spawn_offset := projectile_spawn.global_position - range_center
		var direction_dot := spawn_offset.dot(shot_direction)
		var discriminant := direction_dot * direction_dot - spawn_offset.length_squared() + range_shape.radius * range_shape.radius

		if discriminant >= 0.0:
			return max(0.0, -direction_dot + sqrt(discriminant)) + 10

	return 0.0

func _retreat_from_player(to_player: Vector2) -> void:
	if to_player.is_zero_approx():
		velocity = Vector2.ZERO
		return

	if repath_timer <= 0.0:
		nav_agent.target_position = global_position - to_player.normalized() * move_speed
		repath_timer = repath_interval

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_position := nav_agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(next_position) * move_speed
	nav_agent.velocity = desired_velocity

func _sync_retreat_area_state() -> void:
	player_in_retreat_area = false
	for area in retreat_area.get_overlapping_areas():
		if area.owner == player:
			player_in_retreat_area = true
			return

func _on_retreat_area_area_entered(area: Area2D) -> void:
	if area.owner == player:
		player_in_retreat_area = true

func _on_retreat_area_area_exited(area: Area2D) -> void:
	if area.owner == player:
		player_in_retreat_area = false
