# EditorPlugin

**Inherits:** Node < Object

**Inherited By:** GridMapEditorPlugin

Used by the editor to extend its functionality.

## Description

Plugins are used by the editor to extend functionality. The most common types of plugins are those which edit a given node or resource type, import plugins and export plugins.

## Key Methods for godotclaw

### Scene Access
```gdscript
# Get the currently edited scene root
var scene_root = EditorInterface.get_edited_scene_root()

# Get selected nodes
var selection = EditorInterface.get_selection()
var selected_nodes = selection.get_selected_nodes()

# Get the script editor
var script_editor = EditorInterface.get_script_editor()
var current_script = script_editor.get_current_script()
```

### Adding UI
```gdscript
# Add a dock panel (godotclaw chat interface)
func _enter_tree():
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock_panel)

func _exit_tree():
    remove_control_from_docks(dock_panel)
```

### Dock Slots
- `DOCK_SLOT_LEFT_UL` - Left dock, upper-left
- `DOCK_SLOT_LEFT_BL` - Left dock, bottom-left
- `DOCK_SLOT_LEFT_UR` - Left dock, upper-right
- `DOCK_SLOT_LEFT_BR` - Left dock, bottom-right
- `DOCK_SLOT_RIGHT_UL` - Right dock, upper-left (recommended for godotclaw)
- `DOCK_SLOT_RIGHT_BL` - Right dock, bottom-left
- `DOCK_SLOT_RIGHT_UR` - Right dock, upper-right
- `DOCK_SLOT_RIGHT_BR` - Right dock, bottom-right

## Virtual Methods

### _enter_tree()
Called when the plugin is enabled. Use this to set up your plugin.

### _exit_tree()
Called when the plugin is disabled. Clean up here.

### _handles(object)
Return true if this plugin handles the given object type.

### _edit(object)
Called when an object is selected for editing.

### _make_visible(visible)
Called when the plugin should show/hide its UI.

### _apply_changes()
Called when the editor wants to save changes.

### _get_plugin_name()
Return the display name for this plugin.

### _get_plugin_icon()
Return an icon for this plugin.

## Useful Methods

### add_control_to_dock(slot, control)
Add a control to a dock slot.

### add_control_to_bottom_panel(control, title)
Add a control to the bottom panel (like Output, Debugger).

### add_tool_menu_item(name, callable)
Add a menu item to the Tools menu.

### add_autoload_singleton(name, path)
Add an autoload singleton to the project.

### edit_resource(resource)
Open a resource in the editor.

### open_scene_from_path(path)
Open a scene file.

### save_scene()
Save the current scene.

## Example: godotclaw Plugin Structure

```gdscript
# godotclaw/plugin.gd
@tool
extends EditorPlugin

var dock_panel: Control
var openclaw_client: OpenClawClient

func _enter_tree():
    # Create dock panel
    dock_panel = preload("res://addons/godotclaw/ui/dock_panel.tscn").instantiate()
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock_panel)
    
    # Initialize OpenClaw client
    openclaw_client = OpenClawClient.new()
    openclaw_client.openclaw_url = "http://localhost:18789"
    
    # Connect to selection changes
    EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

func _exit_tree():
    remove_control_from_docks(dock_panel)
    dock_panel.queue_free()

func _on_selection_changed():
    var selected = EditorInterface.get_selection().get_selected_nodes()
    if selected.size() > 0:
        dock_panel.update_context(selected[0])

func _apply_changes():
    # Save any pending changes
    pass
```

## Getting Scene Context

```gdscript
func get_scene_context() -> Dictionary:
    var context = {}
    
    # Get scene root
    var root = EditorInterface.get_edited_scene_root()
    if root:
        context["scene_name"] = root.name
        context["scene_path"] = root.scene_file_path
        
        # Get all nodes
        var all_nodes = root.find_children("*")
        context["node_count"] = all_nodes.size()
        
        # Get node types
        var node_types = {}
        for node in all_nodes:
            var type = node.get_class()
            node_types[type] = node_types.get(type, 0) + 1
        context["node_types"] = node_types
    
    # Get selected nodes
    var selection = EditorInterface.get_selection().get_selected_nodes()
    if selection.size() > 0:
        context["selected"] = []
        for node in selection:
            context["selected"].append({
                "name": node.name,
                "type": node.get_class(),
                "path": node.get_path(),
                "script": node.script.resource_path if node.script else null
            })
    
    # Get open script
    var script_editor = EditorInterface.get_script_editor()
    var current_script = script_editor.get_current_script()
    if current_script:
        context["open_script"] = {
            "path": current_script.resource_path,
            "source": current_script.source_code
        }
    
    return context
```

## More Information

- [Official Docs](https://docs.godotengine.org/en/stable/classes/class_editorplugin.html)
- [Editor Plugins Tutorial](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/index.html)