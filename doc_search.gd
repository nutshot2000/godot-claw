class_name DocSearch
extends RefCounted

# Documentation Search Engine for godotclaw
# Indexes and searches pre-baked Godot documentation

var docs_path: String
var index: Dictionary = {}
var content_cache: Dictionary = {}

func _init(path: String = "res://addons/godotclaw/docs/"):
	docs_path = path
	_index_docs()

func _index_docs():
	var dir = DirAccess.open(docs_path)
	if dir == null:
		push_error("[godotclaw] Failed to open docs directory: " + docs_path)
		return
	
	_index_recursive(dir, docs_path)
	print("[godotclaw] Indexed %d documents" % index.size())

func _index_recursive(dir: DirAccess, current_path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = current_path + file_name
		
		if dir.current_is_dir():
			var sub_dir = DirAccess.open(full_path)
			if sub_dir:
				_index_recursive(sub_dir, full_path + "/")
		elif file_name.ends_with(".md"):
			_index_file(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _index_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	var topic = file_path.replace(docs_path, "").replace(".md", "")
	
	# Extract keywords from content
	var keywords = _extract_keywords(content)
	
	# Store in index
	index[topic.to_lower()] = {
		"path": file_path,
		"keywords": keywords,
		"title": _extract_title(content),
		"summary": _extract_summary(content)
	}
	
	# Cache content for quick access
	content_cache[file_path] = content

func _extract_keywords(content: String) -> Array:
	var keywords = []
	
	# Extract code blocks
	var code_regex = RegEx.new()
	code_regex.compile("```[\\s\\S]*?```")
	for result in code_regex.search_all(content):
		var code = result.get_string()
		# Extract function names
		var func_regex = RegEx.new()
		func_regex.compile("func\\s+(\\w+)")
		for func_match in func_regex.search_all(code):
			keywords.append(func_match.get_string(1).to_lower())
	
	# Extract class names (Title Case)
	var class_regex = RegEx.new()
	class_regex.compile("\\b[A-Z][a-z]+[A-Z][a-zA-Z]*\\b")
	for result in class_regex.search_all(content):
		keywords.append(result.get_string().to_lower())
	
	# Common Godot keywords
	var godot_keywords = [
		"node", "scene", "script", "signal", "export", "ready", "process",
		"physics", "input", "collision", "sprite", "animation", "tween",
		"vector", "transform", "position", "rotation", "scale", "velocity",
		"character", "rigid", "area", "camera", "light", "mesh", "shader",
		"tilemap", "navigation", "multiplayer", "rpc", "resource"
	]
	
	for keyword in godot_keywords:
		if keyword.to_lower() in content.to_lower():
			keywords.append(keyword)
	
	return keywords

func _extract_title(content: String) -> String:
	var lines = content.split("\n")
	for line in lines:
		if line.begins_with("# "):
			return line.replace("# ", "").strip_edges()
	return "Untitled"

func _extract_summary(content: String) -> String:
	var lines = content.split("\n")
	var in_code_block = false
	var summary_lines = []
	
	for line in lines:
		if line.begins_with("```"):
			in_code_block = !in_code_block
			continue
		
		if !in_code_block and !line.begins_with("#") and line.strip_edges() != "":
			summary_lines.append(line)
			if summary_lines.size() >= 3:
				break
	
	return "\n".join(summary_lines)

func search(query: String, max_results: int = 5) -> Array:
	var results = []
	var query_lower = query.to_lower()
	var query_terms = query_lower.split(" ")
	
	# Score each document
	var scores = {}
	for topic in index:
		var doc = index[topic]
		var score = 0
		
		# Check if topic matches query
		if topic in query_lower:
			score += 10
		
		# Check keywords
		for term in query_terms:
			if term in doc.keywords:
				score += 5
		
		# Check title
		if query_lower in doc.title.to_lower():
			score += 8
		
		# Check summary
		if query_lower in doc.summary.to_lower():
			score += 3
		
		if score > 0:
			scores[topic] = score
	
	# Sort by score
	var sorted = scores.keys()
	sorted.sort_custom(func(a, b): return scores[a] > scores[b])
	
	# Get top results
	for i in range(min(max_results, sorted.size())):
		var topic = sorted[i]
		var doc = index[topic]
		var content = get_content(topic)
		
		results.append({
			"topic": topic,
			"title": doc.title,
			"score": scores[topic],
			"summary": doc.summary,
			"content": content.left(2000)  # First 2000 chars
		})
	
	return results

func get_content(topic: String) -> String:
	topic = topic.to_lower()
	
	if !index.has(topic):
		return ""
	
	var file_path = index[topic].path
	
	if content_cache.has(file_path):
		return content_cache[file_path]
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	
	var content = file.get_as_text()
	content_cache[file_path] = content
	return content

func get_topics() -> Array:
	return index.keys()

func get_topics_by_category() -> Dictionary:
	var categories = {}
	
	for topic in index:
		var parts = topic.split("/")
		var category = parts[0] if parts.size() > 1 else "general"
		
		if !categories.has(category):
			categories[category] = []
		
		categories[category].append({
			"topic": topic,
			"title": index[topic].title
		})
	
	return categories