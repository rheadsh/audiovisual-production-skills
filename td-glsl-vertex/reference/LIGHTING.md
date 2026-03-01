# Lighting in GLSL MAT Pixel Shaders

TouchDesigner provides high-level lighting functions that integrate with its light operators. These are only available in the **pixel shader stage**.

---

## TD Lighting Functions

### `TDLighting()` — Phong / Per-Light

```glsl
vec4 TDLighting(
    int   lightIndex,       // Index into uTDLights[] (0-based)
    vec3  worldSpacePos,    // Surface position in world space
    vec3  worldSpaceNorm,   // Surface normal in world space (unit length)
    vec3  diffuseColor,     // Material diffuse color
    float shininess,        // Specular power (e.g. 32.0)
    vec3  specularColor     // Material specular color
)
```

Returns a `vec4` containing the lit color for that single light (RGBA).

### `TDLightingPBR()` — Physically Based

```glsl
TDPBRResult TDLightingPBR(
    int   lightIndex,
    vec3  worldSpacePos,
    vec3  worldSpaceNorm,
    vec3  albedo,
    float roughness,
    float metallic,
    vec3  F0            // Fresnel reflectance at normal incidence
)
```

Returns a `TDPBRResult` struct with `.diffuse` and `.specular` vec4 fields.

### `TDFog()` — Apply Scene Fog

```glsl
vec4 TDFog(vec4 color, vec3 worldPos, int camIndex)
```

Applies the scene's fog settings to a color, based on distance from camera.

### `TDCheckDiscard()` — Order-Independent Transparency

```glsl
void TDCheckDiscard()
```

Call at the very start of `main()` in pixel shaders when using the Render TOP's OIT (order-independent transparency) feature. Handles the discard logic for transparent surfaces.

---

## Full Phong Lit Material Example

```glsl
// ============================================
// PHONG LIT MATERIAL — Pixel Shader
// ============================================

// Input varyings from vertex shader
in vec3 vWorldPos;
in vec3 vWorldNorm;
in vec2 vTexCoord;

layout(location = 0) out vec4 fragColor;

uniform vec4  uDiffuseColor;   // Material base color
uniform float uShininess;      // Specular sharpness (4–256)
uniform vec3  uSpecularColor;  // Specular highlight color
uniform float uAmbient;        // Ambient intensity

void main() {
    TDCheckDiscard();  // Required for OIT transparency

    vec3 norm   = normalize(vWorldNorm);
    vec3 albedo = uDiffuseColor.rgb;

    // Sample diffuse texture if available
    albedo *= texture(sTD2DInputs[0], vTexCoord).rgb;

    // Accumulate all scene lights
    vec4 litColor = vec4(0.0);
    for (int i = 0; i < TD_NUM_LIGHTS; i++) {
        litColor += TDLighting(
            i,
            vWorldPos,
            norm,
            albedo,
            uShininess,
            uSpecularColor
        );
    }

    // Add ambient
    litColor.rgb += albedo * uAmbient;

    // Apply fog
    litColor = TDFog(litColor, vWorldPos, TDCameraIndex());

    fragColor = TDOutputSwizzle(litColor);
}
```

**Vertex shader companion:**
```glsl
out vec3 vWorldPos;
out vec3 vWorldNorm;
out vec2 vTexCoord;

void main() {
    vec4 worldPos = TDDeform(P);
    vWorldPos     = worldPos.xyz;
    vWorldNorm    = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    vTexCoord     = uv[0].st;
    gl_Position   = TDWorldToProj(worldPos);
}
```

**TD Setup**:
- Colors 1 → `uDiffuseColor` (vec4) = `1.0, 1.0, 1.0, 1.0`
- Vectors 1 → `uShininess` (float) = `32.0`
- Colors 2 → `uSpecularColor` (vec3) = `1.0, 1.0, 1.0`
- Vectors 2 → `uAmbient` (float) = `0.1`

---

## PBR Material Example

```glsl
// ============================================
// PBR MATERIAL — Pixel Shader
// ============================================

in vec3 vWorldPos;
in vec3 vWorldNorm;
in vec2 vTexCoord;

layout(location = 0) out vec4 fragColor;

uniform vec3  uAlbedo;
uniform float uRoughness;
uniform float uMetallic;

void main() {
    TDCheckDiscard();

    vec3 norm     = normalize(vWorldNorm);
    vec3 albedo   = uAlbedo * texture(sTD2DInputs[0], vTexCoord).rgb;
    vec3 F0       = mix(vec3(0.04), albedo, uMetallic); // Dielectric vs metal

    vec4 litColor = vec4(0.0);
    for (int i = 0; i < TD_NUM_LIGHTS; i++) {
        TDPBRResult pbr = TDLightingPBR(
            i,
            vWorldPos,
            norm,
            albedo,
            uRoughness,
            uMetallic,
            F0
        );
        litColor += pbr.diffuse + pbr.specular;
    }

    litColor = TDFog(litColor, vWorldPos, TDCameraIndex());
    fragColor = TDOutputSwizzle(litColor);
}
```

**TD Setup**:
- Colors 1 → `uAlbedo` (vec3) = `0.8, 0.5, 0.2`
- Vectors 1 → `uRoughness` (float) = `0.5`
- Vectors 2 → `uMetallic` (float) = `0.0`

---

## Unlit Material (No Lighting)

For effects that don't need lighting (glowing, screen-space, pure color):

```glsl
// Pixel shader — unlit
in vec2 vTexCoord;
in vec4 vColor;

layout(location = 0) out vec4 fragColor;

void main() {
    vec4 col  = texture(sTD2DInputs[0], vTexCoord);
    col      *= vColor;
    fragColor = TDOutputSwizzle(col);
}
```

No `TDLighting()` calls needed. Works great with emissive/additive blending setups.

---

## Two-Sided Materials

When **Two-Sided** is enabled on the GLSL MAT, you can differentiate front and back faces using the built-in `gl_FrontFacing` variable (pixel stage only):

```glsl
in vec3 vWorldNorm;

layout(location = 0) out vec4 fragColor;

uniform vec4 uFrontColor;
uniform vec4 uBackColor;

void main() {
    // Flip normal for back faces
    vec3 norm = gl_FrontFacing ? normalize(vWorldNorm)
                               : -normalize(vWorldNorm);

    vec4 color = gl_FrontFacing ? uFrontColor : uBackColor;

    // ... lighting with flipped norm
    fragColor = TDOutputSwizzle(color);
}
```

---

## Accessing Textures in the Pixel Shader

```glsl
// Standard GLSL TOP inputs (index by slot)
texture(sTD2DInputs[0], texcoord)   // First input slot of the GLSL MAT
texture(sTD2DInputs[1], texcoord)   // Second input slot

// Cube map
texture(sTDCubeInputs[0], direction)

// 3D texture
texture(sTD3DInputs[0], vec3(s, t, r))
```

---

## Quick Reference: When to Call What

| Task | Function |
|------|----------|
| Phong lighting | `TDLighting(lightIndex, pos, norm, diffuse, shininess, spec)` |
| PBR lighting | `TDLightingPBR(lightIndex, pos, norm, albedo, rough, metal, F0)` |
| Fog | `TDFog(color, worldPos, TDCameraIndex())` |
| OIT transparency | `TDCheckDiscard()` at start of `main()` |
| Final output | `TDOutputSwizzle(color)` — always wrap final fragColor |
| Texture input | `texture(sTD2DInputs[n], uv)` |
| Camera index | `TDCameraIndex()` for multi-cam `uTDMats` indexing |
