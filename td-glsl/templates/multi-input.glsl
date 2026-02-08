// ============================================
// MULTI-INPUT TEMPLATE
// For compositing/blending multiple inputs
// ============================================

// UNIFORMS
uniform float uBlend;
uniform float uTime;

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    vec2 uv = vUV.st;
    
    // Sample inputs
    vec4 input1 = texture(sTD2DInputs[0], uv);
    vec4 input2 = texture(sTD2DInputs[1], uv);
    
    // Blend logic
    vec4 color = mix(input1, input2, uBlend);
    
    fragColor = TDOutputSwizzle(color);
}
