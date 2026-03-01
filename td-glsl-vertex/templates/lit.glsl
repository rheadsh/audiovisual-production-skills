// ============================================================
// FULL LIT GLSL MAT — Vertex + Pixel Shader
// Complete Phong material with:
//   - Diffuse texture (slot 0)
//   - Normal map (slot 1, tangent space)
//   - Specular texture (slot 2, optional)
//   - Fog integration
//   - OIT-compatible TDCheckDiscard()
//
// Vertex shader builds a full TBN matrix for normal mapping.
// ============================================================

// ---- VERTEX SHADER ----

out vec3 vWorldPos;
out vec2 vTexCoord;
out mat3 vTBN;      // Tangent-Bitangent-Normal matrix (world space)

void main() {
    vec4 worldPos = TDDeform(P);

    // --- Build TBN for normal mapping ---
    // Use the dedicated normal matrix (inverse-transpose of world) for N
    mat3 normMat  = uTDMats[TDCameraIndex()].worldForNormals;
    vec3 wN       = normalize(normMat * N);
    // Tangent T from the tangent attribute (T.w = handedness / sign)
    vec3 wT       = normalize(mat3(uTDMats[TDCameraIndex()].world) * T.xyz);
    // Re-orthogonalize T with respect to N (Gram-Schmidt)
    wT            = normalize(wT - dot(wT, wN) * wN);
    // Bitangent is derived from N cross T, T.w holds the handedness sign
    vec3 wB       = cross(wN, wT) * T.w;

    vTBN       = mat3(wT, wB, wN);
    vWorldPos  = worldPos.xyz;
    vTexCoord  = uv[0].st;

    gl_Position = TDWorldToProj(worldPos);
}


// ---- PIXEL SHADER ----

in vec3 vWorldPos;
in vec2 vTexCoord;
in mat3 vTBN;

layout(location = 0) out vec4 fragColor;

// Material uniforms
uniform vec4  uDiffuseTint;    // Multiplied on top of diffuse texture (default: 1,1,1,1)
uniform float uShininess;      // Specular power — higher = tighter highlight (default: 64.0)
uniform vec3  uSpecularColor;  // Specular highlight color (default: 1,1,1)
uniform float uNormalStrength; // Normal map intensity 0–1 (default: 1.0)
uniform float uAmbient;        // Ambient fill intensity (default: 0.1)
uniform float uEmissive;       // Self-glow multiplier on diffuse color (default: 0.0)

// Texture inputs (connected via GLSL MAT inputs)
// sTD2DInputs[0] = diffuse/albedo texture
// sTD2DInputs[1] = normal map (tangent space, RGB → XYZ -1..1)
// sTD2DInputs[2] = specular map (grayscale or RGB)

void main() {
    TDCheckDiscard();

    // --- Sample Textures ---
    vec4 diffuseSample   = texture(sTD2DInputs[0], vTexCoord) * uDiffuseTint;
    vec3 normalSample    = texture(sTD2DInputs[1], vTexCoord).rgb;
    float specularSample = texture(sTD2DInputs[2], vTexCoord).r;

    // --- Reconstruct Normal from Normal Map ---
    // Normal map stores [0,1], remap to [-1,1]
    vec3 tsNormal = normalSample * 2.0 - 1.0;
    // Blend between flat normal (0,0,1) and map normal by uNormalStrength
    tsNormal = normalize(mix(vec3(0.0, 0.0, 1.0), tsNormal, uNormalStrength));
    // Transform tangent-space normal to world space via TBN
    vec3 worldNorm = normalize(vTBN * tsNormal);

    // --- Lighting Accumulation ---
    vec3 specular = uSpecularColor * specularSample;
    vec4 litColor = vec4(0.0);

    for (int i = 0; i < TD_NUM_LIGHTS; i++) {
        litColor += TDLighting(
            i,
            vWorldPos,
            worldNorm,
            diffuseSample.rgb,
            uShininess,
            specular
        );
    }

    // Ambient + emissive fills
    litColor.rgb += diffuseSample.rgb * uAmbient;
    litColor.rgb += diffuseSample.rgb * uEmissive;
    litColor.a    = diffuseSample.a;

    // Fog
    litColor  = TDFog(litColor, vWorldPos, TDCameraIndex());
    fragColor = TDOutputSwizzle(litColor);
}


// ---- TOUCHDESIGNER SETUP ----
// GLSL MAT → Load Page:
//   Vertex Shader: (your vertex DAT)
//   Pixel Shader:  (your pixel DAT)
//
// GLSL MAT → Inputs: connect textures to input slots
//   Slot 0 → Diffuse / Albedo TOP
//   Slot 1 → Normal Map TOP (tangent space)
//   Slot 2 → Specular Map TOP (or a Constant TOP white/black)
//
// GLSL MAT → Colors 1:  uDiffuseTint     vec4   1.0, 1.0, 1.0, 1.0
// GLSL MAT → Colors 2:  uSpecularColor   vec3   1.0, 1.0, 1.0
// GLSL MAT → Vectors 1: uShininess       float  64.0
// GLSL MAT → Vectors 2: uNormalStrength  float  1.0
// GLSL MAT → Vectors 3: uAmbient         float  0.1
// GLSL MAT → Vectors 4: uEmissive        float  0.0
//
// NOTES:
//   • Connect at least one Light COMP to the Render TOP for TDLighting() to work.
//   • If you don't have a normal map, connect a Constant TOP (0.5, 0.5, 1.0) to slot 1.
//   • If you don't have a specular map, connect a Constant TOP (white) to slot 2
//     and control specular purely via uSpecularColor.
//   • For the TBN matrix to work correctly, the SOP must have tangent attributes.
//     Add a Attribute SOP set to "Tangents" if the geometry has none.
