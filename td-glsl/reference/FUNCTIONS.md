# TouchDesigner GLSL Functions Reference

Complete API reference for TouchDesigner-specific GLSL functions.

## Automatic Variables

### Texture Inputs

```glsl
sTD2DInputs[N]  // Array of input textures (sampler2D)
```

Access input textures by index:
- `sTD2DInputs[0]` - First input
- `sTD2DInputs[1]` - Second input
- etc.

**DO NOT DECLARE** - automatically provided by TouchDesigner.

**Get texture dimensions**:
```glsl
ivec2 size = textureSize(sTD2DInputs[0], 0);  // width, height
```

### Varyings (Pixel Shaders)

```glsl
in vec2 vUV;        // UV coordinates (0-1 range)
in vec3 vP;         // World position
in vec3 vN;         // Normal vector
in vec4 vColor;     // Vertex color
```

**DO NOT DECLARE** - automatically provided.

### Depth Info (3D Textures)

```glsl
uniform int uTDCurrentDepth;  // Current slice index (0-based)
```

Available when rendering 3D textures or 2D texture arrays.

---

## TouchDesigner Functions

### Output

```glsl
vec4 TDOutputSwizzle(vec4 color)
```

**REQUIRED** - Always wrap your final output with this function.

Handles color space conversion and channel swizzling.

**Example**:
```glsl
fragColor = TDOutputSwizzle(color);
```

---

### Noise Functions

#### Simplex Noise (Recommended)

```glsl
float TDSimplexNoise(vec2 p)
float TDSimplexNoise(vec3 p)
```

Fast, smooth noise with good visual quality.

**Quality modes** (set in GLSL TOP parameters):
- Performance: Faster, slight artifacts
- Quality: Slower, fewer artifacts

**Example**:
```glsl
float noise = TDSimplexNoise(vec2(vUV.st * 10.0));
float noise3d = TDSimplexNoise(vec3(vUV.st * 5.0, uTime));
```

#### Perlin Noise

```glsl
float TDPerlinNoise(vec2 p)
float TDPerlinNoise(vec3 p)
```

Classic Perlin noise.

**Example**:
```glsl
float noise = TDPerlinNoise(vec2(vUV.st * 10.0));
```

---

### Color Conversion

```glsl
vec3 TDHSVToRGB(vec3 hsv)
vec3 TDRGBToHSV(vec3 rgb)
```

Convert between RGB and HSV color spaces.

**HSV components**:
- `x` (H): Hue (0-1, wraps around)
- `y` (S): Saturation (0-1)
- `z` (V): Value/Brightness (0-1)

**Example**:
```glsl
vec3 rgb = vec3(1.0, 0.5, 0.2);
vec3 hsv = TDRGBToHSV(rgb);

// Adjust hue
hsv.x += 0.5;

// Convert back
vec3 newRgb = TDHSVToRGB(hsv);
```

---

### Coordinate Utilities

```glsl
vec2 TDUVMap(vec2 uv)
```

Apply UV mapping transformations configured in the operator.

```glsl
vec2 TDDefaultCoord()
```

Get default coordinates for the current pixel.

---

## Standard GLSL Functions

### Texture Sampling

```glsl
vec4 texture(sampler2D tex, vec2 uv)
vec4 texture(sampler2D tex, vec2 uv, float bias)
```

Sample a texture at UV coordinates.

**Example**:
```glsl
vec4 color = texture(sTD2DInputs[0], vUV.st);
```

```glsl
vec4 texelFetch(sampler2D tex, ivec2 coord, int lod)
```

Direct texel access (no filtering).

**Example**:
```glsl
ivec2 pixel = ivec2(100, 50);
vec4 color = texelFetch(sTD2DInputs[0], pixel, 0);
```

```glsl
ivec2 textureSize(sampler2D tex, int lod)
```

Get texture dimensions in pixels.

**Example**:
```glsl
ivec2 size = textureSize(sTD2DInputs[0], 0);
float width = float(size.x);
float height = float(size.y);
```

---

### Math Functions

#### Interpolation

```glsl
mix(x, y, a)           // Linear interpolation: x*(1-a) + y*a
smoothstep(e0, e1, x)  // Smooth Hermite interpolation
step(edge, x)          // 0 if x < edge, 1 otherwise
```

**Examples**:
```glsl
vec4 blended = mix(color1, color2, 0.5);  // 50% blend

// Smooth transition from 0 to 1 between edges
float fade = smoothstep(0.4, 0.6, distance);

// Hard threshold
float mask = step(0.5, value);
```

#### Clamping

```glsl
clamp(x, min, max)  // Constrain x to [min, max]
min(x, y)           // Minimum of x and y
max(x, y)           // Maximum of x and y
```

**Examples**:
```glsl
color.rgb = clamp(color.rgb, 0.0, 1.0);  // Keep in valid range
float safe = max(denominator, 0.0001);    // Prevent division by zero
```

#### Geometric

```glsl
length(v)           // Length of vector
distance(p0, p1)    // Distance between points
normalize(v)        // Normalize vector to unit length
dot(v1, v2)         // Dot product
cross(v1, v2)       // Cross product (vec3 only)
```

**Examples**:
```glsl
float dist = distance(vUV.st, center);
vec2 direction = normalize(offset);
```

#### Trigonometric

```glsl
sin(x), cos(x), tan(x)
asin(x), acos(x), atan(x)
atan(y, x)  // atan2 - angle from x axis
```

**Examples**:
```glsl
float wave = sin(uTime * 3.14159);
float angle = atan(uv.y, uv.x);
```

#### Exponential

```glsl
pow(x, y)    // x^y
exp(x)       // e^x
log(x)       // Natural logarithm
sqrt(x)      // Square root
```

#### Common

```glsl
abs(x)       // Absolute value
sign(x)      // Sign (-1, 0, or 1)
floor(x)     // Round down
ceil(x)      // Round up
fract(x)     // Fractional part (x - floor(x))
mod(x, y)    // Modulo operation
```

**Examples**:
```glsl
vec2 repeated = fract(uv * 10.0);  // Tile 10x10
float grid = mod(floor(uv.x * 10.0), 2.0);  // Checkerboard
```

---

## Useful Patterns

### Remap Range

```glsl
float remap(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

// Usage
float remapped = remap(value, 0.0, 1.0, -1.0, 1.0);
```

### Safe Division

```glsl
float safeDivide(float numerator, float denominator) {
    return numerator / max(denominator, 0.0001);
}
```

### Aspect-Corrected Coordinates

```glsl
uniform float uAspect;

vec2 aspectCorrect(vec2 uv) {
    vec2 centered = uv * 2.0 - 1.0;  // -1 to 1
    centered.x *= uAspect;
    return centered;
}
```

### Polar Coordinates

```glsl
vec2 toPolar(vec2 uv) {
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    return vec2(angle, radius);
}
```

### RGB to Grayscale

```glsl
float toGrayscale(vec3 rgb) {
    // Perceptual weights
    return dot(rgb, vec3(0.299, 0.587, 0.114));
}
```

---

## Performance Tips

### Minimize Texture Lookups

```glsl
// ❌ Slow - 9 texture lookups
for(int i = 0; i < 9; i++) {
    color += texture(sTD2DInputs[0], uv + offsets[i]);
}

// ✅ Better - Unroll if possible
color += texture(sTD2DInputs[0], uv + vec2(-1,-1) * size);
color += texture(sTD2DInputs[0], uv + vec2(0,-1) * size);
// ... etc
```

### Use Built-in Functions

```glsl
// ❌ Slower
float len = sqrt(x*x + y*y);

// ✅ Faster
float len = length(vec2(x, y));
```

### Avoid Conditionals

```glsl
// ❌ Branching
if(value > 0.5) {
    color = red;
} else {
    color = blue;
}

// ✅ Branchless
color = mix(blue, red, step(0.5, value));
```

### Precompute Constants

```glsl
// ❌ Computed every pixel
float value = sin(uTime * 3.14159265);

// ✅ Define once
const float PI = 3.14159265;
// Then use PI in calculations
```
