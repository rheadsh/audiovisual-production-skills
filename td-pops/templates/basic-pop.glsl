// ============================================
// BASIC GLSL POP TEMPLATE
// Modify point attributes on a single class
// ============================================

// UNIFORMS
uniform float uTime;

// MAIN
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // Read input attributes
    vec3 pos = TDIn_P();

    // Your logic here
    pos.y += sin(uTime) * 0.1;

    // Write output
    P[id] = pos;
}
