# ShaderMaterial

**Inherits:** Material < Resource < RefCounted < Object

## Description

ShaderMaterial allows you to use custom shaders on objects. It contains a Shader resource and uniforms (parameters) that can be set from GDScript.

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| shader | Shader | The Shader resource containing the shader code |

## Key Methods

### set_shader_parameter(name, value)
Set a uniform parameter in the shader.

```gdscript
# Set shader uniform
material.set_shader_parameter("tint_color", Color.RED)
material.set_shader_parameter("strength", 0.5)
```

### get_shader_parameter(name) -> Variant
Get a uniform parameter value.

## Shader Types

### CanvasItem Shader (2D)
```glsl
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    COLOR = texture(TEXTURE, UV) * tint_color;
    COLOR.a *= strength;
}
```

### Spatial Shader (3D)
```glsl
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    ALBEDO = albedo.rgb;
    METALLIC = metallic;
    ROUGHNESS = roughness;
}
```

## Common Patterns

### Creating ShaderMaterial in Code
```gdscript
# Create shader material
var shader_material = ShaderMaterial.new()
var shader = Shader.new()
shader.code = """
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    COLOR = mix(COLOR, flash_color, flash_amount);
}
"""
shader_material.shader = shader
sprite.material = shader_material
```

### Setting Uniforms
```gdscript
# Set from code
shader_material.set_shader_parameter("flash_color", Color.WHITE)
shader_material.set_shader_parameter("flash_amount", 0.5)

# Animate with Tween
var tween = create_tween()
tween.tween_property(shader_material, "shader_parameter/flash_amount", 0.0, 0.5)
```

### Passing Textures
```glsl
shader_type canvas_item;

uniform sampler2D noise_texture;

void fragment() {
    vec2 distorted_uv = UV + texture(noise_texture, UV).xy * 0.1;
    COLOR = texture(TEXTURE, distorted_uv);
}
```

```gdscript
# Set texture uniform
var noise_texture = preload("res://noise.png")
shader_material.set_shader_parameter("noise_texture", noise_texture)
```

## Built-in Variables

### CanvasItem (2D)
- `COLOR` - Output color
- `UV` - Texture coordinates
- `TEXTURE` - Sprite texture
- `TIME` - Time in seconds
- `SCREEN_TEXTURE` - Screen content
- `SCREEN_UV` - Screen coordinates

### Spatial (3D)
- `ALBEDO` - Base color
- `METALLIC` - Metallic value
- `ROUGHNESS` - Roughness value
- `NORMAL_MAP` - Normal map
- `EMISSION` - Emission color
- `ALPHA` - Transparency

## Integration with godotclaw

When a user asks about shaders, godotclaw should:

1. Check if ShaderMaterial exists on selected nodes
2. Check for existing shader resources in the project
3. Provide context about:
   - Current shader parameters
   - Available textures
   - Shader type (canvas_item vs spatial)

### Example Context
```json
{
  "shader": {
    "has_material": true,
    "shader_type": "canvas_item",
    "uniforms": {
      "tint_color": {"type": "vec4", "value": [1, 0, 0, 1]},
      "strength": {"type": "float", "value": 0.5}
    },
    "shader_path": "res://shaders/tint.gdshader"
  }
}
```

## More Information

- [Official Docs](https://docs.godotengine.org/en/stable/classes/class_shadermaterial.html)
- [Shading Language](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/index.html)
- [Visual Shader Tutorial](https://docs.godotengine.org/en/stable/tutorials/shaders/introduction_to_visual_shaders.html)