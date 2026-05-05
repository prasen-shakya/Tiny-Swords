extends CanvasLayer

@onready var player: Node2D = $"../Decorations/Player"
@onready var enemies_container: Node = $"../Decorations/Enemies"
@onready var arrow: Control = $Arrow

const EDGE_PADDING: float = 48.0
const SCREEN_MARGIN: float = 250.0
const POP_IN_OVERSHOOT: Vector2 = Vector2(1.25, 1.25)
const POP_OUT_OVERSHOOT: Vector2 = Vector2(1.15, 1.15)

var is_arrow_visible := false
var arrow_tween: Tween

func _ready() -> void:
	set_process(true)
	arrow.visible = false
	arrow.scale = Vector2.ZERO
	arrow.modulate.a = 0.0

func _process(_delta: float) -> void:
	update_arrow()

func update_arrow() -> void:
	var nearest := get_nearest_enemy()
	if nearest == null:
		set_arrow_visible(false)
		return

	if is_any_enemy_on_screen():
		set_arrow_visible(false)
		return

	var cam := get_viewport().get_camera_2d()
	if cam == null:
		set_arrow_visible(false)
		return

	var viewport_rect = get_viewport().get_visible_rect()
	var center: Vector2 = viewport_rect.size * 0.5
	var direction: Vector2 = (nearest.global_position - cam.global_position).normalized()
	var radius: float = min(center.x, center.y) - EDGE_PADDING

	set_arrow_visible(true)
	arrow.position = center + direction * radius - arrow.pivot_offset
	arrow.rotation = Vector2.LEFT.angle_to(direction)

func set_arrow_visible(should_show: bool) -> void:
	if should_show == is_arrow_visible:
		return

	is_arrow_visible = should_show

	if arrow_tween != null:
		arrow_tween.kill()

	arrow_tween = create_tween()
	arrow_tween.set_parallel(true)

	if should_show:
		arrow.visible = true
		arrow.scale = Vector2.ZERO
		arrow.modulate.a = 0.0
		arrow_tween.tween_property(arrow, "modulate:a", 1.0, 0.08)
		arrow_tween.tween_property(arrow, "scale", POP_IN_OVERSHOOT, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		arrow_tween.chain().tween_property(arrow, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		arrow_tween.tween_property(arrow, "modulate:a", 0.0, 0.12).set_delay(0.04)
		arrow_tween.tween_property(arrow, "scale", POP_OUT_OVERSHOOT, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		arrow_tween.chain().tween_property(arrow, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		arrow_tween.chain().tween_callback(Callable(self, "_hide_arrow_after_pop_out"))

func _hide_arrow_after_pop_out() -> void:
	if !is_arrow_visible:
		arrow.visible = false

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
