# GLSL Best Practices for TouchDesigner

Optimization, organization, and workflow guidelines.

## Code Organization

### Recommended Structure

```glsl
// 1. UNIFORMS (global scope, top of file)
uniform float uTime;
uniform vec2 uResolution;
uniform vec3 uColor;

// 2. CONSTANTS (optional, after uniforms)
const float PI = 3.14159265359;
const float TAU = 6.28318530718;

// 3. HELPER FUNCTIONS (optional, before main)
float remap(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

// 4. OUTPUT DECLARATION (required, before main)
out vec4 fragColor;

// 5. MAIN FUNCTION (last)
void main() {
    // Shader logic here
    vec4 color = vec4(1.0);
    fragColor = TDOutputSwizzle(color);
}
```

### Naming Conventions

**Uniforms**: Prefix with `u`
```glsl
uniform float uTime;
uniform vec3 uColor;
```

**Constants**: UPPER_CASE or PascalCase
```glsl
const float PI = 3.14159;
const float MaxIterations = 100.0;
```

**Functions**: camelCase or snake_case
```glsl
float calculateNoise(vec2 p) { ... }
vec3 apply_color_grade(vec3 rgb) { ... }
```

**Variables**: camelCase
```glsl
vec2 texCoord = vUV.st;
float distFromCenter = length(uv);
```

---

## Performance Optimization

### Texture Sampling

**Minimize lookups** - Each `texture()` call is expensive:

```glsl
// ❌ BAD - Multiple samples for same texture
vec4 c1 = texture(sTD2DInputs[0], uv);
vec4 c2 = texture(sTD2DInputs[0], uv + offset);
vec4 c3 = texture(sTD2DInputs[0], uv - offset);

// ✅ GOOD - Cache when possible
vec4 center = texture(sTD2DInputs[0], uv);
vec4 offset1 = texture(sTD2DInputs[0], uv + offset);
vec4 offset2 = texture(sTD2DInputs[0], uv - offset);
vec4 result = center * 0.5 + offset1 * 0.25 + offset2 * 0.25;
```

### Conditional Statements

**Avoid branching** - GPUs prefer branchless code:

```glsl
// ❌ SLOW - Conditional branch
vec3 color;
if(uv.x > 0.5) {
    color = vec3(1.0, 0.0, 0.0);
} else {
    color = vec3(0.0, 0.0, 1.0);
}

// ✅ FAST - Branchless
vec3 red = vec3(1.0, 0.0, 0.0);
vec3 blue = vec3(0.0, 0.0, 1.0);
vec3 color = mix(blue, red, step(0.5, uv.x));
```

**When conditionals are okay**:
- Uniform-based switches (compiled into shader variants)
- Early termination in complex shaders
- Rare edge cases

### Loop Optimization

**Unroll when possible**:

```glsl
// ❌ DYNAMIC LOOP - Slower
for(int i = 0; i < iterations; i++) {
    result += calculate(i);
}

// ✅ FIXED LOOP - Faster
for(int i = 0; i < 10; i++) {
    result += calculate(i);
}

// ✅ UNROLLED - Fastest (for small counts)
result += calculate(0);
result += calculate(1);
result += calculate(2);
```

### Math Optimization

**Use built-in functions**:

```glsl
// ❌ SLOW
float dist = sqrt(x*x + y*y);
float normalized_x = x / sqrt(x*x + y*y);

// ✅ FAST
float dist = length(vec2(x, y));
vec2 normalized = normalize(vec2(x, y));
```

**Avoid expensive operations**:

```glsl
// Expensive: pow, sin, cos, tan, exp, log
// Cheap: +, -, *, /, mix, step, smoothstep

// ❌ SLOW
float result = pow(value, 2.0);

// ✅ FAST
float result = value * value;
```

**Precompute constants**:

```glsl
// ❌ BAD - Computed every pixel
float angle = uTime * 3.14159265 / 180.0;

// ✅ GOOD - Computed once
const float DEG_TO_RAD = 3.14159265 / 180.0;
float angle = uTime * DEG_TO_RAD;
```

---

## Precision and Stability

### Numeric Precision

```glsl
// Default is highp on modern GPUs, but be aware:
// - highp: full precision (slower on mobile)
// - mediump: half precision (faster, less accurate)
// - lowp: quarter precision (colors only)

// Specify when needed
highp float preciseValue;
mediump vec2 normalCoord;
lowp vec4 color;
```

### Avoid Division by Zero

```glsl
// ❌ DANGEROUS
float result = value / denominator;

// ✅ SAFE
float result = value / max(denominator, 0.0001);
```

### Handle Edge Cases

```glsl
// ❌ Can produce NaN
float normalized = value / length(vec);

// ✅ Safe
float len = length(vec);
float normalized = len > 0.0 ? value / len : 0.0;

// Or use safe normalize
vec2 safeNormalize(vec2 v) {
    float len = length(v);
    return len > 0.0 ? v / len : vec2(0.0);
}
```

---

## Memory and Resources

### Minimize Variable Count

```glsl
// ❌ Too many variables
float temp1 = a + b;
float temp2 = temp1 * c;
float temp3 = temp2 - d;
float result = temp3 / e;

// ✅ Reuse variables
float result = a + b;
result *= c;
result -= d;
result /= e;
```

### Vector Packing

```glsl
// ❌ Separate variables
float x, y, z;

// ✅ Packed in vector
vec3 position;
```

---

## Debugging Strategies

### Visual Debugging

**Output intermediate values as colors**:

```glsl
// Debug: visualize UV coordinates
fragColor = TDOutputSwizzle(vec4(vUV.st, 0.0, 1.0));

// Debug: visualize distance field
float dist = length(uv);
fragColor = TDOutputSwizzle(vec4(vec3(dist), 1.0));

// Debug: visualize noise
float noise = TDSimplexNoise(vUV.st * 10.0);
fragColor = TDOutputSwizzle(vec4(vec3(noise), 1.0));
```

### Range Checking

**Ensure values are in expected range**:

```glsl
// Clamp to see if values exceed range
vec3 clamped = clamp(color.rgb, 0.0, 1.0);
if(clamped != color.rgb) {
    // Values were out of range - visualize in red
    fragColor = TDOutputSwizzle(vec4(1.0, 0.0, 0.0, 1.0));
}
```

### Gradient Debugging

**Test with simple gradients first**:

```glsl
// Start with simple gradient to verify UV
fragColor = TDOutputSwizzle(vec4(vUV.st, 0.0, 1.0));

// Then add complexity incrementally
```

---

## TouchDesigner-Specific Tips

### Uniform Configuration

**Use CHOPs for animated values**:

Instead of Python expressions like `absTime.seconds`, use CHOPs:

1. Create **Speed CHOP**
2. Set to Play Mode: Locked
3. Reference in GLSL TOP CHOP Uniforms

Benefits:
- Reduces CPU overhead
- Better performance
- GPU-side computation

### Multi-Pass Techniques

For expensive effects (blur, convolution), use multiple passes:

1. GLSL TOP 1: Horizontal pass
2. GLSL TOP 2: Vertical pass (takes output of #1)

Benefits:
- Faster than single 2D pass
- Better quality
- More control

### Feedback Patterns

**Use Feedback TOP + GLSL TOP**:

```glsl
uniform float uDecay;

out vec4 fragColor;
void main() {
    vec4 current = texture(sTD2DInputs[0], vUV.st);
    vec4 feedback = texture(sTD2DInputs[1], vUV.st);
    
    vec4 color = mix(feedback * uDecay, current, 0.1);
    fragColor = TDOutputSwizzle(color);
}
```

Connect:
- Input 0: Current frame
- Input 1: Feedback TOP (output of this GLSL)

---

## Testing Checklist

Before finalizing a shader:

- [ ] Test at different resolutions
- [ ] Test with different input textures
- [ ] Verify all uniforms work as expected
- [ ] Check edge cases (black, white, transparent inputs)
- [ ] Verify aspect ratio correction (if needed)
- [ ] Test performance (check FPS)
- [ ] Ensure no compiler warnings
- [ ] Document uniform ranges and expected values
- [ ] Test with team/users if sharing

---

## Documentation Standards

### Comment Your Code

```glsl
// Good comments explain WHY, not WHAT

// ❌ BAD - Obvious
float x = uv.x * 2.0;  // Multiply x by 2

// ✅ GOOD - Explains purpose
float x = uv.x * 2.0;  // Remap from 0-1 to 0-2 range for tiling

// Document complex math
// Converts Cartesian to polar coordinates for radial distortion
float angle = atan(uv.y, uv.x);
float radius = length(uv);
```

### Parameter Documentation

In SKILL.md or shader comments, document:

```glsl
uniform float uDistortion;   // Range: 0.0-1.0, Default: 0.5
uniform vec3 uColor;         // RGB color, Default: (1.0, 0.5, 0.2)
uniform int uIterations;     // Range: 1-10, Default: 5
```

---

## Common Pitfalls

1. **Forgetting `TDOutputSwizzle()`** - Required for correct output
2. **Declaring automatic variables** - Don't declare `sTD2DInputs`, `vUV`, etc.
3. **Wrong declaration scope** - `out vec4 fragColor;` must be global
4. **Not configuring uniforms in TD** - Declaration alone isn't enough
5. **Overusing texture samples** - Cache and reuse when possible
6. **Dynamic loops** - Use fixed iteration counts when possible
7. **Division by zero** - Always protect against it
8. **Assuming square pixels** - Account for aspect ratio
9. **Not testing edge cases** - Black, white, transparent inputs
10. **Ignoring performance** - Profile and optimize hot paths
