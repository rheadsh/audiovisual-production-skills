// ============================================
// GLSL ADVANCED POP TEMPLATE
// Read/write points, verts, and prims simultaneously
// ============================================

// UNIFORMS
uniform float uTime;

// MAIN
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // Read point attributes (class-prefixed)
    vec3 pos = TDInPoint_P();
    vec4 col = TDInPoint_Cd();

    // Your logic here
    pos.y += sin(pos.x + uTime) * 0.5;

    // Write point outputs (class-prefixed)
    oTDPoint_P[id] = pos;
    oTDPoint_Cd[id] = col;
}
