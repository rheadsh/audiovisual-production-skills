# TouchDesigner GLSL MAT — Vertex Shader API Reference

Complete reference for vertex-stage attributes, functions, and uniforms available in GLSL MAT.

---

## Auto-Provided Vertex Attributes

These are **injected by TouchDesigner at compile time**. Do NOT re-declare them.

```glsl
attribute vec3 P;      // Vertex position in object/local space
attribute vec3 N;      // Vertex normal in object space (unit length)
attribute vec4 uv[8];  // Texture coordinate layers (uv[0] = layer 0, etc.)
attribute vec4 Cd;     // Vertex color (RGBA, 0–1 range)
attribute vec4 T;      // Tangent vector (for normal mapping; xyz=tangent, w=handedness)
```

### Accessing UV layers

```glsl
vec2 texcoord  = uv[0].st;   // Standard UV (st components)
vec2 layer1    = uv[1].st;   // Second UV layer
```

### Custom Vertex Attributes

Custom attributes defined on the SOP (via Attribute SOP or Python) are accessed via a TD macro:

```glsl
// Attribute named "myFloat" (float type)
float customVal = TDAttrib_myFloat();

// Attribute named "myVec3" (vec3 type)
vec3 customPos = TDAttrib_myVec3();
```

Declare them on the **Attributes** page of the GLSL MAT to make TD inject them.

---

## Core Vertex Functions

### `TDDeform(pos)` — World-Space Deform

```glsl
vec4 TDDeform(vec3 pos)
vec4 TDDeform(vec4 pos)
```

Applies the full deformation pipeline (instancing transforms, soft-body skinning, bones) and returns the final **world-space position**. Always use this instead of manually multiplying by `uTDMats[n].world`.

```glsl
// Correct
vec4 worldPos = TDDeform(P);
gl_Position   = TDWorldToProj(worldPos);

// Incorrect — bypasses instancing
vec4 worldPos = uTDMats[0].world * vec4(P, 1.0);
```

You can also deform a modified position (for displacement):
```glsl
vec3 displaced = P + N * noiseAmount;
vec4 worldPos  = TDDeform(displaced);
```

---

### `TDWorldToProj(v)` — World → Clip Space

```glsl
vec4 TDWorldToProj(vec4 worldPos)
vec4 TDWorldToProj(vec3 worldPos)
```

Transforms a world-space position into **clip space** (what `gl_Position` expects). Internally multiplies by the combined view-projection matrix for the active camera.

```glsl
gl_Position = TDWorldToProj(TDDeform(P));
```

For multi-camera rendering, this automatically selects the correct camera's matrix.

---

### `TDInstanceID()` — Instance Index

```glsl
int TDInstanceID()
```

Returns the 0-based index of the current instance (when Render TOP instancing is active). Each instance of the geometry gets a unique ID, which you can use to sample per-instance data from textures or CHOPs.

```glsl
int id   = TDInstanceID();
float t  = (float(id) + 0.5) / float(uInstanceCount);
vec4 col = texture(uInstanceTex, vec2(t, 0.5));
```

---

### `TDCameraIndex()` — Active Camera

```glsl
int TDCameraIndex()
```

Returns the index (0-based) of the camera currently being rendered. Use this to index into `uTDMats` when doing multi-camera or stereo rendering.

```glsl
mat4 MVP    = uTDMats[TDCameraIndex()].worldCamProj;
mat3 normMat = uTDMats[TDCameraIndex()].worldForNormals;
```

---

## Transformation Matrices — `uTDMats`

```glsl
struct TDMatrix {
    mat4 world;              // Object space → world space
    mat4 worldCam;           // Object space → camera space
    mat4 cam;                // World space → camera space (view matrix)
    mat4 proj;               // Camera space → clip space (projection)
    mat4 worldCamProj;       // Combined: object → clip (MVP)
    mat3 worldForNormals;    // Correct matrix for normals: inverse-transpose of world
    mat3 worldCamForNormals; // Correct matrix for normals in camera space
};
uniform TDMatrix uTDMats[TD_NUM_CAMERAS];
```

### Normal Transformation

Normals must be transformed with the **inverse-transpose** of the model matrix, not the model matrix itself. TD provides this as `worldForNormals`:

```glsl
// ✅ Correct — handles non-uniform scale properly
vec3 worldNormal = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);

// ❌ Wrong — breaks with non-uniform scale
vec3 worldNormal = normalize(mat3(uTDMats[TDCameraIndex()].world) * N);
```

---

## Noise Functions (Available in Vertex Stage)

Same functions as GLSL TOP — fully available in vertex shaders.

```glsl
float TDSimplexNoise(vec2 p)
float TDSimplexNoise(vec3 p)
float TDSimplexNoise(vec4 p)

float TDPerlinNoise(vec2 p)
float TDPerlinNoise(vec3 p)
float TDPerlinNoise(vec4 p)
```

Great for vertex displacement without needing a texture:

```glsl
float n = TDSimplexNoise(vec3(P * 3.0 + uTime * 0.5));
vec3 displaced = P + N * n * uDisplaceAmount;
```

---

## GLSL Built-in Vertex Outputs

```glsl
vec4  gl_Position;     // REQUIRED — clip-space position
float gl_PointSize;    // For point primitives: size in pixels
```

`gl_Position` must be written in every vertex shader execution. `gl_PointSize` only matters if you're rendering point clouds.

---

## Compile-Time Defines

TouchDesigner sets these as `#define` values before compilation:

```glsl
TD_NUM_LIGHTS       // Number of lights in the scene
TD_NUM_CAMERAS      // Number of cameras (usually 1, 2 for stereo)
TD_VERTEX_SHADER    // Defined only in vertex stage (use for shared code)
TD_PIXEL_SHADER     // Defined only in pixel stage
```

Use for conditional compilation in shared code:

```glsl
#ifdef TD_VERTEX_SHADER
    // Vertex-only code
#endif
```

---

## Lighting Uniforms (Read in Vertex, Used in Pixel)

These are available in both stages but are typically only sampled in the pixel shader:

```glsl
struct TDLight {
    vec4 position;        // World-space position (w=1 point, w=0 directional)
    vec4 direction;       // World-space direction (for directional lights)
    vec4 diffuse;         // Diffuse color (RGB) and intensity (A)
    vec4 specular;        // Specular color (RGB) and shininess (A)
    vec4 ambient;         // Ambient contribution
    float attenuationStart;
    float attenuationEnd;
    mat4 shadowMapMatrix;
    mat4 projMapMatrix;
};
uniform TDLight uTDLights[TD_NUM_LIGHTS];
```

---

## Practical Patterns

### Pass UV to Pixel Shader
```glsl
out vec2 vTexCoord;

void main() {
    vTexCoord   = uv[0].st;
    gl_Position = TDWorldToProj(TDDeform(P));
}
```

### Pass World Position + Normal
```glsl
out vec3 vWorldPos;
out vec3 vWorldNorm;

void main() {
    vec4 worldPos = TDDeform(P);
    vWorldPos     = worldPos.xyz;
    vWorldNorm    = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    gl_Position   = TDWorldToProj(worldPos);
}
```

### Vertex Color Passthrough
```glsl
out vec4 vColor;

void main() {
    vColor      = Cd;
    gl_Position = TDWorldToProj(TDDeform(P));
}
```

### Noise Displacement
```glsl
uniform float uAmount;
uniform float uFrequency;
uniform float uTime;

out vec3 vWorldPos;
out vec3 vWorldNorm;

void main() {
    float n   = TDSimplexNoise(vec3(P * uFrequency + uTime * 0.3));
    vec3 disp = P + N * n * uAmount;

    vec4 worldPos = TDDeform(disp);
    vWorldPos     = worldPos.xyz;
    vWorldNorm    = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    gl_Position   = TDWorldToProj(worldPos);
}
```

**TD Setup**: Vectors page → `uAmount` float, `uFrequency` float, `uTime` float = `absTime.seconds`
