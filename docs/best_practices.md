# Godot Best Practices

This document covers common pitfalls and best practices that AI assistants often get wrong.

## Scene Organization

### When to Use Scenes vs Scripts

**Use SCENES for:**
- Complex node hierarchies
- Reusable game objects (enemies, items, UI elements)
- Anything with multiple nodes and configuration
- Content that designers might edit

**Use SCRIPTS for:**
- Simple behaviors on single nodes
- Utility classes and singletons
- Custom resource types
- Editor tools and plugins

**Key insight:** Scenes are declarative, scripts are imperative. Scenes can define initialization but not behavior. Use both together.

```gdscript
# GOOD: Scene for complex object, script for behavior
# Player.tscn contains: CharacterBody2D > Sprite2D, CollisionShape2D, Camera2D
# Player.gd extends CharacterBody2D with movement logic

# BAD: Creating node hierarchies purely in code
func _init():
    var child = Node.new()
    child.name = "Child"
    child.script = preload("child.gd")
    add_child(child)
    # This is slow and error-prone!
```

### Performance: PackedScene vs Script

Creating nodes via script is slower than instantiating scenes. PackedScene uses serialized data and the engine processes it in batches.

```gdscript
# GOOD: Instantiate from PackedScene
const PlayerScene = preload("res://player.tscn")
var player = PlayerScene.instantiate()

# SLOWER: Build in script
var player = CharacterBody2D.new()
var sprite = Sprite2D.new()
player.add_child(sprite)
# ... many more lines
```

---

## Autoloads vs Internal Nodes

### The Problem with Global Managers

Autoloads (singletons) create global state problems:

1. **Global state**: One object responsible for all objects' data
2. **Global access**: Any code can call it from anywhere, making bugs hard to trace
3. **Global resource allocation**: Fixed pool size can be too small or wasteful

### When Autoloads ARE Good

- Systems with broad scope that manage their own data
- Quest systems, dialogue systems, game state managers
- Systems that don't interfere with other objects' data

### Better Pattern: Scene-Local Management

Each scene manages its own resources:

```gdscript
# GOOD: Each scene has its own AudioStreamPlayer
# Enemy.tscn
extends CharacterBody2D

@onready var audio = $AudioStreamPlayer

func play_sound(path: String):
    audio.stream = load(path)
    audio.play()

# BAD: Global sound manager
# Sound.gd (Autoload)
static func play(path: String):
    # Manages pool of AudioStreamPlayers globally
    # Hard to debug, wasteful if pool is too large
```

### Using `static` Instead of Autoloads

Since Godot 4.1, you can use static variables:

```gdscript
# GameState.gd
class_name GameState
extends RefCounted

static var score: int = 0
static var lives: int = 3

static func add_score(points: int):
    score += points

# No autoload needed! Access from anywhere:
# GameState.add_score(100)
```

---

## Node Alternatives

Don't use Nodes for everything. Lighter alternatives:

### Object
- Lightest weight
- Manual memory management (use with caution)
- Good for data structures, tree structures

### RefCounted
- Automatic memory management (reference counting)
- Only slightly heavier than Object
- Good for most custom data classes

### Resource
- Can be serialized (saved/loaded)
- Inspector-compatible
- Good for data containers, configuration

```gdscript
# GOOD: Use RefCounted for data structures
class_name Inventory
extends RefCounted

var items: Array = []

func add(item: Item):
    items.append(item)

# BAD: Using Node for pure data
class_name Inventory
extends Node  # Unnecessary overhead
```

---

## Accessing Objects: Interfaces

### Duck Typing in Godot

Godot uses duck typing - it checks if an object implements a method, not its type.

```gdscript
# Duck-typed access (will crash if method doesn't exist)
get_parent().visible = false

# Safe access with check
var parent = get_parent()
if parent.has_method("set_visible"):
    parent.set_visible(false)

# Type check with casting
var parent = get_parent()
if parent is CanvasItem:
    parent.visible = false
```

### NodePath Caching

Always cache node references for performance:

```gdscript
# SLOW: Dynamic lookup every time
func _process(delta):
    get_node("Child").do_something()
    get_node("Child").do_another_thing()

# FASTER: Cached NodePath
@onready var child = $Child
func _process(delta):
    child.do_something()
    child.do_another_thing()

# FASTEST: Export (assign in Inspector)
@export var child: Node
func _process(delta):
    child.do_something()
```

### Using Groups as Interfaces

Groups can define informal interfaces:

```gdscript
# Define convention: any node in "quest" group has complete() and fail()
for quest_node in get_tree().get_nodes_in_group("quest"):
    quest_node.complete()
```

---

## Project Organization

### File Structure

```
/project.godot
/addons/              # Third-party plugins
/assets/              # Shared resources (sprites, sounds, etc.)
/characters/          # Character-related scenes and scripts
  /player/
    player.tscn
    player.gd
  /enemies/
    /goblin/
      goblin.tscn
      goblin.gd
/levels/              # Game levels
  riverdale.tscn
/ui/                  # UI scenes
  hud.tscn
  menu.tscn
/autoload/            # Singleton scripts
  game_state.gd
/resources/           # Resource files (.tres)
  player_stats.tres
```

### Naming Conventions

- **snake_case** for files and folders (lowercase)
- **PascalCase** for node names
- **snake_case** for GDScript functions and variables
- **UPPER_CASE** for constants
- C# scripts are exception (PascalCase for filename to match class)

### Case Sensitivity

Windows/macOS are case-insensitive, Linux is case-sensitive. Use lowercase for all project files to avoid export issues.

---

## Common AI Mistakes

### Mistake 1: Overusing Autoloads

**AI often suggests:** "Create an autoload for [GameManager, SoundManager, UIManager, etc.]"

**Better approach:** Each scene should manage its own state. Use signals for communication.

### Mistake 2: Creating Node Hierarchies in Code

**AI often suggests:** Building complex scenes purely in GDScript

**Better approach:** Create scenes in the editor, instantiate them. Only use code for dynamic content.

### Mistake 3: Using Nodes for Data

**AI often suggests:** "extends Node" for data classes

**Better approach:** Use `RefCounted` for pure data, `Resource` for saveable data.

### Mistake 4: Global Access via Singleton

**AI often suggests:** "Access from anywhere with GameManager.instance"

**Better approach:** Pass references through signals or dependency injection.

### Mistake 5: Direct Property Access

**AI often suggests:** `get_node("Child").property = value`

**Better approach:** Cache with `@onready` or use `@export` for Inspector assignment.

---

## Data Structures: Array vs Dictionary vs Object

### Array
- **Fast:** Iteration, get/set by index
- **Slow:** Insert/erase from front, find by value
- **Use for:** Ordered sequences, iteration-heavy code

### Dictionary
- **Fast:** Insert, erase, get/set by key
- **Slow:** Find by value
- **Use for:** Key-value lookups, configuration, caching

### Object
- **Slow:** Property lookups (must check inheritance chain)
- **Use for:** Complex behaviors, signals, custom abstractions

```gdscript
# GOOD: Array for iteration
var enemies: Array = []
for enemy in enemies:
    enemy.update(delta)

# GOOD: Dictionary for lookups
var items_by_id: Dictionary = {}
func get_item(id: String) -> Item:
    return items_by_id[id]

# BAD: Object for simple key-value storage
# Dictionary is much faster for this
```

---

## Signals vs Polling

### Use Signals for Events

```gdscript
# GOOD: Signal-based communication
signal health_changed(new_health: int)
signal died()

func take_damage(amount: int):
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        died.emit()

# Other nodes connect:
func _ready():
    player.health_changed.connect(_on_health_changed)
    player.died.connect(_on_player_died)
```

### Avoid Polling

```gdscript
# BAD: Polling every frame
func _process(delta):
    if player.health != last_health:
        update_health_display()
        last_health = player.health

# GOOD: Event-driven
func _ready():
    player.health_changed.connect(update_health_display)
```

---

## Animation Classes

### AnimatedTexture
- Simple sprite animation in a Texture
- Good for: Simple UI animations, decorative elements

### AnimatedSprite2D
- Sprite-based animation with SpriteFrames resource
- Good for: Character animations, effects
- Best for: Simple sprite animations

### AnimationPlayer
- Keyframe animation of any property
- Good for: Complex animations, cutscenes, UI transitions
- Best for: Most game animations

### AnimationTree
- State machine for animations
- Good for: Complex character animation states
- Best for: Characters with many animation states (idle, walk, run, jump, attack, etc.)

```gdscript
# Choose based on complexity:
# 1-2 frame sprite animation → AnimatedTexture
# Simple sprite animations → AnimatedSprite2D
# Complex property animations → AnimationPlayer
# State-based character animations → AnimationTree
```