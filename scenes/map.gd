@tool
extends Node2D

const FOAM_SOURCE_ID := 0
const FOAM_ATLAS_COORD := Vector2i(0, 0)

@export var regenerate := false:
	set(value):
		regenerate = false
		if Engine.is_editor_hint():
			generate_foam()
	
func generate_foam() -> void:
	var ground: TileMapLayer = get_node_or_null("Ground")
	
	var water: TileMapLayer = get_node_or_null("Water")
	var foam: TileMapLayer = get_node_or_null("WaterFoam")

	if ground == null or water == null or foam == null:
		print("Nodes not found")
		return

	print("Generating foam...")
	foam.clear()

	var directions := [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]


	for cell in ground.get_used_cells():
		for dir in directions:
			var neighbor = cell + dir

			# Water exists AND ground does not exist there
			if water.get_cell_source_id(neighbor) != -1 \
			and ground.get_cell_source_id(neighbor) == -1:
				foam.set_cell(
					cell,
					FOAM_SOURCE_ID,
					FOAM_ATLAS_COORD
				)
