# MultiplayerAPI

**Inherits:** RefCounted < Object

**Inherited By:** MultiplayerAPIExtension, SceneMultiplayer

High-level multiplayer API interface.

## Description

Base class for high-level multiplayer API implementations. Handles RPCs (Remote Procedure Calls) and peer management.

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| multiplayer_peer | MultiplayerPeer | The peer object to handle RPCs |

## Key Methods

### get_unique_id() -> int
Returns the unique peer ID of this MultiplayerAPI's multiplayer_peer.

### is_server() -> bool
Returns `true` if the multiplayer_peer is valid and in server mode.

### get_peers() -> PackedInt32Array
Returns the peer IDs of all connected peers.

### rpc(peer, object, method, arguments)
Sends an RPC to the target peer.

## RPC Modes

```gdscript
# RPC disabled (default)
@rpc
func my_function():
    pass

# Any peer can call
@rpc("any_peer")
func my_function():
    pass

# Only authority can call
@rpc("authority")
func my_function():
    pass
```

## Signals

### connected_to_server()
Emitted when this MultiplayerAPI's multiplayer_peer successfully connects to a server. Only emitted on clients.

### connection_failed()
Emitted when connection to server fails.

### peer_connected(id)
Emitted when a new peer connects. `id` is the peer ID.

### peer_disconnected(id)
Emitted when a peer disconnects.

### server_disconnected()
Emitted when disconnected from server. Only emitted on clients.

## Common Patterns

### Setting Up Server
```gdscript
# Create server
var peer = ENetMultiplayerPeer.new()
peer.create_server(PORT, MAX_PLAYERS)
multiplayer.multiplayer_peer = peer

# Wait for connections
multiplayer.peer_connected.connect(_on_peer_connected)
multiplayer.peer_disconnected.connect(_on_peer_disconnected)
```

### Connecting as Client
```gdscript
# Connect to server
var peer = ENetMultiplayerPeer.new()
peer.create_client(SERVER_IP, PORT)
multiplayer.multiplayer_peer = peer

# Wait for connection
multiplayer.connected_to_server.connect(_on_connected_to_server)
multiplayer.connection_failed.connect(_on_connection_failed)
```

### Using RPCs
```gdscript
# Define RPC function
@rpc("any_peer")
func sync_position(position: Vector3):
    global_position = position

# Call on all peers
sync_position.rpc(global_position)

# Call on specific peer
sync_position.rpc_id(peer_id, global_position)

# Call on server only
sync_position.rpc_id(1, global_position)
```

### Authority Pattern
```gdscript
# Set node authority
set_multiplayer_authority(peer_id)

# Check if we're the authority
if is_multiplayer_authority():
    # Only authority sends updates
    sync_position.rpc(global_position)
```

## Integration with godotclaw

When a user asks about multiplayer, godotclaw should:

1. Check if multiplayer is already configured in the scene
2. Check for existing RPC functions in scripts
3. Provide context about:
   - Current multiplayer state (server/client)
   - Number of connected peers
   - Existing RPC functions

### Example Context
```json
{
  "multiplayer": {
    "is_server": false,
    "peer_id": 2,
    "connected_peers": [1],
    "has_multiplayer_node": true,
    "rpc_functions": ["sync_position", "sync_animation", "chat_message"]
  }
}
```

## More Information

- [Official Docs](https://docs.godotengine.org/en/stable/classes/class_multiplayerapi.html)
- [High-level Multiplayer Tutorial](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)