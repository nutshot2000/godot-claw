## Player Controller (CharacterBody2D)
## A basic 2D player controller with movement and jump

extends CharacterBody2D

## Movement speed in pixels per second
@export var speed: float = 200.0

## Jump velocity in pixels per second
@export var jump_velocity: float = -400.0

## Gravity scale (multiplies ProjectSettings gravity)
@export var gravity_scale: float = 1.0

## Maximum fall speed
@export var max_fall_speed: float = 600.0

## Acceleration for ground movement
@export var acceleration: float = 1500.0

## Deceleration for ground movement
@export var deceleration: float = 2000.0

## Acceleration for air movement
@export var air_acceleration: float = 800.0

## Coyote time (seconds after leaving ground before jump is disabled)
@export var coyote_time: float = 0.1

## Jump buffer time (seconds to remember jump input)
@export var jump_buffer_time: float = 0.1

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * gravity_scale * delta
		velocity.y = min(velocity.y, max_fall_speed)
	
	# Update coyote time
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	# Update jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	# Handle jump
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0
	
	# Variable jump height (release early for lower jump)
	if Input.is_action_just_released("jump") and velocity.y < jump_velocity / 2:
		velocity.y = jump_velocity / 2
	
	# Get input direction
	var direction := Input.get_axis("move_left", "move_right")
	
	# Apply movement
	if direction != 0:
		# Accelerate
		var accel = acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
		
		# Flip sprite
		sprite.flip_h = direction < 0
	else:
		# Decelerate
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	# Update animation
	_update_animation(direction)
	
	# Move
	move_and_slide()

func _update_animation(direction: float) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			animation_player.play("jump")
		else:
			animation_player.play("fall")
	elif direction != 0:
		animation_player.play("run")
	else:
		animation_player.play("idle")

func get_gravity_value() -> float:
	return ProjectSettings.get_setting("physics/2d/default_gravity")