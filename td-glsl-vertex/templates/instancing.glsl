// ============================================================
// INSTANCING GLSL MAT
// Per-instance color and scale variation using a texture
// that stores RGBA data per instance row (e.g. from a CHOP
// exported to TOP, or any data texture).
//
// Render TOP → Instancing must be enabled, connected to a
// CHOP with enough samples for instance count.
// ============================================================

// ---- VERTEX SHADER ----

uniform sampler2D uColorTex;    // Data texture: 1 pixel per instance, RGBA = color
uniform int       uInstanceCount;  // Total number of instances
uniform float     uScaleVariation; // How much scale differs between instances (0–1)
uniform float     uTime;

flat out vec4 vInstanceColor;  // flat = no interpolation, same for whole primitive
out vec3 vWorldPos;
out vec3 vWorldNorm;
out vec2 vTexCoord;

void main() {
    int   id = TDInstanceID();

    // Sample per-instance color from data texture (center of each pixel row)
    float u  = (float(id) + 0.5) / float(uInstanceCount);
    vInstanceColor = texture(uColorTex, vec2(u, 0.5));

    // Scale variation — each instance gets a slightly different size
    // Use the red channel of the color texture as a scale factor, or generate
    float scaleNoise = TDSimplexNoise(vec2(float(id) * 0.37, uTime * 0.1));
    float scale = 1.0 + scaleNoise * uScaleVariation;

    // Apply scale in object space before deforming
    vec3 scaledPos = P * scale;

    // Deform (applies instance transform from Render TOP instancing CHOP)
    vec4 worldPos = TDDeform(scaledPos);

    // Standard varyings
    vWorldPos  = worldPos.xyz;
    vWorldNorm = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    vTexCoord  = uv[0].st;

    gl_Position = TDWorldToProj(worldPos);
}


// ---- PIXEL SHADER ----

flat in vec4 vInstanceColor;
in vec3 vWorldPos;
in vec3 vWorldNorm;
in vec2 vTexCoord;

layout(location = 0) out vec4 fragColor;

uniform float uShininess;  // Specular sharpness (default: 32.0)
uniform float uAmbient;    // Ambient intensity (default: 0.1)

void main() {
    TDCheckDiscard();

    vec3 norm    = normalize(vWorldNorm);
    vec3 albedo  = vInstanceColor.rgb;

    // Accumulate scene lighting — Phong per light
    vec4 litColor = vec4(0.0);
    for (int i = 0; i < TD_NUM_LIGHTS; i++) {
        litColor += TDLighting(
            i,
            vWorldPos,
            norm,
            albedo,
            uShininess,
            vec3(1.0)   // White specular
        );
    }

    // Ambient fill
    litColor.rgb += albedo * uAmbient;

    // Preserve instance alpha
    litColor.a = vInstanceColor.a;

    litColor  = TDFog(litColor, vWorldPos, TDCameraIndex());
    fragColor = TDOutputSwizzle(litColor);
}


// ---- TOUCHDESIGNER SETUP ----
// 1. GLSL MAT → Load Page → Vertex Shader / Pixel Shader: point to your DATs
//
// 2. GLSL MAT → Samplers page:
//      Name: uColorTex
//      Type: 2D
//      Connect a CHOP → TOP (or Movie File In TOP) with one pixel per instance
//      For a quick test: Noise TOP with W=instanceCount, H=1
//
// 3. GLSL MAT → Vectors page:
//      uInstanceCount   int   (match Render TOP instance count, or use Python expr)
//      uScaleVariation  float  0.3
//      uTime            float  absTime.seconds
//      uShininess       float  32.0
//      uAmbient         float  0.1
//
// 4. Render TOP → Instancing page:
//      Enable instancing, connect transform CHOPs (tx, ty, tz channels etc.)
//
// TIP: To drive uColorTex from a CHOP (e.g. 3 channels r/g/b per instance):
//      CHOP → CHOP to TOP → set the TOP format to RGBA32Float, connect to MAT sampler
