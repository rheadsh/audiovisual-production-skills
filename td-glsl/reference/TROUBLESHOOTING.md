# TouchDesigner GLSL Troubleshooting

Common errors and their solutions.

## Error: `'fragColor' : undeclared identifier`

**Cause**: `out vec4 fragColor;` declared inside `main()` instead of at global scope.

**Fix**: Move the declaration outside and before `main()`:

```glsl
// ✅ CORRECT
out vec4 fragColor;
void main() { 
    // shader code
}

// ❌ WRONG
void main() {
    out vec4 fragColor;  // This will fail!
}
```

---

## Error: `'sTD2DInputs' : redefinition` or sampler errors

**Cause**: Attempting to declare `sTD2DInputs[]` in your shader.

**Fix**: Remove any declaration - TouchDesigner provides it automatically:

```glsl
// ❌ WRONG - Do NOT declare
sampler2D sTD2DInputs[1];

// ✅ CORRECT - Just use it directly
void main() {
    vec4 color = texture(sTD2DInputs[0], vUV.st);
    fragColor = TDOutputSwizzle(color);
}
```

---

## Error: `'uTime' : undeclared identifier` (or similar uniform)

**Cause**: Using a uniform without declaring it.

**Fix**: Add the uniform declaration at the top (global scope):

```glsl
// Add this BEFORE main()
uniform float uTime;

out vec4 fragColor;
void main() {
    // Now you can use uTime
}
```

**Then configure in TouchDesigner**:
- Go to Vectors parameter page
- Name: `uTime`
- Type: `float`
- Value: `absTime.seconds`

---

## Shader compiles but nothing appears / uniform has no effect

**Cause**: Uniform declared in GLSL but not configured in TouchDesigner UI.

**Fix**:
1. Click "Load Uniform Names" button in GLSL TOP
2. Or manually add in appropriate parameter page:
   - Vectors page for float/vec2/vec3/vec4
   - Colors page for color values
   - CHOP Uniforms page for CHOP data

**Verify setup**:
- Name matches exactly (case-sensitive)
- Type matches declaration (float vs vec2 vs vec3 vs vec4)
- Value is provided or connected

---

## Uniform doesn't show up in "Load Uniform Names"

**Cause**: GLSL compiler optimized away unused uniforms.

**Fix**: Make sure you actually use the uniform in your shader code:

```glsl
// ❌ Declared but never used - won't appear
uniform float uUnused;

// ✅ Declared and used - will appear
uniform float uTime;
void main() {
    vec2 uv = vUV.st + sin(uTime);  // Actually using it
}
```

---

## Texture appears black or wrong

**Cause**: Not using `TDOutputSwizzle()` or incorrect sampler.

**Fix**:

1. Always wrap final output:
```glsl
fragColor = TDOutputSwizzle(color);  // ✅ CORRECT
fragColor = color;                    // ❌ May produce wrong colors
```

2. Use correct sampler syntax:
```glsl
texture(sTD2DInputs[0], vUV.st)  // ✅ CORRECT
texture(myTexture, vUV.st)        // ❌ Don't declare your own
```

---

## Aspect ratio distortion in geometric shapes

**Cause**: Not accounting for non-square pixels/output.

**Fix**: Declare and use aspect ratio uniform:

```glsl
uniform float uAspect;

out vec4 fragColor;
void main() {
    vec2 uv = vUV.st * 2.0 - 1.0;
    uv.x *= uAspect;  // Correct for aspect ratio
    
    // Now geometric calculations are correct
    float circle = length(uv);
}
```

**TD Setup**: Vectors → `uAspect` (float) = `me.width / me.height`

---

## Performance issues / shader runs slowly

**Common causes**:
1. Too many texture lookups
2. Complex conditionals (if/else)
3. Dynamic loops
4. Expensive math operations

**Optimizations**:

```glsl
// ❌ SLOW - Multiple texture lookups
for(int i = 0; i < 100; i++) {
    color += texture(sTD2DInputs[0], uv + offset[i]);
}

// ✅ FASTER - Fewer lookups, fixed iterations
color += texture(sTD2DInputs[0], uv + offset1);
color += texture(sTD2DInputs[0], uv + offset2);
color += texture(sTD2DInputs[0], uv + offset3);

// ❌ SLOW - Conditional branching
if(uv.x > 0.5) {
    color = red;
} else {
    color = blue;
}

// ✅ FASTER - Use mix/step
color = mix(blue, red, step(0.5, uv.x));

// ❌ SLOW - Expensive operations in loop
for(int i = 0; i < 10; i++) {
    float expensive = pow(sin(x * 3.14159), 2.0);
}

// ✅ FASTER - Precompute constants
const float PI = 3.14159;
float base = sin(x * PI);
float result = base * base;
```

---

## Division by zero / NaN values

**Cause**: Dividing by zero or very small numbers.

**Fix**: Add safety checks:

```glsl
// ❌ Dangerous
float result = value / denominator;

// ✅ Safe
float result = value / max(denominator, 0.0001);

// Or with conditional
float result = denominator != 0.0 ? value / denominator : 0.0;
```

---

## Colors out of range (too bright/dark)

**Cause**: Values exceeding 0-1 range.

**Fix**: Use `clamp()`:

```glsl
// ❌ Can go out of range
color.rgb += brightness;

// ✅ Clamped to valid range
color.rgb = clamp(color.rgb + brightness, 0.0, 1.0);
```

---

## Using `absTime.seconds` causes high CPU usage

**Cause**: TouchDesigner evaluates Python expressions every frame.

**Fix**: Use a CHOP instead:

1. Create a **Speed CHOP**
2. Set Speed: 1.0
3. Set Play Mode: Locked
4. Reference in GLSL TOP CHOP Uniforms:
   - Name: `uTime`
   - CHOP: path to Speed CHOP
   - Type: float

This keeps time on GPU, reducing CPU overhead.

---

## Quick Diagnostic Checklist

When shader doesn't work:

- [ ] Is `out vec4 fragColor;` declared globally (before `main()`)?
- [ ] Are you declaring `sTD2DInputs`, `vUV`, etc.? (Don't!)
- [ ] Are all uniforms declared in shader?
- [ ] Are all declared uniforms configured in TD parameters?
- [ ] Did you click "Load Uniform Names" or manually add them?
- [ ] Are uniform names spelled exactly the same? (case-sensitive)
- [ ] Do types match (float vs vec2 vs vec3)?
- [ ] Is `TDOutputSwizzle()` wrapping the final output?
- [ ] Are you actually using all declared uniforms? (or they'll be optimized away)
