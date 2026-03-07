---
name: td-pops
description: Write GLSL compute shaders for TouchDesigner's POP (Point Operator) family — GLSL POP, GLSL Advanced POP, GLSL Copy POP, and GLSL Select POP. Use this skill whenever the user wants to create particle systems, point cloud manipulation, geometry processing, GPU-driven point simulations, instancing with GLSL, or any compute-shader work inside TouchDesigner's POP context. Trigger on mentions of GLSL POP, particle shader, point operator, compute shader for particles, point cloud GLSL, POP attributes, SSBO particle data, GLSL Copy POP, GLSL Advanced POP, or any request to manipulate points/vertices/primitives with GLSL in TouchDesigner.
---

# TouchDesigner GLSL POPs — Compute Shader Writing

Write GLSL compute shaders for TouchDesigner's GPU-accelerated Point Operators (POPs).

GLSL POPs are fundamentally different from GLSL TOPs. TOPs are pixel/fragment shaders that output images; POPs are **compute shaders** that read and write **particle/point attributes** stored in SSBOs (Shader Storage Buffer Objects). There is no `fragColor`, no `vUV`, no `sTD2DInputs` — instead you work with attribute arrays like `P[]`, `v[]`, `Cd[]` indexed by `TDIndex()`.

## Quick Start

Every GLSL POP compute shader needs:

```glsl
void main() {
    // 1. Get thread index and bounds-check
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // 2. Read input attributes
    vec3 pos = TDIn_P();           // shorthand for TDIn_P(0, id, 0)

    // 3. Modify attributes
    pos.y += 0.01;

    // 4. Write to output attribute arrays
    P[id] = pos;
}
```

## Critical Rules

1. **No fragment-shader constructs** — there is no `out vec4 fragColor`, no `vUV`, no `sTD2DInputs`, no `TDOutputSwizzle()`. Those belong to GLSL TOPs/MATs, not POPs.
2. **Always bounds-check**: `if (id >= TDNumElements()) return;` prevents out-of-bounds writes.
3. **Output attributes are arrays** declared as `attribType AttribName[];` — write with `AttribName[id] = value;`
4. **Input attributes are functions**: `TDIn_AttribName()` for GLSL POP, `TDInPoint_AttribName()` / `TDInPrim_AttribName()` / `TDInVert_AttribName()` for GLSL Advanced POP.
5. **Initialize outputs**: Uninitialized output attributes cause crashes. Either enable "Initialize Output Attributes" in the operator parameters, or explicitly write every output element.
6. **Uniforms workflow**: Same as GLSL TOPs — declare in shader, configure on the operator's parameter pages (Vectors, Colors, Samplers, etc.).

## Choosing the Right POP Operator

| Operator | Use When | Key Trait |
|---|---|---|
| **GLSL POP** | Modifying one attribute class (points OR verts OR prims) without changing element count | Simplest, single-class processing |
| **GLSL Advanced POP** | Reading/writing points, verts, AND prims simultaneously, or changing element counts | Most powerful, simultaneous multi-class access |
| **GLSL Copy POP** | Instancing — duplicating geometry with per-copy transforms | Separate shaders for points/verts/prims per copy |
| **GLSL Select POP** | Picking an extra output stream from a GLSL Advanced POP | Utility, no shader code needed |

## Input / Output Attribute Access

### GLSL POP (single attribute class)

```glsl
// Reading input (shorthand defaults: inputIndex=0, elementId=TDIndex(), arrayIndex=0)
vec3 pos = TDIn_P();
vec4 col = TDIn_Cd();
vec3 vel = TDIn_v();

// With explicit parameters
vec3 pos2 = TDIn_P(1, id, 0);   // input 1, element id, array index 0

// Writing output (arrays — must be declared in Output Attributes parameter)
P[id] = pos;
Cd[id] = col;
v[id] = vel;
```

### GLSL Advanced POP (all classes simultaneously)

```glsl
// Reading — class-prefixed functions
vec3 pos  = TDInPoint_P();
vec3 nrm  = TDInVert_N();
int  ptype = TDInPrim_primtype();

// Writing — class-prefixed arrays
oTDPoint_P[id] = pos;
oTDVert_N[id]  = nrm;
```

### GLSL Copy POP

```glsl
// Same TDIn_ pattern, plus copy-specific functions
uint copyIdx  = TDCopyIndex();
uint inputPt  = TDInputPointIndex();   // matching input point for this thread

P[id] = TDIn_P() + float(copyIdx) * vec3(1.0, 0.0, 0.0);
TDUpdatePointGroups();   // preserve point group membership
```

## Common Patterns

See [examples/PATTERNS.md](examples/PATTERNS.md) for ready-to-use templates:
- Position offset / animation
- Velocity-driven motion
- Noise-based displacement
- Attraction / repulsion forces
- Age-based color and fade
- Instancing with GLSL Copy POP

## TouchDesigner Helper Functions

```glsl
// Indexing
uint TDIndex();              // 1D thread index
uint TDNumElements();        // total requested threads

// Element counts
uint TDInputNumPoints(uint inputIndex);
uint TDInputNumPrims(uint inputIndex);
uint TDInputNumVerts(uint inputIndex);

// Math helpers
mat3 TDRotateOnAxis(float radians, vec3 axis);
mat3 TDRotateX(float radians);
mat3 TDRotateY(float radians);
mat3 TDRotateZ(float radians);
mat3 TDCreateRotMatrix(vec3 from, vec3 to);

// Noise
float TDSimplexNoise(vec2/vec3/vec4 v);
float TDPerlinNoise(vec2/vec3/vec4 v);

// Color
vec3 TDHSVToRGB(vec3 hsv);
vec3 TDRGBToHSV(vec3 rgb);

// Remapping
float TDRemap(float val, float oldMin, float oldMax, float newMin, float newMax);
float TDLoop(float val, float low, float high);
float TDZigZag(float val, float low, float high);
```

## Response Format

When providing GLSL POP shaders, always include:

1. **Which POP operator** to use (GLSL POP, GLSL Advanced POP, or GLSL Copy POP)
2. **GLSL Code** with comments explaining each section
3. **Output Attributes** — which attributes the user must list in the "Output Attributes" parameter (e.g., `P v Cd`)
4. **Attribute Class** — Point, Vertex, or Primitive (for GLSL POP)
5. **TouchDesigner Setup** instructions:
   - Uniform names, types, and values on the Vectors / Colors / Samplers pages
   - Whether to enable "Initialize Output Attributes"
   - Number of passes (if multi-pass)
   - Any additional inputs or operator wiring

## Common Errors

See [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) for solutions to:
- Reading uninitialized output attributes (crashes)
- Missing bounds check causing GPU hangs
- Using fragment-shader syntax in a compute shader
- Attributes not appearing in output
- Performance issues with large point counts

## Additional Resources

- [reference/FUNCTIONS.md](reference/FUNCTIONS.md) — Complete GLSL POP API reference
- [reference/BEST-PRACTICES.md](reference/BEST-PRACTICES.md) — Optimization & workflow tips
- [examples/COMPLETE.md](examples/COMPLETE.md) — Full production-ready examples

## Writing Process

1. Identify the right POP operator for the task
2. Start with a template from [templates/](templates/)
3. Declare uniforms and configure on TD parameter pages
4. List all output attributes in the operator's "Output Attributes" field
5. Implement shader logic with proper bounds checking
6. Enable "Initialize Output Attributes" if not writing every attribute
7. Test incrementally — start with position only, then add velocity, color, etc.
