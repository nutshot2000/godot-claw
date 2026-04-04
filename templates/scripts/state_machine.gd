## State Machine Pattern
## Generic state machine for game entities

class_name StateMachine
extends Node

## Emitted when transitioning to a new state
signal state_changed(old_state: String, new_state: String)

## Current state name
var current_state: String = ""

## Dictionary of state nodes {name: State}
var states: Dictionary = {}

## Reference to the owner entity
@export var owner_node: Node

func _ready() -> void:
	# Collect all state children
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.owner_node = owner_node
	
	# Enter first state
	if states.size() > 0:
		var first_state = states.keys()[0]
		_enter_state(first_state)

func _physics_process(delta: float) -> void:
	if current_state != "" and states.has(current_state):
		states[current_state].physics_update(delta)

func _process(delta: float) -> void:
	if current_state != "" and states.has(current_state):
		states[current_state].update(delta)

func change_state(new_state: String) -> void:
	new_state = new_state.to_lower()
	
	if new_state == current_state:
		return
	
	if not states.has(new_state):
		push_error("State '%s' not found" % new_state)
		return
	
	var old_state = current_state
	
	# Exit current state
	if current_state != "" and states.has(current_state):
		states[current_state].exit()
	
	# Enter new state
	current_state = new_state
	states[current_state].enter()
	
	state_changed.emit(old_state, new_state)

func _enter_state(state_name: String) -> void:
	current_state = state_name.to_lower()
	if states.has(current_state):
		states[current_state].enter()

func has_state(state_name: String) -> bool:
	return states.has(state_name.to_lower())

func get_current_state() -> State:
	if current_state != "" and states.has(current_state):
		return states[current_state]
	return null


## Base State Class
class State extends Node:
	## Reference to the state machine
	var state_machine: StateMachine
	
	## Reference to the owner entity
	var owner_node: Node
	
	## Called when entering this state
	func enter() -> void:
		pass
	
	## Called when exiting this state
	func exit() -> void:
		pass
	
	## Called every physics frame while in this state
	func physics_update(_delta: float) -> void:
		pass
	
	## Called every frame while in this state
	func update(_delta: float) -> void:
		pass
	
	## Helper to change state
	func change_state(new_state: String) -> void:
		state_machine.change_state(new_state)


## Example States for a Platformer Character
class IdleState extends State:
	func enter() -> void:
		if owner_node.has_node("AnimationPlayer"):
			owner_node.get_node("AnimationPlayer").play("idle")
	
	func physics_update(delta: float) -> void:
		# Check for movement input
		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			change_state("run")
		
		# Check for jump
		if Input.is_action_just_pressed("jump") and owner_node.is_on_floor():
			change_state("jump")

class RunState extends State:
	func enter() -> void:
		if owner_node.has_node("AnimationPlayer"):
			owner_node.get_node("AnimationPlayer").play("run")
	
	func physics_update(delta: float) -> void:
		var direction = Input.get_axis("move_left", "move_right")
		
		# Apply movement
		owner_node.velocity.x = direction * owner_node.speed
		
		# Check for state transitions
		if direction == 0:
			change_state("idle")
		
		if Input.is_action_just_pressed("jump") and owner_node.is_on_floor():
			change_state("jump")
		
		if not owner_node.is_on_floor():
			change_state("fall")

class JumpState extends State:
	func enter() -> void:
		owner_node.velocity.y = owner_node.jump_velocity
		if owner_node.has_node("AnimationPlayer"):
			owner_node.get_node("AnimationPlayer").play("jump")
	
	func physics_update(delta: float) -> void:
		# Apply gravity
		owner_node.velocity.y += owner_node.gravity * delta
		
		# Apply horizontal movement
		var direction = Input.get_axis("move_left", "move_right")
		owner_node.velocity.x = direction * owner_node.speed
		
		# Transition to fall when going down
		if owner_node.velocity.y > 0:
			change_state("fall")
		
		# Transition to idle when landing
		if owner_node.is_on_floor():
			change_state("idle")

class FallState extends State:
	func enter() -> void:
		if owner_node.has_node("AnimationPlayer"):
			owner_node.get_node("AnimationPlayer").play("fall")
	
	func physics_update(delta: float) -> void:
		# Apply gravity
		owner_node.velocity.y += owner_node.gravity * delta
		
		# Apply horizontal movement
		var direction = Input.get_axis("move_left", "move_right")
		owner_node.velocity.x = direction * owner_node.speed
		
		# Transition to idle when landing
		if owner_node.is_on_floor():
			change_state("idle")