# godotclaw - AI Assistant for Godot

A Godot 4 plugin that connects to OpenClaw for AI-powered game development assistance.

## Features

- **Scene Context Awareness**: Automatically sees your current scene, selected nodes, and open scripts
- **Godot Docs Integration**: Pre-baked documentation for accurate answers
- **Code Generation**: Generate GDScript code that matches your project structure
- **Node Configuration**: Get help setting up nodes with correct properties

## Installation

1. Copy the `godotclaw` folder to your project's `addons/` directory
2. In Godot, go to **Project → Project Settings → Plugins**
3. Find `godotclaw` and enable it
4. The plugin panel will appear in the right dock

## Configuration

### OpenClaw Setup

godotclaw connects to OpenClaw's gateway (default: `http://localhost:18789`).

1. Make sure OpenClaw is running
2. In godotclaw, click ⚙️ Settings
3. Verify the URL matches your OpenClaw gateway
4. Select your preferred model from the dropdown

## Usage

### Basic Chat

1. Open a scene in Godot
2. Select a node or open a script
3. Type your question in the chat input
4. Press Send or Enter

### What You Can Ask

- **Coding**: "How do I make a player controller?"
- **Nodes**: "What properties does CharacterBody2D have?"
- **Debugging**: "Why is my player falling through the floor?"
- **Architecture**: "How should I structure my game manager?"

### Context Features

godotclaw automatically knows:

- Current scene name and structure
- Selected node(s) and their properties
- Open scripts in the editor
- Node hierarchy and types
- Project settings

Click **Context** to see what the AI knows about your scene.

## Documentation Included

- **GDScript**: Syntax, classes, signals, exports, typing
- **Nodes**: CharacterBody2D, RigidBody2D, Area2D, Sprite2D, Control, AnimationPlayer, TileMap, MeshInstance3D, Camera3D
- **Physics**: Movement, collisions, raycasts
- **Input**: Input singleton, actions, events
- **Animation**: Tween, AnimationPlayer
- **Navigation**: NavigationAgent2D, pathfinding
- **Multiplayer**: RPC system, peer management
- **Shaders**: ShaderMaterial, uniforms, GLSL
- **Editor**: EditorPlugin API for plugin development

## Architecture

```
godotclaw/
├── plugin.gd          # Main plugin (EditorPlugin)
├── plugin.cfg         # Plugin configuration
├── openclaw_client.gd # HTTP client for OpenClaw gateway
├── doc_search.gd      # Documentation search engine
├── scene_context.gd   # Scene context gatherer
├── ui/
│   └── chat_panel.tscn # Chat UI
├── docs/              # Pre-baked Godot documentation
│   ├── nodes/
│   ├── gdscript/
│   ├── physics/
│   ├── navigation/
│   ├── multiplayer/
│   ├── shaders/
│   └── editor/
└── templates/         # Code templates
    └── scripts/
        ├── player_controller_2d.gd
        ├── game_singleton.gd
        └── state_machine.gd
```

## API Reference

### SceneContext

```gdscript
# Get full context
var context = scene_context.get_full_context()

# Get minimal context (faster)
var context = scene_context.get_minimal_context()

# Get context summary for LLM
var summary = scene_context.generate_context_summary()
```

### DocSearch

```gdscript
# Search documentation
var results = doc_search.search("CharacterBody2D movement")

# Get full document
var content = doc_search.get_content("nodes/characterbody2d")

# List all topics
var topics = doc_search.get_topics()
```

### OpenClawClient

```gdscript
# Send chat request
client.chat(system_prompt, messages, callback)

# Fetch available models
client.fetch_models(callback)
```

## Troubleshooting

### "Failed to connect to OpenClaw"

1. Verify OpenClaw is running
2. Check the gateway URL (default: http://localhost:18789)
3. Check your firewall settings

### "No models available"

1. Make sure you've configured a model in OpenClaw
2. Try refreshing the model list in Settings

### "Context not updating"

1. Make sure you have a scene open
2. Try selecting a node
3. Click Refresh in the context panel

## License

MIT License

## Credits

- Godot Engine documentation (CC BY)
- OpenClaw - AI assistant framework