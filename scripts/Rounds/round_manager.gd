extends Node

@export var enemy_scenes: Array[PackedScene] = []

var current_round := 0
var alive_enemies: int = 0
var round_active := false

@onready var enemies_container = $"../Enemies"
@onready var round_timer = $"../RoundTimer"
@onready var spawn_points = [
	$"../Background/Spawn1",
	$"../Background/Spawn2",
	$"../Background/Spawn3"
]

func _ready() -> void:
	randomize()
	round_timer.one_shot = true
	
	if not round_timer.timeout.is_connected(_on_round_timer_timeout):
		round_timer.timeout.connect(_on_round_timer_timeout)
	
	start_round()

func start_round() -> void:
	current_round += 1
	round_active = true
	
	var enemy_count: int = 2 + current_round
	alive_enemies = enemy_count
	
	#print("Starting round %d with %d enemies" % [current_round, enemy_count])
	
	for i in range(enemy_count):
		spawn_enemy()

	#print("Round %d started!" % current_round)

func spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		push_warning("RoundManager: no enemy scenes assigned.")
		return
	
	if spawn_points.is_empty():
		push_warning("RoundManager: no spawn points found.")
		return
	
	var chosen_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = chosen_scene.instantiate()
	var spawn_point: Node2D = spawn_points[randi() % spawn_points.size()]
	
	enemies_container.add_child(enemy)
	
	if enemy is Node2D:
		enemy.global_position = spawn_point.global_position
	
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		push_warning("Spawned enemy has no 'died' signal.")

func _on_enemy_died() -> void:
	alive_enemies -= 1
	#print("Enemy died. Remaining: %d" % alive_enemies)
	
	if alive_enemies <= 0 and round_active:
		round_active = false
		#print("Round %d cleared" % current_round)
		round_timer.start(2.0)

func _on_round_timer_timeout() -> void:
	start_round()
