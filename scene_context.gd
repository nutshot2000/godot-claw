class_name SceneContext
extends RefCounted

# Scene Context Gatherer for godotclaw
# Collects information about the current scene for LLM context

signal context_updated(context: Dictionary)

var _last_context: Dictionary = {}

func get_full_context() -> Dictionary:
	var context = {}
	
	# Scene info
	context.merge(_get_scene_info())
	
	# Selected nodes
	context.merge(_get_selection_info())
	
	# Script info
	context.merge(_get_script_info())
	
	# Project info
	context.merge(_get_project_info())
	
	_last_context = context
	return context

func get_minimal_context() -> Dictionary:
	var context = {}
	
	context.merge(_get_scene_info_minimal())
	context.merge(_get_selection_info_minimal())
	
	return context

func _get_scene_info() -> Dictionary:
	var info = {}
	var root = EditorInterface.get_edited_scene_root()
	
	if root == null:
		info["scene"] = {"loaded": false}
		return info
	
	info["scene"] = {
		"loaded": true,
		"name": root.name,
		"path": root.scene_file_path if root.scene_file_path else "unsaved",
		"type": root.get_class(),
		"child_count": root.get_child_count()
	}
	
	# Get all nodes
	var all_nodes = root.find_children("*", "", true, false)
	
	# Count by type
	var node_types = {}
	for node in all_nodes:
		var type = node.get_class()
		node_types[type] = node_types.get(type, 0) + 1
	
	info["scene"]["node_types"] = node_types
	info["scene"]["total_nodes"] = all_nodes.size() + 1  # +1 for root
	
	# Get node tree structure (limited depth)
	info["scene"]["tree"] = _get_node_tree(root, 3)
	
	return info

func _get_scene_info_minimal() -> Dictionary:
	var info = {}
	var root = EditorInterface.get_edited_scene_root()
	
	if root == null:
		info["scene"] = {"loaded": false}
		return info
	
	info["scene"] = {
		"loaded": true,
		"name": root.name,
		"type": root.get_class(),
		"child_count": root.get_child_count()
	}
	
	return info

func _get_selection_info() -> Dictionary:
	var info = {}
	var selection = EditorInterface.get_selection()
	var selected_nodes = selection.get_selected_nodes()
	
	if selected_nodes.is_empty():
		info["selection"] = {"has_selection": false}
		return info
	
	info["selection"] = {
		"has_selection": true,
		"count": selected_nodes.size(),
		"nodes": []
	}
	
	for node in selected_nodes:
		var node_info = {
			"name": node.name,
			"type": node.get_class(),
			"path": str(node.get_path())
		}
		
		# Get properties
		var props = node.get_property_list()
		var interesting_props = {}
		
		for prop in props:
			var prop_name = prop.name
			# Skip internal properties
			if prop_name.begins_with("_") or prop_name in ["script", "owner"]:
				continue
			
			# Get value
			var value = node.get(prop_name)
			if value != null:
				# Limit value representation
				if value is Resource:
					value = value.resource_path if value.resource_path else str(value)
				elif value is Node:
					value = value.name
				elif value is Vector2 or value is Vector3:
					value = str(value)
				elif value is Color:
					value = str(value)
				
				interesting_props[prop_name] = value
		
		node_info["properties"] = interesting_props
		
		# Get script info
		var script = node.get_script()
		if script:
			node_info["script"] = {
				"path": script.resource_path,
				"has_script": true
			}
		else:
			node_info["script"] = {"has_script": false}
		
		# Get children
		var children = []
		for child in node.get_children():
			children.append({
				"name": child.name,
				"type": child.get_class()
			})
		node_info["children"] = children
		
		info["selection"]["nodes"].append(node_info)
	
	return info

func _get_selection_info_minimal() -> Dictionary:
	var info = {}
	var selection = EditorInterface.get_selection()
	var selected_nodes = selection.get_selected_nodes()
	
	if selected_nodes.is_empty():
		info["selection"] = {"has_selection": false}
		return info
	
	var first = selected_nodes[0]
	info["selection"] = {
		"has_selection": true,
		"name": first.name,
		"type": first.get_class()
	}
	
	return info

func _get_script_info() -> Dictionary:
	var info = {}
	var script_editor = EditorInterface.get_script_editor()
	var current_script = script_editor.get_current_script()
	
	if current_script == null:
		info["script"] = {"open": false}
		return info
	
	info["script"] = {
		"open": true,
		"path": current_script.resource_path,
		"language": "gdscript",  # Assume GDScript for now
		"source_length": current_script.source_code.length()
	}
	
	# Get script content (limited)
	var source = current_script.source_code
	var lines = source.split("\n")
	
	# Extract function signatures
	var functions = []
	var func_regex = RegEx.new()
	func_regex.compile("^func\\s+(\\w+)\\s*\\(")
	
	for line in lines:
		var result = func_regex.search(line)
		if result:
			functions.append(result.get_string(1))
	
	info["script"]["functions"] = functions
	
	# Extract class variables
	var variables = []
	var var_regex = RegEx.new()
	var_regex.compile("^(?:var|@export)\\s+(\\w+)")
	
	for line in lines:
		var result = var_regex.search(line)
		if result:
			variables.append(result.get_string(1))
	
	info["script"]["variables"] = variables
	
	return info

func _get_project_info() -> Dictionary:
	var info = {}
	
	# Project settings
	info["project"] = {
		"name": ProjectSettings.get_setting("application/config/name", "Unnamed"),
		"version": ProjectSettings.get_setting("application/config/version", "1.0"),
		"godot_version": Engine.get_version_info().string
	}
	
	# Get main scene
	var main_scene = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene != "":
		info["project"]["main_scene"] = main_scene
	
	# Get autoloads
	var autoloads = []
	var props = ProjectSettings.get_property_list()
	for prop in props:
		if prop.name.begins_with("autoload/"):
			var autoload_name = prop.name.replace("autoload/", "")
			var autoload_path = ProjectSettings.get_setting(prop.name)
			autoloads.append({"name": autoload_name, "path": autoload_path})
	
	if autoloads.size() > 0:
		info["project"]["autoloads"] = autoloads
	
	return info

func _get_node_tree(node: Node, max_depth: int, current_depth: int = 0) -> Dictionary:
	if current_depth >= max_depth:
		return {}
	
	var tree = {
		"name": node.name,
		"type": node.get_class()
	}
	
	var children = []
	for child in node.get_children():
		var child_tree = _get_node_tree(child, max_depth, current_depth + 1)
		if !child_tree.is_empty():
			children.append(child_tree)
	
	if children.size() > 0:
		tree["children"] = children
	
	return tree

func get_node_script(node: Node) -> Dictionary:
	var result = {"has_script": false}
	
	var script = node.get_script()
	if script:
		result = {
			"has_script": true,
			"path": script.resource_path,
			"source": script.source_code
		}
	
	return result

func get_node_properties(node: Node, filter: String = "") -> Dictionary:
	var result = {}
	var props = node.get_property_list()
	
	for prop in props:
		var prop_name = prop.name
		
		# Filter
		if filter != "" and filter.to_lower() not in prop_name.to_lower():
			continue
		
		# Skip internal
		if prop_name.begins_with("_"):
			continue
		
		result[prop_name] = node.get(prop_name)
	
	return result

# Generate context summary for LLM prompt
func generate_context_summary() -> String:
	var context = get_full_context()
	var summary = ""
	
	# Scene
	if context.has("scene") and context.scene.loaded:
		summary += "Current Scene: %s (%s)\n" % [context.scene.name, context.scene.type]
		summary += "Path: %s\n" % context.scene.path
		summary += "Nodes: %d total\n" % context.scene.total_nodes
		
		# Node types
		if context.scene.has("node_types"):
			summary += "Node types: "
			var types = []
			for type in context.scene.node_types:
				types.append("%s x%d" % [type, context.scene.node_types[type]])
			summary += ", ".join(types) + "\n"
	
	# Selection
	if context.has("selection") and context.selection.has_selection:
		summary += "\nSelected Node: %s (%s)\n" % [context.selection.nodes[0].name, context.selection.nodes[0].type]
		
		var node = context.selection.nodes[0]
		if node.has("properties"):
			summary += "Properties:\n"
			for prop in node.properties:
				var val = node.properties[prop]
				summary += "  %s: %s\n" % [prop, str(val)]
		
		if node.script.has_script:
			summary += "Script: %s\n" % node.script.path
	
	# Script editor
	if context.has("script") and context.script.open:
		summary += "\nEditing Script: %s\n" % context.script.path
		summary += "Functions: %s\n" % ", ".join(context.script.functions)
	
	return summary