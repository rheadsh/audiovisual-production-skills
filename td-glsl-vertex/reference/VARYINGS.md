# Varyings — Passing Data from Vertex to Pixel Shader

Varyings are the communication bridge between the vertex and pixel stages. They are declared as `out` in the vertex shader and `in` in the pixel shader. The GPU interpolates them smoothly across each triangle.

---

## Declaring Varyings

**Vertex shader:**
```glsl
out vec3  vWorldPos;
out vec3  vWorldNorm;
out vec2  vTexCoord;
out vec4  vColor;
out float vCustom;
```

**Pixel shader (names + types must match exactly):**
```glsl
in vec3  vWorldPos;
in vec3  vWorldNorm;
in vec2  vTexCoord;
in vec4  vColor;
in float vCustom;
```

If a name or type mismatches, the shader will fail to link with an error like `'vWorldPos' : undeclared identifier`.

---

## Default TD Varyings (Free, No Setup Needed)

If you write a **pixel-only shader** (no custom vertex shader), TouchDesigner provides these automatically. If you write a custom vertex shader, you must pass these yourself if you want them in the pixel stage:

```glsl
// Available in pixel shader "for free" from TD's default vertex shader:
vUV     // vec4 — texture coordinates from uv[0] (use .st components)
vP      // vec3 — world-space position
vN      // vec3 — world-space normal
vColor  // vec4 — vertex color from Cd
```

Once you supply a custom vertex shader, TD's default varyings are **replaced**. If your pixel shader references `vUV` but your vertex shader doesn't declare and write `out vec4 vUV`, you'll get an error.

### Passing TD defaults manually (if needed alongside custom ones):
```glsl
// Vertex shader — reproduce TD defaults while adding custom ones
out vec4 vUV;
out vec3 vP;
out vec3 vN;
out vec4 vColor;
out float vMyExtra;

void main() {
    vec4 worldPos = TDDeform(P);

    vUV      = uv[0];
    vP       = worldPos.xyz;
    vN       = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    vColor   = Cd;
    vMyExtra = someComputed;

    gl_Position = TDWorldToProj(worldPos);
}
```

---

## Interpolation Qualifiers

By default, varyings are interpolated linearly (perspective-corrected). You can override this:

```glsl
// Default: smooth perspective-correct interpolation
smooth out vec3 vWorldPos;

// Flat: no interpolation (value from "provoking" vertex, whole triangle is same)
flat out int vInstanceID;
flat out vec4 vFlatColor;

// No perspective correction (pure linear, rarely needed)
noperspective out vec2 vLinearUV;
```

Use `flat` for integer data or any value that shouldn't blend across a face (like instance IDs or face IDs).

---

## Common Varying Patterns

### Basic UV + Normal (Most Common)

```glsl
// Vertex
out vec2 vTexCoord;
out vec3 vWorldNorm;

void main() {
    vec4 worldPos = TDDeform(P);
    vTexCoord  = uv[0].st;
    vWorldNorm = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    gl_Position = TDWorldToProj(worldPos);
}

// Pixel
in vec2 vTexCoord;
in vec3 vWorldNorm;

layout(location = 0) out vec4 fragColor;
void main() {
    vec4 tex   = texture(sTD2DInputs[0], vTexCoord);
    float diff = max(dot(normalize(vWorldNorm), vec3(0, 1, 0)), 0.0);
    fragColor  = TDOutputSwizzle(vec4(tex.rgb * diff, tex.a));
}
```

---

### Tangent Space (Normal Mapping)

```glsl
// Vertex
out vec3 vWorldPos;
out mat3 vTBN;        // Tangent-Bitangent-Normal matrix (3x3)

void main() {
    vec4 worldPos = TDDeform(P);

    // Build TBN matrix in world space
    mat3 normMat  = uTDMats[TDCameraIndex()].worldForNormals;
    vec3 wNormal  = normalize(normMat * N);
    vec3 wTangent = normalize(mat3(uTDMats[TDCameraIndex()].world) * T.xyz);
    // Re-orthogonalize tangent (Gram-Schmidt)
    wTangent      = normalize(wTangent - dot(wTangent, wNormal) * wNormal);
    vec3 wBitang  = cross(wNormal, wTangent) * T.w;  // T.w = handedness

    vWorldPos = worldPos.xyz;
    vTBN      = mat3(wTangent, wBitang, wNormal);
    gl_Position = TDWorldToProj(worldPos);
}

// Pixel
in vec3 vWorldPos;
in mat3 vTBN;

uniform sampler2D uNormalMap;  // sTD2DInputs[1] or declared uniform

layout(location = 0) out vec4 fragColor;
void main() {
    // Sample normal map, remap from [0,1] to [-1,1]
    vec3 tsNormal = texture(sTD2DInputs[1], vUV.st).xyz * 2.0 - 1.0;
    vec3 worldNorm = normalize(vTBN * tsNormal);

    // ...use worldNorm for lighting
}
```

---

### Per-Instance Color (Instancing)

```glsl
// Vertex
flat out vec4 vInstanceColor;

void main() {
    int id   = TDInstanceID();
    float t  = (float(id) + 0.5) / float(uInstanceCount);
    vInstanceColor = texture(uColorTex, vec2(t, 0.5));

    gl_Position = TDWorldToProj(TDDeform(P));
}

// Pixel
flat in vec4 vInstanceColor;  // flat = whole primitive has same value

layout(location = 0) out vec4 fragColor;
void main() {
    fragColor = TDOutputSwizzle(vInstanceColor);
}
```

---

### Displacement Amount for Pixel-Side Effects

```glsl
// Vertex
out float vDisplace;  // Pass displacement scalar to pixel stage

uniform float uAmount;
uniform float uTime;

void main() {
    float n   = TDSimplexNoise(vec3(P * 3.0 + uTime * 0.5));
    vDisplace = n;

    vec3 disp   = P + N * n * uAmount;
    gl_Position = TDWorldToProj(TDDeform(disp));
}

// Pixel — use displacement for color mapping
in float vDisplace;

layout(location = 0) out vec4 fragColor;
void main() {
    float t   = vDisplace * 0.5 + 0.5;         // Remap -1..1 → 0..1
    vec3 col  = mix(vec3(0.1, 0.2, 0.8),        // Cool color
                    vec3(0.9, 0.4, 0.1), t);     // Warm color
    fragColor = TDOutputSwizzle(vec4(col, 1.0));
}
```

---

## Limits

TouchDesigner uses OpenGL 3.3+, which guarantees a minimum of **16 vec4 varying slots**. Each varying costs slots based on its type:

| Type     | Slots |
|----------|-------|
| float    | 1     |
| vec2     | 1     |
| vec3     | 1     |
| vec4     | 1     |
| mat3     | 3     |
| mat4     | 4     |

Pack multiple small varyings into a `vec4` if you're near the limit:

```glsl
// Compact form instead of 3 separate varyings
out vec4 vData1;  // .xy = texcoord, .z = displacement, .w = custom

// In pixel shader:
in vec4 vData1;
vec2  texcoord   = vData1.xy;
float displace   = vData1.z;
float custom     = vData1.w;
```
