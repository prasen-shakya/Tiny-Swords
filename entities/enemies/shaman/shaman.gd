extends "res://scripts/characters/enemy.gd"

@export var projectile_effect: PackedScene
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var base_projectile_spawn := projectile_spawn.position

func spawn_projectile() -> void:
	var projectile_scene := projectile_effect.instantiate()
	projectile_scene.global_position = projectile_spawn.global_position
	projectile_scene.max_travel_distance = _get_projectile_max_travel_distance()
	projectile_scene.fly((player.global_position - projectile_spawn.global_position).normalized())
	projectile_scene.damage = attack_damage
	get_parent().add_child(projectile_scene)

func _update_facing(direction_x: float) -> void:
	if is_zero_approx(direction_x):
		return

	super._update_facing(direction_x)
	
	var facing_left := direction_x < 0
	projectile_spawn.position.x = abs(base_projectile_spawn.x) if facing_left else -abs(base_projectile_spawn.x)

func _get_projectile_max_travel_distance() -> float:
	var range_shape := attack_range_shape.shape as CircleShape2D

	if range_shape:
		return range_shape.radius + 50

	return 0.0
