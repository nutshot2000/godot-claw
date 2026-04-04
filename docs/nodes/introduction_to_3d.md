# Introduction to 3D

## 3D Workspace

The 3D workspace is automatically selected when a Node3D node is selected.

### Main Toolbar

- **Select Mode** (Q): Select nodes, use gizmos
- **Move Mode** (W): Move nodes with gizmo
- **Rotate Mode** (E): Rotate nodes with gizmo
- **Scale Mode** (R): Scale nodes with gizmo
- **Lock** (Ctrl+L): Lock nodes to prevent selection
- **Group** (Ctrl+G): Group selected nodes
- **Ruler Mode** (M): Measure distance in meters
- **Use Local Space** (T): Use node's rotation for gizmos
- **Use Snap** (Y): Snap to grid

### Navigation

Default controls (Blender-style):
- **Middle mouse + drag**: Orbit around center
- **Right mouse + WASD**: Free-look mode
- **Shift + F**: Toggle free-look
- **F**: Focus on selected object
- **Keypad 5**: Toggle perspective/orthogonal

## Coordinate System

- **1 unit = 1 meter** (metric system)
- **Y is up**
- **Right-handed coordinate system**:
  - X = sides (red)
  - Y = up/down (green)
  - Z = front/back (blue)

## Node3D

Base node for all 3D. Provides:
- Position (Vector3)
- Rotation (Vector3 - Euler angles)
- Scale (Vector3)
- Transform (Transform3D)

```gdscript
# Access transform
var pos = node_3d.position
var rot = node_3d.rotation
var scale = node_3d.scale

# Set position
node_3d.position = Vector3(10, 5, 0)

# Look at target
node_3d.look_at(target_position, Vector3.UP)
```

## 3D Content Types

### Imported Models
- Use external DCC tools (Blender, Maya, etc.)
- Export to glTF, OBJ, or other supported formats
- Import as scenes or resources

### Generated Geometry
- Use `ArrayMesh` for static geometry
- Use `SurfaceTool` for easier mesh creation
- Use `ImmediateMesh` for dynamic geometry

```gdscript
# Create mesh with SurfaceTool
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
st.add_vertex(Vector3(0, 0, 0))
st.add_vertex(Vector3(1, 0, 0))
st.add_vertex(Vector3(0.5, 1, 0))
var mesh = st.commit()
mesh_instance.mesh = mesh
```

### 2D in 3D
- Use `Sprite3D` or `AnimatedSprite3D`
- Fixed camera for 2D-style games
- Can mix with 3D backgrounds

## Environment

### WorldEnvironment
- Background color or skybox
- Post-processing effects
- Ambient light

### Preview Environment
- Auto-enabled if no WorldEnvironment exists
- Editor-only preview
- Toggle with sun/environment icons

## Cameras

Camera3D is required to see anything. Only one camera can be active per viewport.

### Camera Properties
- `fov`: Field of view (default: 75°)
- `near`: Near clip distance (default: 0.05)
- `far`: Far clip distance (default: 4000)
- `projection`: Perspective, Orthogonal, or Frustum
- `current`: Is this the active camera?

```gdscript
# Set camera properties
camera.fov = 90.0
camera.near = 0.1
camera.far = 1000.0

# Make camera active
camera.make_current()

# Project screen position to world
var world_pos = camera.project_position(screen_point, z_depth)

# Project world position to screen
var screen_pos = camera.unproject_position(world_point)
```

### Camera Modes

```gdscript
# Perspective (default)
camera.projection = Camera3D.PROJECTION_PERSPECTIVE

# Orthogonal (no perspective)
camera.projection = Camera3D.PROJECTION_ORTHOGONAL
camera.size = 10.0  # View size in units
```

## Lights

### DirectionalLight3D
- Sun/moon lighting
- Parallel rays
- Best for outdoor scenes

```gdscript
var sun = DirectionalLight3D.new()
sun.light_color = Color.WHITE
sun.light_energy = 1.0
sun.shadow_enabled = true
add_child(sun)
```

### OmniLight3D
- Point light (light bulb)
- Radiates in all directions

```gdscript
var light = OmniLight3D.new()
light.light_color = Color.WHITE
light.light_energy = 1.0
light.omni_range = 10.0
add_child(light)
```

### SpotLight3D
- Cone-shaped light
- Directional spotlight

```gdscript
var light = SpotLight3D.new()
light.light_color = Color.WHITE
light.spot_range = 20.0
light.spot_angle = 30.0
add_child(light)
```

## Common Patterns

### Third-Person Camera

```gdscript
extends Camera3D

@export var target: Node3D
@export var distance: float = 10.0
@export var height: float = 5.0

func _process(delta):
    if target:
        global_position = target.global_position + Vector3(0, height, distance)
        look_at(target.global_position)
```

### First-Person Camera

```gdscript
extends Camera3D

@export var mouse_sensitivity: float = 0.002

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
    if event is InputEventMouseMotion:
        rotation.y -= event.relative.x * mouse_sensitivity
        rotation.x -= event.relative.y * mouse_sensitivity
        rotation.x = clamp(rotation.x, -PI/2, PI/2)
```

## Integration with godotclaw

When a user asks about 3D, godotclaw should:

1. Check for Node3D-derived nodes in scene
2. Identify camera and light setup
3. Check for MeshInstance3D nodes
4. Provide context about:
   - Scene hierarchy (Node3D tree)
   - Camera configuration
   - Light types and positions
   - Mesh resources

### Example Context
```json
{
  "3d_scene": {
    "root_type": "Node3D",
    "nodes": {
      "Player": {
        "type": "CharacterBody3D",
        "position": [10, 0, 5],
        "children": ["MeshInstance3D", "CollisionShape3D", "Camera3D"]
      },
      "World": {
        "type": "Node3D",
        "children": ["MeshInstance3D", "WorldEnvironment"]
      }
    },
    "camera": {
      "type": "Camera3D",
      "fov": 75,
      "projection": "perspective"
    },
    "lights": ["DirectionalLight3D"]
  }
}
```