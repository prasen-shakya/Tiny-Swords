extends CharacterBody2D

@onready var player_node: CharacterBody2D = get_node("/root/Main/Decorations/Player") 

signal died

var speed: float = 300.0

var should_chase: bool = false

func _ready():
	add_to_group("enemies")

func _process(delta: float) -> void:
	if should_chase:
		var direction = (player_node.global_position - global_position).normalized()
		velocity = lerp(velocity, direction * speed , 8.5 * delta) 
		move_and_slide()
		if direction.x > 0:
			$Sprite2D.flip_h = false
		elif direction.x < 0:
			$Sprite2D.flip_h = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player_node:
		died.emit()
		queue_free()


func _on_enter_area_body_entered(body: Node2D) -> void:
	if body == player_node:
		should_chase = true

func _on_exit_area_body_exited(body: Node2D) -> void:
	if body == player_node:
		should_chase = false
