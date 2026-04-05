@tool
extends EditorPlugin

const PLUGIN_NAME = "godotclaw"
const PLUGIN_VERSION = "1.0.0"
const DEFAULT_OPENCLAW_URL = "http://localhost:18789"

var dock_panel: Control
var openclaw_client: HTTPRequest
var docs_index: Dictionary = {}
var conversation_history: Array = []

var chat_input: TextEdit
var chat_output: RichTextLabel
var send_button: Button
var context_label: Label
var status_label: Label
var model_dropdown: OptionButton

var openclaw_url: String = DEFAULT_OPENCLAW_URL
var current_model: String = ""

func _enter_tree():
    print("[godotclaw] Loading docs index...")
    _load_docs_index()
    print("[godotclaw] Creating UI...")
    dock_panel = _create_ui()
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock_panel)
    print("[godotclaw] UI created, adding HTTP client...")
    
    openclaw_client = HTTPRequest.new()
    dock_panel.add_child(openclaw_client)
    openclaw_client.request_completed.connect(_on_openclaw_response)
    
    EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
    _update_context()
    
    print("[godotclaw] Plugin loaded v%s" % PLUGIN_VERSION)

func _exit_tree():
    remove_control_from_docks(dock_panel)
    if dock_panel:
        dock_panel.queue_free()

func _create_ui() -> Control:
    var panel = VBoxContainer.new()
    panel.name = "godotclaw"
    panel.custom_minimum_size = Vector2(350, 500)
    
    var header = HBoxContainer.new()
    var title = Label.new()
    title.text = "godotclaw"
    title.add_theme_font_size_override("font_size", 16)
    header.add_child(title)
    
    var settings_btn = Button.new()
    settings_btn.text = "Settings"
    settings_btn.pressed.connect(_show_settings)
    header.add_child(settings_btn)
    panel.add_child(header)
    
    var model_row = HBoxContainer.new()
    model_dropdown = OptionButton.new()
    model_dropdown.tooltip_text = "Select model"
    model_dropdown.add_item("Default")
    model_row.add_child(model_dropdown)
    panel.add_child(model_row)
    
    context_label = Label.new()
    context_label.text = "Context: No scene loaded"
    context_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    context_label.custom_minimum_size.y = 60
    panel.add_child(context_label)
    
    chat_output = RichTextLabel.new()
    chat_output.bbcode_enabled = true
    chat_output.scroll_following = true
    chat_output.custom_minimum_size.y = 300
    panel.add_child(chat_output)
    
    chat_input = TextEdit.new()
    chat_input.custom_minimum_size.y = 80
    panel.add_child(chat_input)
    
    var button_row = HBoxContainer.new()
    send_button = Button.new()
    send_button.text = "Send"
    send_button.pressed.connect(_send_message)
    button_row.add_child(send_button)
    
    var clear_btn = Button.new()
    clear_btn.text = "Clear"
    clear_btn.pressed.connect(_clear_chat)
    button_row.add_child(clear_btn)
    panel.add_child(button_row)
    
    status_label = Label.new()
    status_label.text = "Ready"
    panel.add_child(status_label)
    
    _add_assistant_message("Welcome to godotclaw! I can help with GDScript, nodes, and your project.")
    
    return panel

func _load_docs_index():
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
            var topic = file_name.replace(".md", "")
            docs_index[topic.to_lower()] = base_path + "/" + file_name
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
    
    var root = EditorInterface.get_edited_scene_root()
    if root:
        context["scene_name"] = root.name
        context["scene_path"] = root.scene_file_path if root.scene_file_path else "unsaved"
        
        var all_nodes = root.find_children("*", "", true, false)
        var node_types = {}
        for node in all_nodes:
            var type = node.get_class()
            node_types[type] = node_types.get(type, 0) + 1
        context["node_types"] = node_types
        context["node_count"] = all_nodes.size()
    
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
    
    var script_editor = EditorInterface.get_script_editor()
    var current_script = script_editor.get_current_script()
    if current_script:
        context["open_script"] = {
            "path": current_script.resource_path,
            "source": current_script.source_code
        }
    
    context["project_name"] = ProjectSettings.get_setting("application/config/name")
    
    return context

func _send_message():
    var text = chat_input.get_text()
    var prompt = text.strip_edges()
    if prompt.length() == 0:
        return
    
    _add_user_message(prompt)
    chat_input.set_text("")
    status_label.text = "Thinking..."
    send_button.disabled = true
    
    var context = get_scene_context()
    var docs = _search_docs(prompt)
    var system_prompt = _build_system_prompt(context, docs)
    var messages = conversation_history.duplicate()
    messages.append({"role": "user", "content": prompt})
    
    _send_to_openclaw(system_prompt, messages, prompt)

func _build_system_prompt(context: Dictionary, relevant_docs: String) -> String:
    var prompt = "You are godotclaw, an AI assistant integrated into Godot 4.\n\n"
    prompt += "You help users with GDScript coding, node setup, scene architecture, and Godot best practices.\n\n"
    prompt += "You have access to the current scene context and pre-baked Godot documentation.\n\n"
    prompt += "Current scene context:\n"
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
                results.append("## %s\n%s..." % [keyword, content.left(1000)])
    
    if results.size() > 0:
        return "\n\n".join(results)
    return ""

func _send_to_openclaw(system_prompt: String, messages: Array, original_prompt: String):
    var url = openclaw_url + "/v1/chat/completions"
    
    var body = {
        "model": current_model if current_model != "" else "default",
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
    chat_output.append_text(text + "\n\n")

func _clear_chat():
    chat_output.clear()
    conversation_history.clear()
    _add_assistant_message("[b]Chat cleared.[/b]\n\nWhat can I help you with?")

func _show_settings():
    var popup = AcceptDialog.new()
    popup.dialog_text = "Settings\n\nOpenClaw URL: " + openclaw_url
    popup.popup_centered(Vector2i(300, 200))
    dock_panel.add_child(popup)