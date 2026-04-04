## Singleton/Autoload Pattern
## Global manager for game state, events, and services

extends Node

## Signal bus for global events
signal game_started
signal game_paused(is_paused: bool)
signal level_loaded(level_name: String)
signal player_died
signal score_changed(new_score: int)

## Game state
var current_level: String = ""
var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

var is_paused: bool = false
var player_lives: int = 3

## Settings
var settings: Dictionary = {
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"vsync": true
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)

func load_level(level_name: String) -> void:
	current_level = level_name
	get_tree().change_scene_to_file("res://levels/%s.tscn" % level_name)
	level_loaded.emit(level_name)

func restart_level() -> void:
	if current_level != "":
		load_level(current_level)

func add_score(points: int) -> void:
	score += points

func reset_score() -> void:
	score = 0

func player_death() -> void:
	player_lives -= 1
	player_died.emit()
	
	if player_lives <= 0:
		game_over()
	else:
		restart_level()

func game_over() -> void:
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

func quit_game() -> void:
	_save_settings()
	get_tree().quit()

func _load_settings() -> void:
	var file = FileAccess.open("user://settings.save", FileAccess.READ)
	if file:
		var data = file.get_var()
		if data is Dictionary:
			settings.merge(data, true)
		file.close()
	
	_apply_settings()

func _save_settings() -> void:
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func _apply_settings() -> void:
	# Apply audio settings
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(settings.music_volume))
	
	# Apply display settings
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)

## Utility: Get a random element from an array
static func random_element(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi() % array.size()]

## Utility: Get a random point in a rectangle
static func random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		rect.position.x + randf() * rect.size.x,
		rect.position.y + randf() * rect.size.y
	)

## Utility: Check if a point is on screen
static func is_on_screen(point: Vector2) -> bool:
	var viewport = EditorInterface.get_editor_viewport_2d().get_viewport_rect()
	return viewport.has_point(point)