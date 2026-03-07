// ============================================
// GLSL COPY POP TEMPLATE
// Duplicate geometry with per-copy transforms
// ============================================

// UNIFORMS
uniform float uSpacing;
uniform float uTime;

// MAIN
void main() {
    const uint id = TDIndex();
    if (id >= TDNumPoints())
        return;

    vec3 pos = TDIn_P();

    // Offset each copy
    pos.x += float(TDCopyIndex()) * uSpacing;

    // Write output
    P[id] = pos;

    // Preserve group membership
    TDUpdatePointGroups();
}
