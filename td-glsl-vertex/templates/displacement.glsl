// ============================================================
// VERTEX DISPLACEMENT GLSL MAT
// Pushes vertices along their normals using Simplex noise.
// Displacement amount is animated over time.
// Pixel shader colorizes the surface based on displacement.
// ============================================================

// ---- VERTEX SHADER ----

// Uniforms — declare here, configure in TD's Vectors parameter page
uniform float uDisplaceAmount;  // Strength of displacement (default: 0.1)
uniform float uFrequency;       // Noise frequency / scale (default: 3.0)
uniform float uTime;            // Animate noise (connect to absTime.seconds)
uniform float uSpeed;           // Animation speed multiplier (default: 0.5)

// Varyings
out vec3 vWorldPos;
out vec3 vWorldNorm;
out vec2 vTexCoord;
out float vDisplace;  // Pass raw displacement to pixel for color mapping

void main() {
    // Sample 3D simplex noise using object-space position + time
    float noise = TDSimplexNoise(vec3(P * uFrequency + uTime * uSpeed));

    // Displace vertex along its local normal
    vec3 displaced = P + N * noise * uDisplaceAmount;

    // Deform (instancing / skinning) → world space
    vec4 worldPos = TDDeform(displaced);

    // Build world-space normal for pixel-side lighting
    // NOTE: We're using the original normal here — for accurate normals after
    // displacement, you'd need to compute them analytically or via finite diff.
    vWorldNorm = normalize(uTDMats[TDCameraIndex()].worldForNormals * N);
    vWorldPos  = worldPos.xyz;
    vTexCoord  = uv[0].st;
    vDisplace  = noise;  // -1..1 range, interpolated across the surface

    gl_Position = TDWorldToProj(worldPos);
}


// ---- PIXEL SHADER ----

in vec3 vWorldPos;
in vec3 vWorldNorm;
in vec2 vTexCoord;
in float vDisplace;

layout(location = 0) out vec4 fragColor;

// Color gradient: map displacement to hue
uniform vec3 uColorLow;   // Color at minimum displacement (default: 0.1, 0.3, 0.8)
uniform vec3 uColorHigh;  // Color at maximum displacement (default: 0.9, 0.4, 0.1)
uniform float uAmbient;   // Ambient light intensity (default: 0.15)

void main() {
    TDCheckDiscard();  // Required for OIT transparency

    vec3 norm = normalize(vWorldNorm);

    // Remap displacement from -1..1 → 0..1
    float t = vDisplace * 0.5 + 0.5;

    // Gradient color based on displacement amount
    vec3 baseColor = mix(uColorLow, uColorHigh, t);

    // Simple directional lighting from above (+Y) for depth
    vec3 lightDir = normalize(vec3(0.5, 1.0, 0.5));
    float diff    = max(dot(norm, lightDir), 0.0);

    vec3 finalColor = baseColor * (diff + uAmbient);

    fragColor = TDOutputSwizzle(vec4(finalColor, 1.0));
}


// ---- TOUCHDESIGNER SETUP ----
// GLSL MAT → Load Page:
//   Vertex Shader: displacement vertex DAT
//   Pixel Shader:  displacement pixel DAT
//
// GLSL MAT → Vectors 1:  uDisplaceAmount  float  0.1
// GLSL MAT → Vectors 2:  uFrequency       float  3.0
// GLSL MAT → Vectors 3:  uTime            float  absTime.seconds
// GLSL MAT → Vectors 4:  uSpeed           float  0.5
// GLSL MAT → Vectors 5:  uAmbient         float  0.15
// GLSL MAT → Colors  1:  uColorLow        vec3   0.1, 0.3, 0.8
// GLSL MAT → Colors  2:  uColorHigh       vec3   0.9, 0.4, 0.1
//
// TIP: Feed a higher-tesselation SOP (e.g., Sphere SOP with high divs)
//      to get smoother displacement. Low-poly meshes show faceting.
