@tool
extends Node2D


@export var ground: TileMapLayer 
@export var cliff: TileMapLayer
@export var shadow: TileMapLayer
@export var water: TileMapLayer 
@export var foam: TileMapLayer
@export var props: TileMapLayer

# --- TileSet source/atlas coords (adjust to match your atlas) ---
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORD := Vector2i(0, 0)

const FOAM_SOURCE_ID := 0
const FOAM_ATLAS_COORD := Vector2i(0, 0)

@export var generate_shadow := false:
	set(value):
		generate_shadow = false
		if Engine.is_editor_hint():
			generate_shadows()

@export var generate_water_foam := false:
	set(value):
		generate_water_foam = false
		if Engine.is_editor_hint():
			generate_foam()

@export var filter_props := false:
	set(value):
		filter_props = false
		if Engine.is_editor_hint():
			remove_prop_tiles()

func generate_shadows() -> void:
	if cliff == null or shadow == null:
		push_warning("Nodes not found (Cliff/Shadow)")
		return
	
	shadow.clear()
	
	for cell in cliff.get_used_cells():
		var cliff_edge_atlas_cords := [Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4)]
		if cliff.get_cell_atlas_coords(cell) in cliff_edge_atlas_cords:
			shadow.set_cell(cell, 1, Vector2i(0,0))

func generate_foam() -> void:
	if ground == null or water == null or foam == null:
		push_warning("Nodes not found (Ground/Water/WaterFoam).")
		return

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
			if water.get_cell_source_id(neighbor) != -1 and ground.get_cell_source_id(neighbor) == -1:
				foam.set_cell(cell, FOAM_SOURCE_ID, FOAM_ATLAS_COORD)
				break

func remove_prop_tiles() -> void:
	for cell in props.get_used_cells():
		var cliff_edge_atlas_cords := [Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4)]
		if cliff.get_cell_atlas_coords(cell) in cliff_edge_atlas_cords:
			props.erase_cell(cell)


		if water.get_cell_source_id(cell) != -1 and ground.get_cell_source_id(cell) == -1:
			props.erase_cell(cell)
