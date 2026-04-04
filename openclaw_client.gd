@tool
class_name OpenClawClient
extends RefCounted

# OpenClaw Gateway Client
# Handles communication with OpenClaw's LLM gateway

const DEFAULT_URL = "http://localhost:18789"
const DEFAULT_MODEL = "ollama/kimi-k2.5:cloud"

var openclaw_url: String = DEFAULT_URL
var current_model: String = DEFAULT_MODEL
var api_token: String = ""

var _http_request: HTTPRequest
var _callback: Callable

func _init():
	_http_request = HTTPRequest.new()

func set_url(url: String):
	openclaw_url = url

func set_model(model: String):
	current_model = model

func set_token(token: String):
	api_token = token

func chat(system_prompt: String, messages: Array, callback: Callable) -> void:
	_callback = callback
	
	var url = openclaw_url + "/v1/chat/completions"
	
	var full_messages = [{"role": "system", "content": system_prompt}]
	full_messages.append_array(messages)
	
	var body = {
		"model": current_model,
		"messages": full_messages,
		"temperature": 0.7,
		"max_tokens": 4096
	}
	
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	
	if api_token != "":
		headers.append("Authorization: Bearer " + api_token)
	
	var err = _http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		callback.call({"success": false, "error": "Failed to send request"})

func chat_stream(system_prompt: String, messages: Array, callback: Callable) -> void:
	# TODO: Implement streaming
	chat(system_prompt, messages, callback)

func _on_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		_callback.call({
			"success": false,
			"error": "HTTP error: %d" % response_code
		})
		return
	
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		_callback.call({
			"success": false,
			"error": "Failed to parse response"
		})
		return
	
	var response = json.data
	if response.has("choices") and response.choices.size() > 0:
		var content = response.choices[0].message.content
		_callback.call({
			"success": true,
			"content": content,
			"model": response.model if response.has("model") else current_model
		})
	else:
		_callback.call({
			"success": false,
			"error": "Empty response from model"
		})

# Fetch available models from OpenClaw
func fetch_models(callback: Callable) -> void:
	var url = openclaw_url + "/v1/models"
	var headers = ["Content-Type: application/json"]
	
	if api_token != "":
		headers.append("Authorization: Bearer " + api_token)
	
	_http_request.request_completed.connect(_on_models_response.bind(callback))
	var err = _http_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		callback.call({"success": false, "error": "Failed to fetch models"})

func _on_models_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, callback: Callable):
	if response_code != 200:
		callback.call({"success": false, "error": "HTTP error: %d" % response_code})
		return
	
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		callback.call({"success": false, "error": "Failed to parse response"})
		return
	
	var response = json.data
	var models = []
	
	if response.has("data"):
		for model in response.data:
			if model.has("id"):
				models.append(model.id)
	
	callback.call({
		"success": true,
		"models": models
	})

# Apply code changes to a script
func apply_code_to_script(script_path: String, code: String, callback: Callable) -> void:
	var script = load(script_path)
	if script == null:
		callback.call({"success": false, "error": "Failed to load script: " + script_path})
		return
	
	# This would need to be implemented with EditorInterface
	# For now, just return the code
	callback.call({
		"success": true,
		"script_path": script_path,
		"code": code,
		"message": "Code ready to apply. Use EditorInterface to edit the script."
	})

# Create a new node in the scene
func create_node(parent_path: String, node_type: String, node_name: String, callback: Callable) -> void:
	var parent = _get_node_by_path(parent_path)
	if parent == null:
		callback.call({"success": false, "error": "Parent node not found: " + parent_path})
		return
	
	var node_class = ClassDB.instantiate(node_type)
	if node_class == null:
		callback.call({"success": false, "error": "Unknown node type: " + node_type})
		return
	
	var new_node = node_class
	new_node.name = node_name
	parent.add_child(new_node)
	new_node.owner = EditorInterface.get_edited_scene_root()
	
	callback.call({
		"success": true,
		"node_name": node_name,
		"node_type": node_type,
		"parent_path": parent_path
	})

func _get_node_by_path(path: String) -> Node:
	var root = EditorInterface.get_edited_scene_root()
	if path == "" or path == ".":
		return root
	return root.get_node(path)