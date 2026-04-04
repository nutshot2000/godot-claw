# NavigationAgent2D

**Inherits:** Node < Object

## Description

NavigationAgent2D is used for pathfinding in 2D games. It works with NavigationRegion2D nodes to find paths through tilemaps or polygon regions.

## Key Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| path_desired_distance | float | 1.0 | Distance threshold for path completion |
| target_desired_distance | float | 1.0 | Distance threshold for target reached |
| radius | float | 10.0 | Agent radius for pathfinding |
| speed | float | 10.0 | Max speed |
| avoidance_enabled | bool | false | Enable obstacle avoidance |

## Key Methods

### set_target_position(position: Vector2)
Set the target position for pathfinding.

### get_next_path_position() -> Vector2
Returns the next position to move toward. Call this after `set_target_position()`.

### is_navigation_finished() -> bool
Returns `true` if the agent has reached its target.

### get_current_navigation_path() -> PackedVector2Array
Returns the current path as an array of Vector2 points.

### distance_to_target() -> float
Returns the distance to the target position.

### get_target_position() -> Vector2
Returns the current target position.

## Setup Requirements

1. Add a NavigationRegion2D to your scene
2. Define navigation polygons or use a TileMap with navigation layers
3. Add NavigationAgent2D to your moving entity
4. Call `set_target_position()` and follow the path

## Common Patterns

### Basic Pathfinding
```gdscript
extends CharacterBody2D

@onready var nav_agent = $NavigationAgent2D

func _physics_process(delta):
    if nav_agent.is_navigation_finished():
        return
    
    var next_position = nav_agent.get_next_path_position()
    var direction = (next_position - global_position).normalized()
    velocity = direction * speed
    move_and_slide()

func move_to(target: Vector2):
    nav_agent.set_target_position(target)
```

### With TileMap Navigation
```gdscript
# TileMap needs navigation layers configured
# NavigationAgent2D will automatically use the TileMap's navigation

func _ready():
    # Target the player
    nav_agent.set_target_position(player.global_position)
    
    # Update path periodically
    Timer.new().connect("timeout", _update_path)
    add_child(timer)
    timer.start(0.5)

func _update_path():
    nav_agent.set_target_position(player.global_position)
```

### Avoidance
```gdscript
func _ready():
    nav_agent.avoidance_enabled = true
    nav_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta):
    var next_position = nav_agent.get_next_path_position()
    var target_velocity = (next_position - global_position).normalized() * speed
    
    # Let avoidance compute the final velocity
    nav_agent.set_velocity(target_velocity)

func _on_velocity_computed(safe_velocity: Vector2):
    velocity = safe_velocity
    move_and_slide()
```

## Integration with godotclaw

When a user asks about pathfinding or AI movement, godotclaw should:

1. Check if NavigationRegion2D or TileMap with navigation exists
2. Check if NavigationAgent2D exists on moving entities
3. Provide context about:
   - Navigation regions in the scene
   - Agents configured
   - Target positions

### Example Context
```json
{
  "navigation": {
    "has_navigation_region": true,
    "navigation_region_path": "res://navigation.tres",
    "agents": [
      {
        "name": "Enemy/NavigationAgent2D",
        "has_target": true,
        "target_position": [100, 200]
      }
    ]
  }
}
```

## More Information

- [Official Docs](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html)
- [Navigation Tutorial](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html)