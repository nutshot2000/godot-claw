# Scene Organization

## Building Relationships Effectively

The biggest challenge in Godot is managing dependencies between scenes. When you create a scene and then split it into sub-scenes, hard references break.

### Key Principle: Design scenes with NO dependencies

If a scene must interact with external context, use **Dependency Injection**:

```gdscript
# BAD: Child hardcodes reference to parent
func _ready():
    get_parent().do_something()  # Breaks if reparented!

# GOOD: Parent injects dependency
# Child script
@export var target: Node

func execute():
    if target:
        target.do_something()

# Parent script
func _ready():
    $Child.target = $Receiver
```

### Ways to Inject Dependencies

**1. Signals (Safest)**
```gdscript
# Parent
$Child.signal_name.connect(_on_child_signal)

# Child
signal completed
signal_name.emit()  # Triggers parent behavior
```

**2. Callable Property**
```gdscript
# Parent
$Child.func_property = _on_child_complete

# Child
var func_property: Callable
func complete():
    if func_property:
        func_property.call()
```

**3. Node Reference**
```gdscript
# Parent
$Child.target = self

# Child
var target: Node
func do_work():
    target.some_method()
```

**4. NodePath**
```gdscript
# Parent
$Child.target_path = ".."

# Child
@export var target_path: NodePath
func do_work():
    var target = get_node(target_path)
    target.some_method()
```

---

## Choosing a Node Tree Structure

### Recommended Structure

```
Main (main.gd)
├── World (Node2D/Node3D)
│   ├── Level
│   └── Entities
└── GUI (Control)
```

- **Main**: Entry point, manages scene transitions
- **World**: Game content (2D or 3D)
- **GUI**: Menus, HUD, overlays

### Where to Put Systems

**Autoload (Global Singleton) if:**
- Tracks all data internally
- Needs global access
- Exists in isolation
- Examples: Game settings, Save manager, EventBus

**Scene-local if:**
- Manages data for one scene
- Doesn't need global access
- Examples: Level spawner, Local AI manager

### Parent-Child Relationships

Only make nodes children if removing the parent should remove the children:

```gdscript
# GOOD: Enemy contains its components
Enemy (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
└── HealthBar

# BAD: Player inside Level (shouldn't be deleted with level)
Level
└── Player  # Player should be SIBLING, not child
```

### When Player Must Persist Between Levels

**Option A: Move player before deleting level**
```gdscript
func change_level(new_level_path: String):
    # Move player to temporary parent
    var player = $World/Player
    remove_child(player)
    
    # Delete old level
    $World.queue_free()
    
    # Load new level
    var new_level = load(new_level_path).instantiate()
    add_child(new_level)
    
    # Re-add player
    new_level.add_child(player)
```

**Option B: Keep player in separate branch (Better)**
```
Main
├── Player  # Always exists
├── World   # Swap this out for new levels
│   ├── Level1
│   └── Level2
└── GUI
```

### When Child Shouldn't Inherit Transform

If you need a child that doesn't move with its parent:

**Option 1: Use intermediate Node**
```
Parent (Node2D)
└── Holder (Node)  # Node has no transform
    └── Child (Node2D)  # Independent transform
```

**Option 2: Use top_level property**
```gdscript
# For CanvasItem or Node3D
child.top_level = true  # Ignores parent's transform
```

---

## RemoteTransform for Coordinated Positioning

When separate nodes need to position themselves relative to each other:

```gdscript
# Player contains RemoteTransform2D
# Camera follows but isn't child of Player

Player
└── RemoteTransform2D  # Target: Camera

Camera  # Sibling, not child
```

---

## Scene Organization Rules

1. **Siblings should not know about each other** - Ancestor mediates
2. **Children should be dependent on parent** - Deleting parent deletes children
3. **Independent systems should be siblings or autoloads** - Not parent-child
4. **Document unusual relationships** - Use `_get_configuration_warnings()`

```gdscript
func _get_configuration_warnings() -> PackedStringArray:
    var warnings = []
    if not has_node("CollisionShape2D"):
        warnings.append("This node needs a CollisionShape2D child")
    return warnings
```

---

## OOP Principles Apply

Scripts and scenes should follow:

- **SOLID**: Single responsibility, Open/closed, etc.
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It

---

## Key Takeaways

1. Scenes work best when they work alone
2. If scenes need external context, use dependency injection
3. Keep children dependent on parents (delete together)
4. Independent systems should be siblings, not parent-child
5. Use signals for communication between unrelated nodes
6. Avoid hard references with `get_parent()` or `get_node("../Sibling")`