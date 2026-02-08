// ============================================
// GENERATIVE PATTERN TEMPLATE
// For creating patterns without input textures
// ============================================

// UNIFORMS
uniform float uTime;
uniform float uAspect;
uniform float uScale;

// CONSTANTS
const float PI = 3.14159265359;

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    // Centered coordinates (-1 to 1)
    vec2 uv = vUV.st * 2.0 - 1.0;
    uv.x *= uAspect;
    
    // Your generative logic here
    // Example: simple circle
    float dist = length(uv);
    float pattern = smoothstep(0.5, 0.45, dist);
    
    vec4 color = vec4(vec3(pattern), 1.0);
    fragColor = TDOutputSwizzle(color);
}
