@tool
extends EditorPlugin

# godotclaw - AI Assistant for Godot
# Connects to OpenClaw gateway for LLM-powered game dev assistance

const PLUGIN_NAME = "godotclaw"
const PLUGIN_VERSION = "1.0.0"
const DEFAULT_OPENCLAW_URL = "http://localhost:18789"

var dock_panel: Control
var openclaw_client: HTTPRequest
var docs_index: Dictionary = {}
var conversation_history: Array = []

# UI References
var chat_input: TextEdit
var chat_output: RichTextLabel
var send_button: Button
var context_label: Label
var status_label: Label
var model_dropdown: OptionButton

# Settings
var openclaw_url: String = DEFAULT_OPENCLAW_URL
var current_model: String = ""

func _enter_tree():
	# Load docs index
	_load_docs_index()
	
	# Create dock panel
	dock_panel = _create_ui()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock_panel)
	
	# Initialize HTTP client for OpenClaw
	openclaw_client = HTTPRequest.new()
	dock_panel.add_child(openclaw_client)
	openclaw_client.request_completed.connect(_on_openclaw_response)
	
	# Connect to selection changes
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	
	# Update context on ready
	_update_context()
	
	print("[godotclaw] Plugin loaded v%s" % PLUGIN_VERSION)

func _exit_tree():
	remove_control_from_docks(dock_panel)
	if dock_panel:
		dock_panel.queue_free()
	print("[godotclaw] Plugin unloaded")

func _create_ui() -> Control:
	var panel = VBoxContainer.new()
	panel.name = "godotclaw"
	panel.custom_minimum_size = Vector2(350, 500)
	
	# Header
	var header = HBoxContainer.new()
	var title = Label.new()
	title.text = "🤖 godotclaw"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)
	
	var settings_btn = Button.new()
	settings_btn.text = "⚙️"
	settings_btn.tooltip_text = "Settings"
	settings_btn.pressed.connect(_show_settings)
	header.add_child(settings_btn)
	
	panel.add_child(header)
	
	# Model dropdown
	var model_row = HBoxContainer.new()
	model_dropdown = OptionButton.new()
	model_dropdown.tooltip_text = "Select model"
	_populate_models()
	model_row.add_child(model_dropdown)
	panel.add_child(model_row)
	
	# Context label
	context_label = Label.new()
	context_label.text = "Context: No scene loaded"
	context_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	context_label.custom_minimum_size.y = 60
	panel.add_child(context_label)
	
	# Chat output
	chat_output = RichTextLabel.new()
	chat_output.bbcode_enabled = true
	chat_output.scroll_following = true
	chat_output.custom_minimum_size.y = 300
	chat_output.add_theme_stylebox_override("normal", _get_output_style())
	panel.add_child(chat_output)
	
	# Chat input
	chat_input = TextEdit.new()
	chat_input.placeholder_text = "Ask about Godot, GDScript, your project..."
	chat_input.custom_minimum_size.y = 80
	chat_input.text_changed.connect(_on_input_changed)
	panel.add_child(chat_input)
	
	# Button row
	var button_row = HBoxContainer.new()
	
	send_button = Button.new()
	send_button.text = "Send"
	send_button.pressed.connect(_send_message)
	button_row.add_child(send_button)
	
	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_clear_chat)
	button_row.add_child(clear_btn)
	
	var context_btn = Button.new()
	context_btn.text = "📄 Context"
	context_btn.tooltip_text = "View full scene context"
	context_btn.pressed.connect(_show_context)
	button_row.add_child(context_btn)
	
	panel.add_child(button_row)
	
	# Status label
	status_label = Label.new()
	status_label.text = "Ready"
	panel.add_child(status_label)
	
	# Welcome message
	_add_assistant_message("[b]Welcome to godotclaw![/b]\n\nI can help you with:\n• GDScript coding\n• Scene setup\n• Node configuration\n• Godot best practices\n\nI can see your current scene and selected nodes. Just ask!")

	return panel

func _get_output_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _populate_models():
	model_dropdown.clear()
	# Will be populated from OpenClaw when connected
	model_dropdown.add_item("Loading models...")
	_fetch_models()

func _fetch_models():
	# TODO: Fetch available models from OpenClaw
	pass

func _load_docs_index():
	# Load documentation index from docs folder
	var docs_path = get_script().resource_path.get_base_dir() + "/docs"
	var dir = DirAccess.open(docs_path)
	if dir:
		_index_docs_recursive(dir, docs_path)

func _index_docs_recursive(dir: DirAccess, base_path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var sub_dir = DirAccess.open(base_path + "/" + file_name)
			if sub_dir:
				_index_docs_recursive(sub_dir, base_path + "/" + file_name)
		elif file_name.ends_with(".md"):
			var full_path = base_path + "/" + file_name
			var topic = file_name.replace(".md", "")
			docs_index[topic.to_lower()] = full_path
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_selection_changed():
	_update_context()

func _update_context():
	var context = get_scene_context()
	var context_text = ""
	
	if context.has("scene_name"):
		context_text = "Scene: %s" % context.scene_name
	
	if context.has("selected") and context.selected.size() > 0:
		var sel = context.selected[0]
		context_text += "\nSelected: %s (%s)" % [sel.name, sel.type]
		if sel.has("script"):
			context_text += "\nScript: %s" % sel.script.get_file()
	
	if context.has("open_script"):
		context_text += "\nEditing: %s" % context.open_script.path.get_file()
	
	if context_text == "":
		context_text = "Context: No scene loaded"
	
	context_label.text = context_text

func get_scene_context() -> Dictionary:
	var context = {}
	
	# Get scene root
	var root = EditorInterface.get_edited_scene_root()
	if root:
		context["scene_name"] = root.name
		context["scene_path"] = root.scene_file_path if root.scene_file_path else "unsaved"
		
		# Count nodes by type
		var all_nodes = root.find_children("*", "", true, false)
		var node_types = {}
		for node in all_nodes:
			var type = node.get_class()
			node_types[type] = node_types.get(type, 0) + 1
		context["node_types"] = node_types
		context["node_count"] = all_nodes.size()
	
	# Get selected nodes
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.size() > 0:
		context["selected"] = []
		for node in selection:
			var node_info = {
				"name": node.name,
				"type": node.get_class(),
				"path": str(node.get_path())
			}
			if node.get_script():
				node_info["script"] = node.get_script().resource_path
			context["selected"].append(node_info)
	
	# Get open script
	var script_editor = EditorInterface.get_script_editor()
	var current_script = script_editor.get_current_script()
	if current_script:
		context["open_script"] = {
			"path": current_script.resource_path,
			"source": current_script.source_code
		}
	
	# Get project info
	context["project_name"] = ProjectSettings.get_setting("application/config/name")
	
	return context

func _on_input_changed():
	# Auto-resize input
	var lines = chat_input.get_line_count()
	chat_input.custom_minimum_size.y = min(80 + (lines - 1) * 20, 200)

func _send_message():
	var prompt = chat_input.text.strip_edges()
	if prompt.is_empty():
		return
	
	# Add user message to chat
	_add_user_message(prompt)
	chat_input.text = ""
	status_label.text = "Thinking..."
	send_button.disabled = true
	
	# Build request
	var context = get_scene_context()
	var docs = _search_docs(prompt)
	
	var system_prompt = _build_system_prompt(context, docs)
	var messages = conversation_history.duplicate()
	messages.append({"role": "user", "content": prompt})
	
	# Send to OpenClaw
	_send_to_openclaw(system_prompt, messages, prompt)

func _build_system_prompt(context: Dictionary, relevant_docs: String) -> String:
	var prompt = """You are godotclaw, an AI assistant integrated into Godot 4.

You help users with:
- GDScript coding and debugging
- Node setup and configuration
- Scene architecture
- Godot best practices
- Game development patterns

You have access to:
- The current scene context (nodes, structure, properties)
- The currently selected node(s)
- Any open script in the script editor
- The Godot documentation

When generating code:
- Use GDScript syntax (Godot 4.x)
- Follow Godot naming conventions
- Include proper type hints
- Reference the correct node paths from the context

When modifying scenes:
- Describe what you want to create/change
- Ask for confirmation before making changes
- Use the exact node names from context

Current scene context:
"""
	
	prompt += JSON.stringify(context, "  ")
	
	if relevant_docs != "":
		prompt += "\n\nRelevant documentation:\n" + relevant_docs
	
	return prompt

func _search_docs(query: String) -> String:
	var keywords = query.to_lower().split(" ")
	var results = []
	
	for keyword in keywords:
		if docs_index.has(keyword):
			var file = FileAccess.open(docs_index[keyword], FileAccess.READ)
			if file:
				var content = file.get_as_text()
				# Get first 1000 chars
				results.append("## %s\n%s..." % [keyword, content.left(1000)])
	
	if results.size() > 0:
		return "\n\n".join(results)
	return ""

func _send_to_openclaw(system_prompt: String, messages: Array, original_prompt: String):
	var url = openclaw_url + "/v1/chat/completions"
	
	var body = {
		"model": current_model,
		"messages": [{"role": "system", "content": system_prompt}] + messages,
		"temperature": 0.7,
		"max_tokens": 4096
	}
	
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	
	var err = openclaw_client.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		_add_assistant_message("[color=red]Error: Failed to connect to OpenClaw[/color]")
		status_label.text = "Error"
		send_button.disabled = false

func _on_openclaw_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	send_button.disabled = false
	
	if response_code != 200:
		_add_assistant_message("[color=red]Error: OpenClaw returned code %d[/color]" % response_code)
		status_label.text = "Error"
		return
	
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		_add_assistant_message("[color=red]Error: Failed to parse response[/color]")
		status_label.text = "Error"
		return
	
	var response = json.data
	if response.has("choices") and response.choices.size() > 0:
		var content = response.choices[0].message.content
		_add_assistant_message(content)
		conversation_history.append({"role": "assistant", "content": content})
	else:
		_add_assistant_message("[color=red]Error: Empty response[/color]")
	
	status_label.text = "Ready"

func _add_user_message(text: String):
	chat_output.append_text("[color=#4fc3f7][b]You:[/b][/color]\n")
	chat_output.append_text(text + "\n\n")
	conversation_history.append({"role": "user", "content": text})

func _add_assistant_message(text: String):
	chat_output.append_text("[color=#81c784][b]godotclaw:[/b][/color]\n")
	# Parse markdown-like formatting
	var formatted = text
	formatted = formatted.replace("```gdscript", "[code]")
	formatted = formatted.replace("```", "[/code]")
	formatted = formatted.replace("**", "[b]")
	formatted = formatted.replace("**", "[/b]")
	chat_output.append_text(formatted + "\n\n")

func _clear_chat():
	chat_output.clear()
	conversation_history.clear()
	_add_assistant_message("[b]Chat cleared.[/b]\n\nWhat can I help you with?")

func _show_context():
	var context = get_scene_context()
	var context_json = JSON.stringify(context, "  ")
	
	var popup = AcceptDialog.new()
	popup.dialog_text = "Scene Context"
	popup.add_child(Label.new())
	var label = popup.get_child(popup.get_child_count() - 1)
	label.text = context_json
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup.popup_centered(Vector2i(500, 400))

func _show_settings():
	var popup = AcceptDialog.new()
	popup.dialog_text = "Settings"
	
	var vbox = VBoxContainer.new()
	
	var url_label = Label.new()
	url_label.text = "OpenClaw URL:"
	vbox.add_child(url_label)
	
	var url_input = LineEdit.new()
	url_input.text = openclaw_url
	vbox.add_child(url_input)
	
	popup.add_child(vbox)
	popup.popup_centered(Vector2i(300, 200))