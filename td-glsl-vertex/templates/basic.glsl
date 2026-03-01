// ============================================================
// BASIC GLSL MAT — Vertex + Pixel Shader
// Minimal vertex + pixel pair. Good starting point.
// No lighting. Passes UV and vertex color to pixel stage.
// ============================================================

// ---- VERTEX SHADER (paste into a Text DAT, e.g. "glsl_vert") ----

out vec2 vTexCoord;   // UV coordinates → pixel shader
out vec4 vVertColor;  // Vertex color → pixel shader
out vec3 vWorldPos;   // World-space position → pixel shader

void main() {
    // Deform applies instancing, skinning → world space position
    vec4 worldPos = TDDeform(P);

    // Pass data to pixel shader
    vTexCoord  = uv[0].st;
    vVertColor = Cd;
    vWorldPos  = worldPos.xyz;

    // Project to clip space — required final step
    gl_Position = TDWorldToProj(worldPos);
}


// ---- PIXEL SHADER (paste into a Text DAT, e.g. "glsl_frag") ----

in vec2 vTexCoord;
in vec4 vVertColor;
in vec3 vWorldPos;

layout(location = 0) out vec4 fragColor;

void main() {
    // Sample texture from first input slot (connect a TOP to GLSL MAT input)
    vec4 color = texture(sTD2DInputs[0], vTexCoord);

    // Modulate by vertex color
    color *= vVertColor;

    // TDOutputSwizzle handles color space and channel swizzle
    fragColor = TDOutputSwizzle(color);
}


// ---- TOUCHDESIGNER SETUP ----
// 1. Create a GLSL MAT
// 2. Load Page → Vertex Shader: drag your vertex Text DAT
// 3. Load Page → Pixel Shader: drag your pixel Text DAT
// 4. Connect a TOP to the GLSL MAT's first input (for texture)
// 5. Assign the GLSL MAT to a Geometry COMP
