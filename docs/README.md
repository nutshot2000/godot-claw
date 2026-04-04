# godotclaw Documentation

A comprehensive Godot 4 documentation database for AI-assisted development.

## Folder Structure

```
docs/
├── nodes/                    # Node class documentation
│   ├── 3d_nodes.md          # MeshInstance3D, Camera3D, CharacterBody3D, RigidBody3D
│   ├── introduction_to_3d.md # 3D workspace, coordinate system, cameras, lights
│   ├── tilemap.md           # Tile-based levels
│   └── ...                  # (more from Context7: CharacterBody2D, etc.)
├── gdscript/                 # GDScript language
│   └── ...                  # (from Context7)
├── physics/                  # Physics system
│   └── ...                  # (from Context7)
├── navigation/               # Navigation system
│   └── navigationagent2d.md # Pathfinding
├── multiplayer/              # Multiplayer networking
│   └── multiplayerapi.md    # RPC system
├── shaders/                  # Shader programming
│   └── shadermaterial.md    # Shader materials
├── editor/                   # Editor integration
│   └── editorplugin.md      # Plugin development
├── best_practices.md         # Common pitfalls and best practices
├── scene_organization.md     # Scene tree structure patterns
└── README.md                 # This file
```

## Topics Covered

### Nodes & Classes
- Node3D, MeshInstance3D, Camera3D
- CharacterBody2D/3D, RigidBody2D/3D
- TileMap, Area2D, Sprite2D
- AnimationPlayer, Tween
- EditorPlugin

### Best Practices
- Scene organization
- Autoloads vs internal nodes
- When to use scenes vs scripts
- Dependency injection patterns
- Common AI mistakes

### Systems
- Navigation (NavigationAgent2D)
- Multiplayer (MultiplayerAPI, RPC)
- Shaders (ShaderMaterial)
- Input handling
- Signals

## Integration with godotclaw

When a user asks a question, the plugin:

1. **Searches this documentation** for relevant files
2. **Extracts context** from the current scene
3. **Builds a prompt** with docs + context
4. **Sends to OpenClaw** for LLM processing

## Updating Documentation

### From Context7
```bash
npx ctx7@latest docs /godotengine/godot "topic" > docs/nodes/topic.md
```

### From Official Docs
```bash
curl https://docs.godotengine.org/en/stable/classes/class_topic.html > docs/topic.md
curl https://docs.godotengine.org/en/stable/tutorials/path.html > docs/topic.md
```

## Source Attribution

- **Context7**: GDScript basics, signals, nodes, CharacterBody2D, Tween, Input
- **Godot Official Docs**: TileMap, Shaders, 3D nodes, Navigation, Multiplayer, EditorPlugin, Best Practices