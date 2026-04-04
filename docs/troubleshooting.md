# Troubleshooting

Common Godot issues and solutions.

## Performance Issues

### Editor uses high CPU/GPU

**Symptoms:** Editor runs slowly, computer gets noisy, fans spin up.

**Causes:**
- Retina displays (macOS) render at higher resolution
- Continuous redrawing (particles, animations)

**Solutions:**
- Enable **Half Resolution** in 3D viewport (Perspective button)
- Increase **Low Processor Mode Sleep (µsec)** to `33000` (30 FPS) in Editor Settings
- Hide nodes that cause continuous redraws in editor:

```gdscript
func _ready():
    $Particles.visible = true  # Only visible in game
```

### Variable Refresh Rate Flicker (G-Sync/FreeSync)

**Symptoms:** Editor stutters and flickers on VRR monitors.

**Solutions:**
- Enable **Interface > Editor > Update Continuously** in Editor Settings
- Disable VRR on monitor or graphics driver
- Use **Black (OLED)** editor theme preset

### Slow Startup

**Causes:**
- First startup: shader compilation (normal)
- After driver update: shader recompilation (normal)
- USB peripherals (Corsair iCUE on Windows)
- Firewall blocking debug port
- Windows Defender scanning project files

**Solutions:**
- Wait for shader compilation (one-time)
- Disconnect problematic USB devices
- Change debug port in Editor Settings (**Network > Debug > Remote Port**)
- Add project folder to Windows Defender exclusions

---

## Display Issues

### Washed Out Colors

**Causes:** HDR mode on SDR content

**Solutions:**
- Disable HDR in Windows settings
- Use Windows 11 instead of Windows 10 for HDR
- Configure display for HGIG tonemapping

### Overly Sharp/Blurry Image

**Causes:** Graphics driver forcing sharpening/FXAA

**Solutions:**
- **NVIDIA (Windows):** NVIDIA Control Panel > Manage 3D settings > Image Sharpening > Off
- **NVIDIA (Windows):** NVIDIA Control Panel > Fast Approximate Antialiasing > Application Controlled
- **AMD (Windows):** AMD Software > Graphics > Disable Radeon Image Sharpening

### "NO DC" Text in Top-Left

**Cause:** NVIDIA graphics driver overlay

**Solution:** Restore graphics driver to default settings in NVIDIA Control Panel

### Microphone/Refresh Icon in Corner

**Cause:** NVIDIA ShadowPlay overlay

**Solution:** Press Alt+Z, disable **Settings > HUD Layout > Status Indicator**

---

## Export Issues

### Files Missing in Exported Project

**Symptoms:** Project works in editor but fails to load files when exported.

**Causes:**
- Non-resource files not included (JSON, custom formats)
- Case sensitivity issues (Windows)

**Solutions:**
- Add file filters in Export dialog: `*.json` for non-resource files
- Use consistent file naming (lowercase `snake_case`)
- Files/folders starting with `.` are never included

### Case Sensitivity Problems

**Problem:** Windows is case-insensitive, but PCK filesystem is case-sensitive.

**Solution:** Use `snake_case` for all files and reference them consistently:

```gdscript
# BAD: Case mismatch
preload("res://Player.tscn")  # File is actually player.tscn

# GOOD: Consistent case
preload("res://player.tscn")
```

---

## Platform-Specific Issues

### Windows: Console Selection Mode

**Symptoms:** Editor appears frozen after clicking system console.

**Cause:** Windows selection mode in command window.

**Solution:** Select console window and press Enter to exit selection mode.

### macOS: Duplicate Dock Icons

**Symptoms:** Dock icon duplicates when manually moved.

**Cause:** macOS dock design limitation.

**Solution:** Keep dock icon at default position.

### Linux: NVIDIA Suspend Issues

**Symptoms:** Editor freezes or displays glitches after resume from suspend.

**Solutions:**
- Use Compatibility renderer (OpenGL) instead of Forward+/Mobile (Vulkan)
- Enable NVIDIA experimental option to preserve video memory after suspend
- Save before suspending

---

## Crashes

### Project Crashes on Open

**Solutions:**
- Open in recovery mode (hold Ctrl while opening)
- Check for problematic plugins/GDExtensions
- Check editor logs: `%APPDATA%\Godot\` (Windows) or `~/.local/share/godot/` (Linux)

### Frequent Crashes

**Debugging steps:**
1. Disable all plugins (remove from `addons/` folder)
2. Try Compatibility renderer
3. Update graphics drivers
4. Check for memory leaks in scripts

---

## Common Errors

### "Script not found"

**Causes:**
- Script was moved or renamed
- Script has errors preventing load

**Solutions:**
- Check script path in Inspector
- Open script and check for errors
- Reattach script to node

### "Circular Dependency"

**Symptoms:** Scripts depend on each other.

**Solution:** Restructure code to break circular dependency:

```gdscript
# BAD: Circular dependency
# ClassA references ClassB, ClassB references ClassA

# GOOD: Use signals or dependency injection
class_name ClassA
signal event_happened

# ClassA doesn't directly reference ClassB
```

### "Node not found"

**Causes:**
- Node path is wrong
- Node hasn't been added yet
- Typo in node name

**Solutions:**
- Check node path in Scene tree
- Use `@onready` for references
- Use `get_node_or_null()` to check without error

```gdscript
# Safe node reference
@onready var child = $Child  # Caches reference after _ready

# Check if exists
func do_something():
    var node = get_node_or_null("OptionalNode")
    if node:
        node.visible = false
```

---

## Performance Tips

### Reduce Editor Overhead

1. Hide heavy nodes in editor:

```gdscript
func _ready():
    $HeavyParticles.emitting = true  # Enable at runtime only
```

2. Use **Half Resolution** in 3D viewport

3. Increase **Low Processor Mode Sleep** in Editor Settings

### Reduce Project Size

1. Use `.gdignore` to exclude folders from import
2. Compress textures (VRAM compression)
3. Use audio formats appropriately (OGG for music, WAV for short SFX)

### Improve Game Performance

1. Use Object Pooling for frequently instantiated objects
2. Use TileMaps instead of individual sprites for levels
3. Enable **Visible Collision Shapes** only when debugging
4. Use MultiMesh for many similar objects