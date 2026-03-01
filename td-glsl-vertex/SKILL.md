---
name: td-glsl-vertex
description: Write GLSL vertex shaders for TouchDesigner's GLSL MAT operator. Use whenever creating 3D materials, vertex displacement, geometry deformation, mesh animation, instancing effects, custom surface normals, or any shader that needs to manipulate vertex data in 3D space. Also covers the complete vertex + pixel shader pair for GLSL MAT. Trigger when the user mentions GLSL MAT, vertex shader, vertex displacement, mesh deformation, instancing in TouchDesigner, 3D material writing, surface normals in GLSL, or wants to create a custom material for a SOP/geometry node.
---

# TouchDesigner GLSL MAT — Vertex Shader Writing

Write vertex and pixel shaders for TouchDesigner's **GLSL MAT** operator (not GLSL TOP). GLSL MAT applies to 3D geometry and requires **both a vertex shader and a pixel shader** in separate DATs.

## Quick Start — Minimal GLSL MAT

**Vertex Shader DAT** (e.g. `glsl_vert`):
```glsl
// Minimum viable vertex shader
out vec3 vWorldPos;   // Custom varying to pixel shader
out vec3 vNormal;

void main() {
    // 1. Deform: applies instancing, skinning → world space
    vec4 worldPos = TDDeform(P);

    // 2. Project: world → clip space
    gl_Position = TDWorldToProj(worldPos);

    // 3. Pass data to pixel shader
    vWorldPos = worldPos.xyz;
    vNormal   = normalize((uTDMats[TDCameraIndex()].worldForNormals * N).xyz);
}
```

**Pixel Shader DAT** (e.g. `glsl_frag`):
```glsl
// Input varyings from vertex shader
in vec3 vWorldPos;
in vec3 vNormal;

layout(location = 0) out vec4 fragColor;

void main() {
    vec3 color = vNormal * 0.5 + 0.5;  // Visualize normals
    fragColor = TDOutputSwizzle(vec4(color, 1.0));
}
```

**GLSL MAT Setup**:
- Load Page → Vertex Shader: point to your vertex DAT
- Load Page → Pixel Shader: point to your pixel DAT

---

## Critical Rules

1. **Never declare** the TD-provided vertex attributes — `P`, `N`, `uv[0]`, `Cd`, `T` — they are auto-injected
2. **Never declare** default varyings — `vUV`, `vP`, `vN`, `vColor` — TD provides these if you don't supply a custom vertex shader
3. **Always call** `TDDeform(P)` before `TDWorldToProj()` — skipping it breaks instancing and skinning
4. **Always match** varyings: every `out` in the vertex shader needs an `in` in the pixel shader with the same name and type
5. **No `#version` directive** — TouchDesigner injects it automatically
6. **Pixel shader output** uses `layout(location = 0) out vec4 fragColor;` (with layout qualifier, unlike GLSL TOP)

---

## Auto-Provided Vertex Attributes (DO NOT Declare)

```glsl
P       // vec3  — vertex position in object/local space
N       // vec3  — vertex normal in object space
uv[0]   // vec4  — texture coordinate layer 0 (uv[1], uv[2]... for additional layers)
Cd      // vec4  — vertex color (RGBA)
T       // vec4  — tangent vector (for normal mapping)
```

These are injected by TD at compile time. Declaring them yourself causes errors.

---

## Core Vertex Functions

```glsl
// Transform local position → world space (applies instancing + skinning)
vec4 TDDeform(vec3 pos)
vec4 TDDeform(vec4 pos)

// Transform world/view space → clip space (NDC for gl_Position)
vec4 TDWorldToProj(vec4 worldPos)
vec4 TDWorldToProj(vec3 worldPos)

// Per-instance unique ID (use for per-instance variation)
int TDInstanceID()

// Camera index (for multi-camera / stereo rendering)
int TDCameraIndex()
```

The standard transform chain: `gl_Position = TDWorldToProj(TDDeform(P));`

---

## Key Uniform Structs

```glsl
// Transformation matrices — indexed by camera (use TDCameraIndex())
struct TDMatrix {
    mat4 world;              // Object → world
    mat4 worldCam;           // Object → camera
    mat4 cam;                // World → camera (view matrix)
    mat4 proj;               // Camera → clip (projection)
    mat4 worldCamProj;       // Combined MVP
    mat3 worldForNormals;    // Inverse-transpose for normal transform
    mat3 worldCamForNormals; // Normal matrix in camera space
};
uniform TDMatrix uTDMats[TD_NUM_CAMERAS];
```

Transform normals correctly:
```glsl
// ❌ Wrong — does not handle non-uniform scale
vec3 worldNormal = mat3(uTDMats[0].world) * N;

// ✅ Correct — uses inverse-transpose
vec3 worldNormal = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
```

---

## Varyings — Passing Data Vertex → Pixel

Declare `out` in vertex, matching `in` in pixel:

```glsl
// Vertex shader
out vec2  vTexCoord;   // UV coordinates
out vec3  vWorldNorm;  // World-space normal
out vec4  vVertColor;  // Vertex color passthrough
out float vDisplace;   // Any scalar

// Pixel shader (must match exactly)
in vec2  vTexCoord;
in vec3  vWorldNorm;
in vec4  vVertColor;
in float vDisplace;
```

The GPU interpolates these values across each triangle — what arrives in the pixel shader is a smooth blend across the surface.

See [reference/VARYINGS.md](reference/VARYINGS.md) for full patterns.

---

## Instancing

When Render TOP has instancing enabled, each instance gets a unique `TDInstanceID()`. You can sample per-instance data from a CHOP or texture:

```glsl
uniform sampler2D uInstanceData;  // CHOP/texture with per-instance values
uniform int uInstanceCount;

void main() {
    int id = TDInstanceID();

    // Sample per-instance position offset from texture row
    float u = (float(id) + 0.5) / float(uInstanceCount);
    vec4 offset = texture(uInstanceData, vec2(u, 0.5));

    vec4 worldPos = TDDeform(P + offset.xyz);
    gl_Position   = TDWorldToProj(worldPos);
    ...
}
```

---

## Common Patterns

See [reference/VERTEX-API.md](reference/VERTEX-API.md) for the complete function reference.

### Vertex Displacement
```glsl
uniform float uDisplaceAmount;
uniform float uTime;

void main() {
    // Displace along local normal
    float noise = TDSimplexNoise(vec3(P * 2.0 + uTime * 0.5));
    vec3 displaced = P + N * noise * uDisplaceAmount;

    gl_Position = TDWorldToProj(TDDeform(displaced));
}
```

### Wave Deformation
```glsl
uniform float uFrequency;
uniform float uAmplitude;
uniform float uTime;

void main() {
    vec3 pos = P;
    pos.y += sin(pos.x * uFrequency + uTime) * uAmplitude;
    pos.y += sin(pos.z * uFrequency * 0.7 + uTime * 1.3) * uAmplitude * 0.5;

    gl_Position = TDWorldToProj(TDDeform(pos));
}
```

---

## Response Format

When writing a GLSL MAT shader, always provide:

1. **Vertex Shader** — complete GLSL code with comments
2. **Pixel Shader** — complete GLSL code, matching all varyings
3. **TouchDesigner Setup**:
   - Load Page: which DAT goes in Vertex Shader / Pixel Shader fields
   - Uniforms: parameter page, name, type, value or expression
   - Render setup notes if instancing or lighting is involved

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `'P' : redefinition` | Declared `P` in shader | Remove your declaration — TD provides it |
| Black / no geometry | Forgot `TDDeform()` | Use `TDDeform(P)` before `TDWorldToProj()` |
| Varyings mismatch | Name/type differs between stages | Verify `out` ↔ `in` names and types match exactly |
| Instancing broken | Manual position, no `TDDeform` | Always route through `TDDeform()` |
| Normal flipping | Wrong normal transform | Use `worldForNormals` matrix, not `world` |
| `layout` error | Missing `layout(location=0)` | Pixel output must be `layout(location = 0) out vec4 fragColor;` |

---

## Additional Resources

- [reference/VERTEX-API.md](reference/VERTEX-API.md) — Complete TD vertex function reference
- [reference/VARYINGS.md](reference/VARYINGS.md) — Varying patterns & interpolation modes
- [reference/LIGHTING.md](reference/LIGHTING.md) — Phong and PBR lighting in pixel shaders
- [templates/basic.glsl](templates/basic.glsl) — Minimal vertex + pixel pair
- [templates/displacement.glsl](templates/displacement.glsl) — Vertex displacement + pixel
- [templates/instancing.glsl](templates/instancing.glsl) — Instancing-aware shader
- [templates/lit.glsl](templates/lit.glsl) — Full Phong-lit material
