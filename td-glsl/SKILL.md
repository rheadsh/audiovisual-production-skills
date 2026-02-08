---
name: td-glsl
description: Write GLSL shaders for TouchDesigner's GLSL TOP, GLSL MAT, and GLSL COMP operators. Use when creating pixel shaders, vertex shaders, compute shaders, visual effects, image processing, generative art, GPU computations, or working with .glsl/.frag files for TouchDesigner.
---

# TouchDesigner GLSL Shader Writing

Write GLSL shaders optimized for TouchDesigner's shader operators.

## Quick Start

Every TouchDesigner pixel shader needs:

```glsl
// 1. Uniforms - Only declare what YOU need
uniform float uTime;

// 2. Output - Must be global, before main()
out vec4 fragColor;

// 3. Main function
void main() {
    vec4 color = texture(sTD2DInputs[0], vUV.st);
    fragColor = TDOutputSwizzle(color);
}
```

## Critical Rules

1. **Output declaration**: `out vec4 fragColor;` must be global (before `main()`)
2. **Never declare**: `sTD2DInputs[]`, `vUV`, `vP`, `vN` - TouchDesigner provides these
3. **Always use**: `TDOutputSwizzle()` for final output
4. **Uniforms workflow**: Declare in GLSL + Configure in TD parameter pages

## Automatic Variables (DO NOT Declare)

```glsl
sTD2DInputs[0]     // Input textures - just use them!
vUV.st             // UV coordinates (0-1)
vP, vN, vColor     // Position, normal, vertex color
```

## Must Declare and Configure

TouchDesigner does NOT provide automatic uniforms. You must:

1. Declare in shader: `uniform float uTime;`
2. Configure in TD UI (Vectors page):
   - Name: `uTime`
   - Type: `float`
   - Value: `absTime.seconds`

## Common Patterns

See [examples/PATTERNS.md](examples/PATTERNS.md) for ready-to-use templates:
- Basic texture sampling
- Time-based animation
- Multi-input blending
- Generative patterns
- Feedback loops
- Displacement effects

## TouchDesigner Functions

```glsl
// Output (required)
TDOutputSwizzle(vec4 color)

// Noise
TDSimplexNoise(vec2 p)
TDPerlinNoise(vec3 p)

// Color conversion
TDHSVToRGB(vec3 hsv)
TDRGBToHSV(vec3 rgb)
```

## Response Format

When providing shaders, always include:

1. **GLSL Code** with comments
2. **TouchDesigner Setup** instructions:
   - Which parameter page (Vectors, Colors, CHOP Uniforms)
   - Uniform names and types
   - Values or expressions (e.g., `absTime.seconds`)

## Common Errors

See [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) for solutions to:
- `'fragColor' : undeclared identifier`
- `'sTD2DInputs' : redefinition`
- `'uTime' : undeclared identifier`
- Uniforms with no effect
- Black/incorrect output

## Additional Resources

- [reference/FUNCTIONS.md](reference/FUNCTIONS.md) - Complete API reference
- [reference/BEST-PRACTICES.md](reference/BEST-PRACTICES.md) - Optimization & organization
- [examples/COMPLETE.md](examples/COMPLETE.md) - Full shader examples

## Writing Process

1. Start with basic template
2. Add uniforms (declare + configure)
3. Implement shader logic
4. Test incrementally
5. Optimize when working
