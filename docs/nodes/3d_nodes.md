# 3D Nodes Quick Reference

## MeshInstance3D

**Inherits:** GeometryInstance3D < VisualInstance3D < Node3D < Node < Object

Node that instances meshes into a scenario.

### Key Properties
- `mesh` - The Mesh resource to display
- `skeleton` - NodePath to Skeleton3D for animations
- `skin` - Skin resource for skeletal animation

### Key Methods
```gdscript
# Create collision from mesh
mesh_instance.create_trimesh_collision()  # Triangle mesh collision
mesh_instance.create_convex_collision()    # Convex collision

# Blend shapes
mesh_instance.get_blend_shape_count()
mesh_instance.set_blend_shape_value(index, value)
mesh_instance.get_blend_shape_value(index)

# Materials
mesh_instance.get_active_material(surface_index)
mesh_instance.set_surface_override_material(surface_index, material)
```

### Common Usage
```gdscript
# Load mesh at runtime
var mesh = load("res://model.glb")
mesh_instance.mesh = mesh

# Create collision
mesh_instance.create_trimesh_collision()
```

---

## Camera3D

**Inherits:** Node3D < Node < Object

Camera node for 3D rendering.

### Key Properties
- `fov` - Field of view (default: 75.0)
- `near` - Near clip distance (default: 0.05)
- `far` - Far clip distance (default: 4000.0)
- `projection` - Perspective, Orthogonal, or Frustum
- `current` - Is this the active camera?

### Key Methods
```gdscript
# Project screen position to world
var world_pos = camera.project_position(screen_point, z_depth)

# Project world position to screen
var screen_pos = camera.unproject_position(world_point)

# Get camera frustum
var frustum = camera.get_frustum()

# Make this camera active
camera.make_current()
```

### Third-Person Camera Pattern
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

---

## Node3D

**Inherits:** Node < Object

Base class for all 3D nodes. Provides transform and spatial operations.

### Key Properties
- `position` - Position in local space
- `rotation` - Rotation in radians (Euler angles)
- `scale` - Scale factor
- `global_position` - Position in world space
- `global_rotation` - Rotation in world space
- `global_transform` - Full transform in world space

### Key Methods
```gdscript
# Movement
node.translate(Vector3(1, 0, 0))
node.rotate_y(PI / 2)
node.rotate_object(Vector3(0, 1, 0), angle)

# Look at
node.look_at(target_position, Vector3.UP)

# Get direction vectors
var forward = -node.global_transform.basis.z
var right = node.global_transform.basis.x
var up = node.global_transform.basis.y

# Distance to other node
var distance = node.global_position.distance_to(other_node.global_position)
```

---

## CharacterBody3D

**Inherits:** PhysicsBody3D < CollisionObject3D < Node3D < Node < Object

3D physics body for character movement.

### Key Properties
- `velocity` - Current velocity (Vector3)
- `up_direction` - Direction considered "up" (default: Vector3.UP)
- `floor_stop_on_slope` - Stop on slopes?
- `floor_max_angle` - Maximum slope angle (default: PI/4)

### Movement Pattern
```gdscript
extends CharacterBody3D

@export var speed: float = 10.0
@export var jump_velocity: float = 5.0
@export var gravity: float = 20.0

func _physics_process(delta):
    # Add gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    
    # Movement input
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = 0
        velocity.z = 0
    
    move_and_slide()
```

---

## RigidBody3D

**Inherits:** PhysicsBody3D < CollisionObject3D < Node3D < Node < Object

3D physics body for realistic physics simulation.

### Key Properties
- `mass` - Body mass
- `linear_velocity` - Current linear velocity
- `angular_velocity` - Current angular velocity
- `linear_damp` - Linear velocity damping
- `angular_damp` - Angular velocity damping
- `gravity_scale` - Gravity multiplier

### Key Methods
```gdscript
# Apply forces
rigid_body.apply_force(force, offset)
rigid_body.apply_torque(torque)
rigid_body.apply_impulse(impulse, offset)
rigid_body.apply_torque_impulse(impulse)

# Get/Set velocity
rigid_body.get_linear_velocity()
rigid_body.set_linear_velocity(velocity)
```

---

## Integration with godotclaw

When a user asks about 3D, godotclaw should:

1. Check for Node3D-derived nodes in scene
2. Identify camera setup
3. Check for physics bodies
4. Provide context about:
   - Scene hierarchy
   - Mesh types
   - Collision shapes
   - Camera configuration

### Example Context
```json
{
  "3d_scene": {
    "nodes": {
      "Player": {
        "type": "CharacterBody3D",
        "has_script": true,
        "children": ["MeshInstance3D", "CollisionShape3D", "Camera3D"]
      },
      "Level": {
        "type": "Node3D",
        "children": ["GroundMesh", "GroundCollision"]
      }
    },
    "camera": {
      "type": "Camera3D",
      "fov": 75,
      "projection": "perspective"
    }
  }
}
```