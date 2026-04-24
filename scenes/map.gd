@tool
extends Node2D


@export var ground: TileMapLayer 
@export var cliff: TileMapLayer
@export var shadow: TileMapLayer
@export var water: TileMapLayer 
@export var foam: TileMapLayer
@export var props: TileMapLayer
@export var trees: TileMapLayer
@export var nav: TileMapLayer

# --- TileSet source/atlas coords (adjust to match your atlas) ---
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORD := Vector2i(0, 0)
const NAV_SOURCE_ID := 0
const NAV_WALKABLE_ATLAS_COORD := Vector2i(0, 0)
const NAV_BLOCKED_ATLAS_COORD := Vector2i(2, 1)
const TILE_PHYSICS_LAYER := 0

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
			
@export var add_nav_layer := false:
	set(value):
		add_nav_layer = false
		if Engine.is_editor_hint():
			generate_nav_layer()

func generate_nav_layer() -> void:
	if ground == null or cliff == null or trees == null or nav == null:
		push_warning("Nodes not found (Ground/Cliff/Trees/Nav)")
		return

	if ground.tile_set == null or nav.tile_set == null:
		push_warning("TileSets not found (Ground/Nav)")
		return

	nav.clear()

	var ground_tile_size := ground.tile_set.tile_size
	var nav_tile_size := nav.tile_set.tile_size

	if nav_tile_size.x == 0 or nav_tile_size.y == 0:
		push_warning("Invalid nav tile size")
		return

	var tiles_per_ground_x = max(1, int(round(float(ground_tile_size.x) / float(nav_tile_size.x))))
	var tiles_per_ground_y = max(1, int(round(float(ground_tile_size.y) / float(nav_tile_size.y))))
	var valid_nav_cells := {}

	for cell in ground.get_used_cells():
		var nav_base_cell := Vector2i(cell.x * tiles_per_ground_x, cell.y * tiles_per_ground_y)
		for x in tiles_per_ground_x:
			for y in tiles_per_ground_y:
				var nav_cell := nav_base_cell + Vector2i(x, y)
				valid_nav_cells[nav_cell] = true
				nav.set_cell(nav_cell, NAV_SOURCE_ID, NAV_WALKABLE_ATLAS_COORD)

	_paint_nav_collision_cells(cliff, valid_nav_cells, ground_tile_size, nav_tile_size, tiles_per_ground_x, tiles_per_ground_y)
	_paint_nav_collision_cells(trees, valid_nav_cells, ground_tile_size, nav_tile_size, tiles_per_ground_x, tiles_per_ground_y)

func _paint_nav_collision_cells(
	layer: TileMapLayer,
	valid_nav_cells: Dictionary,
	ground_tile_size: Vector2i,
	nav_tile_size: Vector2i,
	tiles_per_ground_x: int,
	tiles_per_ground_y: int
) -> void:
	if layer == null:
		return

	for cell in layer.get_used_cells():
		var tile_data := layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		var collision_polygons := tile_data.get_collision_polygons_count(TILE_PHYSICS_LAYER)
		for polygon_index in collision_polygons:
			var polygon := tile_data.get_collision_polygon_points(TILE_PHYSICS_LAYER, polygon_index)
			if polygon.is_empty():
				continue

			_paint_nav_polygon(cell, polygon, valid_nav_cells, ground_tile_size, nav_tile_size, tiles_per_ground_x, tiles_per_ground_y)

func _paint_nav_polygon(
	cell: Vector2i,
	polygon: PackedVector2Array,
	valid_nav_cells: Dictionary,
	ground_tile_size: Vector2i,
	nav_tile_size: Vector2i,
	tiles_per_ground_x: int,
	tiles_per_ground_y: int
) -> void:
	var nav_base_cell := Vector2i(cell.x * tiles_per_ground_x, cell.y * tiles_per_ground_y)

	for x in tiles_per_ground_x:
		for y in tiles_per_ground_y:
			var nav_cell := nav_base_cell + Vector2i(x, y)
			if not valid_nav_cells.has(nav_cell):
				continue

			var nav_polygon := _build_nav_subcell_polygon(ground_tile_size, nav_tile_size, x, y)
			if Geometry2D.intersect_polygons(polygon, nav_polygon).is_empty():
				continue

			nav.set_cell(nav_cell, NAV_SOURCE_ID, NAV_BLOCKED_ATLAS_COORD)

func _build_nav_subcell_polygon(
	ground_tile_size: Vector2i,
	nav_tile_size: Vector2i,
	x: int,
	y: int
) -> PackedVector2Array:
	var left := -ground_tile_size.x * 0.5 + x * nav_tile_size.x
	var top := -ground_tile_size.y * 0.5 + y * nav_tile_size.y
	var right := left + nav_tile_size.x
	var bottom := top + nav_tile_size.y

	return PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
		
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
			if water.get_cell_source_id(neighbor) != -1 \
				and ground.get_cell_source_id(neighbor) == -1:
				foam.set_cell(cell, FOAM_SOURCE_ID, FOAM_ATLAS_COORD)
				break

func remove_prop_tiles() -> void:
	for cell in props.get_used_cells():
		var cliff_edge_atlas_cords := [Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4)]
		if cliff.get_cell_atlas_coords(cell) in cliff_edge_atlas_cords:
			props.erase_cell(cell)


		if water.get_cell_source_id(cell) != -1 and ground.get_cell_source_id(cell) == -1:
			props.erase_cell(cell)
			
	for cell in trees.get_used_cells():
		var cliff_edge_atlas_cords := [Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4)]
		if cliff.get_cell_atlas_coords(cell) in cliff_edge_atlas_cords:
			trees.erase_cell(cell)


		if water.get_cell_source_id(cell) != -1 and ground.get_cell_source_id(cell) == -1:
			trees.erase_cell(cell)
		
