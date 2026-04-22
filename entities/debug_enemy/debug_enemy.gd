extends "res://scripts/characters/entity.gd"

var speed: float = 300.0

var should_chase: bool = false

var player_node

func _ready() -> void:
	super._ready()
	add_to_group("enemies")

func should_queue_free_on_death() -> bool:
	return true

func _physics_process(delta: float) -> void:
	if is_spawning:
		return
		
	var player = _get_player_node()
	if player == null or player.is_dead:
		should_chase = false
		velocity = Vector2.ZERO
		return

	if should_chase:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = velocity.lerp(direction * speed, 8.5 * delta)
		move_and_slide()
		face_direction(direction)
	else:
		velocity = Vector2.ZERO

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == _get_player_node():
		die()

func _on_enter_area_body_entered(body: Node2D) -> void:
	if body == _get_player_node():
		should_chase = true

func _on_exit_area_body_exited(body: Node2D) -> void:
	if body == _get_player_node():
		should_chase = false

func _get_player_node():
	if is_instance_valid(player_node):
		return player_node

	player_node = get_tree().get_first_node_in_group("player")
	return player_node
