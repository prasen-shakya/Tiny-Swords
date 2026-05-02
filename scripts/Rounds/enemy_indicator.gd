extends CanvasLayer

@onready var player: Node2D = $"../Decorations/Player"
@onready var enemies_container: Node = $"../Decorations/Enemies"
@onready var arrow: Control = $Arrow

const EDGE_PADDING: float = 48.0
const SCREEN_MARGIN: float = 250.0

func _ready() -> void:
	set_process(true)
	arrow.visible = false

func _process(_delta: float) -> void:
	update_arrow()

func update_arrow() -> void:
	var nearest := get_nearest_enemy()
	if nearest == null:
		arrow.visible = false
		return

	if is_any_enemy_on_screen():
		arrow.visible = false
		return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		arrow.visible = false
		return

	var viewport_rect = get_viewport().get_visible_rect()
	var center: Vector2 = viewport_rect.size * 0.5
	var direction: Vector2 = (nearest.global_position - cam.global_position).normalized()
	var radius: float = min(center.x, center.y) - EDGE_PADDING

	arrow.visible = true
	arrow.position = center + direction * radius
	arrow.rotation = Vector2.LEFT.angle_to(direction)

func get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF

	for enemy in enemies_container.get_children():
		if enemy == null:
			continue
		if !is_instance_valid(enemy):
			continue
		if !(enemy is Node2D):
			continue

		var enemy_node := enemy as Node2D
		var distance := player.global_position.distance_squared_to(enemy_node.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy_node

	return nearest

func is_any_enemy_on_screen() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return false

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_size: Vector2 = viewport_size * 0.5 * cam.zoom

	var visible_rect := Rect2(
		cam.global_position - half_size,
		viewport_size * cam.zoom
	)

	visible_rect = visible_rect.grow(-SCREEN_MARGIN)

	for enemy in enemies_container.get_children():
		if enemy == null:
			continue
		if !is_instance_valid(enemy):
			continue
		if !(enemy is Node2D):
			continue

		var enemy_node := enemy as Node2D
		if visible_rect.has_point(enemy_node.global_position):
			return true

	return false
