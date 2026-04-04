# GDScript Quick Reference

Comprehensive GDScript patterns and common code snippets for godotclaw.

## Table of Contents
- [Signals](#signals)
- [Coroutines & Await](#coroutines--await)
- [Input Handling](#input-handling)
- [Node Lifecycle](#node-lifecycle)
- [Animation](#animation)
- [Timers](#timers)
- [Tween](#tween)
- [CharacterBody2D Movement](#characterbody2d-movement)
- [Control & UI](#control--ui)
- [HTTPRequest](#httprequest)
- [Common Patterns](#common-patterns)

---

## Signals

Godot's signal system implements the observer pattern for decoupled communication.

### Declare and Emit Signals

```gdscript
extends Node

# Declare custom signals
signal health_changed(new_health)
signal player_died
signal item_collected(item_name, quantity)

var health = 100

func take_damage(amount):
    health -= amount
    health_changed.emit(health)  # Emit with argument

    if health <= 0:
        player_died.emit()  # Emit without arguments
```

### Connect Signals

```gdscript
func _ready():
    # Modern connection syntax
    health_changed.connect(_on_health_changed)
    player_died.connect(_on_player_died)

    # Connect with bound arguments
    item_collected.connect(_on_item_collected.bind("bonus", 2))

    # Connect built-in signals
    $Button.pressed.connect(_on_button_pressed)
    $Timer.timeout.connect(_on_timer_timeout)

func _on_health_changed(new_health):
    print("Health is now: ", new_health)

func _on_player_died():
    print("Game Over!")

func _on_item_collected(item_name, quantity, bonus_type, multiplier):
    print("Collected ", quantity, "x ", item_name)
```

### One-Time Connection

```gdscript
func _ready():
    # Disconnect after first call
    $Button.pressed.connect(_on_button_pressed, CONNECT_ONE_SHOT)
```

---

## Coroutines & Await

Use `await` for asynchronous operations and waiting.

### Wait for Signal

```gdscript
func play_animation():
    $AnimationPlayer.play("attack")
    await $AnimationPlayer.animation_finished
    print("Animation complete!")

func delayed_action():
    await get_tree().create_timer(1.5).timeout
    print("1.5 seconds later!")
```

### Wait for Multiple Signals

```gdscript
func wait_for_both():
    # Wait for either signal
    await $Timer.timeout
    # Continue after first signal
```

### Coroutine Return Values

```gdscript
func fetch_data() -> Array:
    var http = HTTPRequest.new()
    add_child(http)
    http.request("https://api.example.com/data")
    var result = await http.request_completed
    return result

func _ready():
    var data = await fetch_data()
    print(data)
```

---

## Input Handling

### Input Singleton (Polling)

```gdscript
func _process(delta):
    # Check action state (configured in Input Map)
    if Input.is_action_just_pressed("jump"):
        jump()

    if Input.is_action_pressed("fire"):
        fire_weapon()

    # Get axis input (-1 to 1)
    var horizontal = Input.get_axis("move_left", "move_right")
    var vertical = Input.get_axis("move_up", "move_down")
    var direction = Vector2(horizontal, vertical).normalized()

    # Get analog stick vector directly
    var stick = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = stick * SPEED
```

### Event-Based Input

```gdscript
func _input(event):
    # Keyboard
    if event is InputEventKey:
        if event.keycode == KEY_ESCAPE and event.pressed:
            get_tree().quit()
        if event.keycode == KEY_SPACE and event.pressed:
            jump()

    # Mouse
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            print("Clicked at: ", event.position)

    if event is InputEventMouseMotion:
        look_at(get_global_mouse_position())

    # Action
    if event.is_action_pressed("pause"):
        toggle_pause()

func _unhandled_input(event):
    # Only receives input NOT consumed by GUI
    if event.is_action_pressed("ui_accept"):
        print("Accept action")
```

### Mouse Position

```gdscript
func get_aim_direction():
    return (get_global_mouse_position() - global_position).normalized()
```

---

## Node Lifecycle

```gdscript
extends Node

# Called when node enters scene tree
func _ready():
    print("Node is ready!")
    # Add child dynamically
    var child = Node2D.new()
    child.name = "DynamicChild"
    add_child(child)
    # Add to group
    add_to_group("enemies")

# Called every frame
func _process(delta):
    pass  # Game logic

# Called at fixed intervals (physics)
func _physics_process(delta):
    pass  # Physics logic

# Handle input events
func _input(event):
    if event is InputEventKey and event.pressed:
        print("Key pressed: ", event.keycode)

# Handle unhandled input (after GUI)
func _unhandled_input(event):
    if event.is_action_pressed("pause"):
        toggle_pause()

# Called when node exits scene tree
func _exit_tree():
    print("Node exiting tree")
```

---

## Animation

### AnimationPlayer

```gdscript
@onready var animation_player = $AnimationPlayer

func _ready():
    animation_player.animation_finished.connect(_on_animation_finished)
    animation_player.play("idle")

func _on_animation_finished(anim_name):
    match anim_name:
        "death":
            queue_free()
        "attack":
            animation_player.play("idle")

func play_attack():
    animation_player.play("attack")
    await animation_player.animation_finished
    animation_player.play("idle")

func set_speed(speed: float):
    animation_player.speed_scale = speed
```

### Create Animation in Code

```gdscript
func create_animation():
    var animation = Animation.new()
    animation.length = 1.0
    animation.loop_mode = Animation.LOOP_LINEAR

    # Add position track
    var track_idx = animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(track_idx, "Sprite2D:position")
    animation.track_insert_key(track_idx, 0.0, Vector2(0, 0))
    animation.track_insert_key(track_idx, 0.5, Vector2(0, -20))
    animation.track_insert_key(track_idx, 1.0, Vector2(0, 0))

    # Add to library
    var library = AnimationLibrary.new()
    library.add_animation("bounce", animation)
    $AnimationPlayer.add_animation_library("", library)
```

---

## Timers

```gdscript
@onready var timer = $Timer

func _ready():
    # Configure in code
    timer.wait_time = 1.0
    timer.one_shot = true  # Only fire once
    timer.autostart = true  # Start automatically
    timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
    print("Timer finished!")

# One-shot timer without Timer node
func delayed_action():
    await get_tree().create_timer(1.5).timeout
    print("1.5 seconds later!")

# Pause-aware timer
func create_pausable_timer(duration: float):
    var timer = Timer.new()
    timer.wait_time = duration
    timer.one_shot = true
    timer.process_callback = Timer.TIMER_PROCESS_IDLE  # Pauses with game
    add_child(timer)
    timer.start()
    await timer.timeout
    timer.queue_free()
```

---

## Tween

Lightweight procedural animations without keyframe overhead.

### Sequential Tween

```gdscript
func animate_sprite():
    var tween = create_tween()

    # Chain animations (sequential)
    tween.tween_property($Sprite2D, "modulate", Color.RED, 0.5)
    tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.5)
    tween.tween_property($Sprite2D, "position", Vector2(200, 100), 1.0)

    # Callback at end
    tween.tween_callback(func(): print("Done!"))
```

### Parallel Tween

```gdscript
func animate_parallel():
    var tween = create_tween().set_parallel(true)

    # These run simultaneously
    tween.tween_property($Sprite2D, "position", Vector2(300, 200), 1.0)
    tween.tween_property($Sprite2D, "rotation", TAU, 1.0)
    tween.tween_property($Sprite2D, "scale", Vector2(2, 2), 1.0)

    # Chain after parallel completes
    tween.chain().tween_property($Sprite2D, "scale", Vector2(1, 1), 0.5)
```

### Easing and Transitions

```gdscript
func animate_with_easing():
    var tween = create_tween()

    # Bounce easing
    tween.tween_property($Sprite2D, "position:y", 400.0, 1.0)\
        .set_trans(Tween.TRANS_BOUNCE)\
        .set_ease(Tween.EASE_OUT)

    # Elastic easing
    tween.tween_property($Sprite2D, "position:y", 100.0, 0.5)\
        .set_trans(Tween.TRANS_ELASTIC)\
        .set_ease(Tween.EASE_OUT)
```

### Method Tween

```gdscript
func animate_method():
    var tween = create_tween()
    # Animate using a method call
    tween.tween_method(set_health, 100.0, 0.0, 2.0)

func set_health(value: float):
    $HealthBar.value = value
```

### Loop Tween

```gdscript
func loop_animation():
    var tween = create_tween().set_loops()  # Infinite loops
    tween.tween_property($Sprite2D, "rotation", TAU, 2.0).from(0.0)
```

---

## CharacterBody2D Movement

### Basic Movement with Gravity

```gdscript
extends CharacterBody2D

@export var SPEED = 400.0
@export var JUMP_VELOCITY = -400.0
@export var ACCELERATION = 1500.0
@export var FRICTION = 2000.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
    # Apply gravity
    if not is_on_floor():
        velocity.y += gravity * delta

    # Handle jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Get input direction
    var direction = Input.get_axis("move_left", "move_right")

    if direction:
        # Accelerate
        velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
    else:
        # Apply friction
        velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

    # Move and handle collisions
    move_and_slide()

    # Check collisions
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        if collider.is_in_group("enemies"):
            take_damage(10)
```

### Coyote Time and Jump Buffer

```gdscript
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

func _physics_process(delta):
    # Update timers
    if is_on_floor():
        coyote_timer = coyote_time
    else:
        coyote_timer -= delta

    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = jump_buffer_time
    else:
        jump_buffer_timer -= delta

    # Jump with buffer and coyote time
    if jump_buffer_timer > 0 and coyote_timer > 0:
        velocity.y = JUMP_VELOCITY
        jump_buffer_timer = 0
        coyote_timer = 0

    # Variable jump height
    if Input.is_action_just_released("jump") and velocity.y < JUMP_VELOCITY / 2:
        velocity.y = JUMP_VELOCITY / 2

    move_and_slide()
```

---

## Control & UI

### Control Node Basics

```gdscript
extends Control

func _ready():
    # Set anchors for responsive layout
    anchor_left = 0.0
    anchor_top = 0.0
    anchor_right = 1.0
    anchor_bottom = 1.0

    # Minimum size
    custom_minimum_size = Vector2(200, 100)

    # Focus settings
    focus_mode = Control.FOCUS_ALL

    # Mouse filter
    mouse_filter = Control.MOUSE_FILTER_STOP

# GUI-specific input
func _gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            print("Clicked at: ", event.position)
            accept_event()  # Consume the event
```

### Drag and Drop

```gdscript
func _get_drag_data(at_position):
    var preview = Label.new()
    preview.text = "Dragging!"
    set_drag_preview(preview)
    return {"type": "my_data", "value": 42}

func _can_drop_data(at_position, data):
    return data is Dictionary and data.get("type") == "my_data"

func _drop_data(at_position, data):
    print("Dropped: ", data.value)
```

### Custom Drawing

```gdscript
func _draw():
    draw_rect(Rect2(0, 0, size.x, size.y), Color.BLUE, false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(10, 30), "Custom Draw")

func update_display():
    queue_redraw()  # Request _draw() to be called
```

---

## HTTPRequest

```gdscript
extends Node

signal data_loaded(data)
signal request_failed(error)

func fetch_json(url: String):
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_request_completed.bind(http))
    var error = http.request(url)
    if error != OK:
        request_failed.emit(error)

func _on_request_completed(result, response_code, headers, body, http):
    http.queue_free()

    if result != HTTPRequest.RESULT_SUCCESS:
        request_failed.emit(result)
        return

    if response_code != 200:
        request_failed.emit(response_code)
        return

    var json = JSON.new()
    var parse_result = json.parse(body.get_string_from_utf8())
    if parse_result != OK:
        request_failed.emit(parse_result)
        return

    data_loaded.emit(json.get_data())
```

---

## Common Patterns

### Singleton (Autoload)

```gdscript
# GameManager.gd - Add as Autoload in Project Settings
extends Node

var score: int = 0
var lives: int = 3

signal score_changed(new_score)
signal player_died

func add_score(points: int):
    score += points
    score_changed.emit(score)

func player_death():
    lives -= 1
    player_died.emit()
```

### Object Pooling

```gdscript
# BulletPool.gd
extends Node

@export var bullet_scene: PackedScene
@export var pool_size: int = 20

var pool: Array = []

func _ready():
    for i in pool_size:
        var bullet = bullet_scene.instantiate()
        bullet.set_physics_process(false)
        bullet.hide()
        add_child(bullet)
        pool.append(bullet)

func get_bullet() -> Node:
    for bullet in pool:
        if not bullet.visible:
            bullet.show()
            bullet.set_physics_process(true)
            return bullet
    return null  # Pool exhausted

func return_bullet(bullet: Node):
    bullet.hide()
    bullet.set_physics_process(false)
```

### State Machine

```gdscript
class_name StateMachine
extends Node

var current_state: State
var states: Dictionary = {}

func _ready():
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.state_machine = self
    if states.size() > 0:
        current_state = states.values()[0]
        current_state.enter()

func _physics_process(delta):
    if current_state:
        current_state.physics_update(delta)

func change_state(new_state_name: String):
    if not states.has(new_state_name.to_lower()):
        return
    if current_state:
        current_state.exit()
    current_state = states[new_state_name.to_lower()]
    current_state.enter()

class_name State
extends Node

var state_machine: StateMachine

func enter(): pass
func exit(): pass
func physics_update(_delta): pass
```

---

## Best Practices Summary

1. **Cache node references** with `@onready` or `@export`
2. **Use signals** for communication between nodes
3. **Avoid `get_parent()`** - use dependency injection
4. **Use `await`** for asynchronous operations
5. **Check `is_on_floor()`** before jumping
6. **Use `move_and_slide()`** for physics
7. **Use Tween** for simple animations, AnimationPlayer for complex
8. **Use Timer nodes** for repeated events, `create_timer()` for one-shot
9. **Use groups** for batch operations on similar nodes
10. **Use Object pooling** for frequently instantiated objects