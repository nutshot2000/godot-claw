# TileMap

**Inherits:** Node2D < CanvasItem < Node < Object

## Description

TileMap is a node for creating tile-based levels. It works with TileSet resources that define the tiles and their properties.

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| tile_set | TileSet | The TileSet resource containing tile definitions |
| format | int | Format version (1 or 2) |
| rendering_quadrant_size | int | Size of rendering quadrants |

## Key Methods

### get_cell_atlas_coords(layer, coords)
Get the atlas coordinates of the cell at `coords` on `layer`.

### get_cell_source_id(layer, coords)
Get the source ID of the cell at `coords` on `layer`.

### get_cell_tile_data(layer, coords)
Get the TileData object for the cell at `coords` on `layer`.

### get_used_cells(layer)
Get all cells with tiles on `layer`. Returns Array[Vector2i].

### get_used_cells_by_id(layer, source_id, atlas_coords, alternative_tile)
Get all cells using a specific tile.

### set_cell(layer, coords, source_id, atlas_coords, alternative_tile)
Set the tile at `coords` on `layer`.

```gdscript
# Set a tile
tile_map.set_cell(0, Vector2i(1, 1), 0, Vector2i(0, 0), 0)

# Clear a tile
tile_map.set_cell(0, Vector2i(1, 1), -1)
```

### erase_cell(layer, coords)
Clear the cell at `coords` on `layer`.

### get_navigation_map(layer)
Get the navigation map for the `layer`.

### get_navigation_path(layer, from, to)
Get a navigation path from `from` to `to`.

## Layers

TileMaps support multiple layers. Each layer can have different tiles and properties.

```gdscript
# Add a layer
tile_map.add_layer()

# Set layer name
tile_map.set_layer_name(0, "Ground")

# Enable layer collision
tile_map.set_layer_enabled(0, true)
```

## Collision

TileMaps can have collision shapes defined in the TileSet. These work automatically with CharacterBody2D and other physics nodes.

```gdscript
# Get the navigation region for pathfinding
var navigation_map = tile_map.get_navigation_map(0)
```

## Common Patterns

### Creating a TileMap at Runtime
```gdscript
var tile_map = TileMap.new()
tile_map.tile_set = preload("res://tileset.tres")
add_child(tile_map)

# Set tiles
for x in range(10):
    for y in range(10):
        tile_map.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0), 0)
```

### Procedural Generation
```gdscript
func generate_level():
    for x in range(width):
        for y in range(height):
            var tile_coords = Vector2i(x, y)
            if is_wall(x, y):
                tile_map.set_cell(0, tile_coords, WALL_SOURCE_ID, Vector2i(0, 0))
            else:
                tile_map.set_cell(0, tile_coords, FLOOR_SOURCE_ID, Vector2i(0, 0))
```

### Getting Tile Properties
```gdscript
func get_tile_property(coords: Vector2i) -> String:
    var tile_data = tile_map.get_cell_tile_data(0, coords)
    if tile_data:
        return tile_data.get_custom_data("terrain_type")
    return "unknown"
```

## Integration with godotclaw

When a user asks about TileMaps, godotclaw should:

1. Check if a TileMap node exists in the scene
2. Check if a TileSet resource exists in the project
3. Provide context about:
   - Current tile layer count
   - Used cells count
   - TileSet source IDs
   - Collision layers configured

### Example Context
```json
{
  "tilemap": {
    "name": "LevelTileMap",
    "layers": 3,
    "used_cells": 250,
    "tileset_path": "res://tileset.tres",
    "source_count": 5
  }
}
```

## More Information

- [Official Docs](https://docs.godotengine.org/en/stable/classes/class_tilemap.html)
- [TileSet Docs](https://docs.godotengine.org/en/stable/classes/class_tileset.html)
- [TileMap Tutorial](https://docs.godotengine.org/en/stable/tutorials/2d/tile_maps/index.html)