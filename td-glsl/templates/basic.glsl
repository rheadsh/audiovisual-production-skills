// ============================================
// BASIC TOUCHDESIGNER GLSL SHADER TEMPLATE
// Copy this as a starting point for new shaders
// ============================================

// UNIFORMS
uniform float uTime;

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    vec2 uv = vUV.st;
    
    // Your shader logic here
    vec4 color = texture(sTD2DInputs[0], uv);
    
    fragColor = TDOutputSwizzle(color);
}
