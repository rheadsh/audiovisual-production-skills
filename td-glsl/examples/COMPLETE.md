# Complete Shader Examples

Full, production-ready shaders demonstrating best practices.

## 1. Kaleidoscope Effect

Full example with helper functions and proper organization.

```glsl
// ============================================
// KALEIDOSCOPE SHADER
// Creates radial symmetry with configurable segments
// ============================================

// UNIFORMS
uniform float uSegments;     // Number of mirror segments (4-16 recommended)
uniform float uRotation;     // Rotation offset in radians
uniform float uZoom;         // Zoom level (0.5-2.0 recommended)
uniform float uTime;         // Animation time

// CONSTANTS
const float PI = 3.14159265359;
const float TAU = 6.28318530718;

// HELPER FUNCTIONS
vec2 toPolar(vec2 cartesian) {
    float angle = atan(cartesian.y, cartesian.x);
    float radius = length(cartesian);
    return vec2(angle, radius);
}

vec2 toCartesian(vec2 polar) {
    float x = polar.y * cos(polar.x);
    float y = polar.y * sin(polar.x);
    return vec2(x, y);
}

vec2 kaleidoscope(vec2 uv, float segments, float time) {
    // Convert to polar
    vec2 polar = toPolar(uv);
    
    // Create mirrored segments
    float angle = polar.x + uRotation + time;
    float segmentAngle = TAU / segments;
    angle = mod(angle, segmentAngle);
    
    // Mirror every other segment
    float segment = floor((polar.x + uRotation) / segmentAngle);
    if(mod(segment, 2.0) > 0.5) {
        angle = segmentAngle - angle;
    }
    
    // Convert back to Cartesian
    return toCartesian(vec2(angle, polar.y));
}

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    // Center and scale UV
    vec2 uv = (vUV.st - 0.5) * uZoom;
    
    // Apply kaleidoscope effect
    vec2 kaleido = kaleidoscope(uv, uSegments, uTime);
    
    // Sample texture
    vec2 sampleUV = kaleido + 0.5;
    vec4 color = texture(sTD2DInputs[0], sampleUV);
    
    fragColor = TDOutputSwizzle(color);
}
```

**TouchDesigner Setup**:
- Vectors 1 → `uSegments` (float) = `8.0`
- Vectors 2 → `uRotation` (float) = `0.0`
- Vectors 3 → `uZoom` (float) = `1.0`
- Vectors 4 → `uTime` (float) = `absTime.seconds`

---

## 2. GPU Particle System (Compute Shader)

Position update shader for particle simulation.

```glsl
// ============================================
// PARTICLE POSITION UPDATE (Compute Shader)
// Updates particle positions based on velocity
// ============================================

layout (local_size_x = 8, local_size_y = 8) in;

// UNIFORMS
uniform float uDeltaTime;
uniform vec2 uAttractor;
uniform float uAttractorStrength;
uniform float uDamping;

// INPUT/OUTPUT TEXTURES
layout(rgba32f, binding=0) uniform image2D positionTexture;
layout(rgba32f, binding=1) uniform image2D velocityTexture;

// MAIN
void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    
    // Read current state
    vec4 position = imageLoad(positionTexture, coord);
    vec4 velocity = imageLoad(velocityTexture, coord);
    
    // Calculate attraction force
    vec2 toAttractor = uAttractor - position.xy;
    float dist = length(toAttractor);
    vec2 force = normalize(toAttractor) * (uAttractorStrength / max(dist, 0.1));
    
    // Update velocity
    velocity.xy += force * uDeltaTime;
    velocity.xy *= uDamping;
    
    // Update position
    position.xy += velocity.xy * uDeltaTime;
    
    // Wrap boundaries
    position.xy = fract(position.xy);
    
    // Write results
    imageStore(positionTexture, coord, position);
    imageStore(velocityTexture, coord, velocity);
}
```

---

## 3. Reaction-Diffusion System

Classic pattern formation algorithm.

```glsl
// ============================================
// REACTION-DIFFUSION SHADER
// Gray-Scott model for pattern formation
// ============================================

// UNIFORMS
uniform float uDiffusionA;      // Diffusion rate A (0.2 default)
uniform float uDiffusionB;      // Diffusion rate B (0.1 default)
uniform float uFeedRate;        // Feed rate (0.055 default)
uniform float uKillRate;        // Kill rate (0.062 default)
uniform float uDeltaTime;       // Time step (1.0 default)

// HELPER FUNCTION
vec2 laplacian(vec2 uv, sampler2D tex, vec2 texelSize) {
    vec2 sum = vec2(0.0);
    
    // 3x3 Laplacian kernel
    sum += texture(tex, uv + vec2(-1, -1) * texelSize).xy * 0.05;
    sum += texture(tex, uv + vec2( 0, -1) * texelSize).xy * 0.2;
    sum += texture(tex, uv + vec2( 1, -1) * texelSize).xy * 0.05;
    
    sum += texture(tex, uv + vec2(-1,  0) * texelSize).xy * 0.2;
    sum += texture(tex, uv + vec2( 0,  0) * texelSize).xy * -1.0;
    sum += texture(tex, uv + vec2( 1,  0) * texelSize).xy * 0.2;
    
    sum += texture(tex, uv + vec2(-1,  1) * texelSize).xy * 0.05;
    sum += texture(tex, uv + vec2( 0,  1) * texelSize).xy * 0.2;
    sum += texture(tex, uv + vec2( 1,  1) * texelSize).xy * 0.05;
    
    return sum;
}

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    vec2 uv = vUV.st;
    vec2 texelSize = 1.0 / vec2(textureSize(sTD2DInputs[0], 0));
    
    // Current state (R = chemical A, G = chemical B)
    vec2 state = texture(sTD2DInputs[0], uv).xy;
    float a = state.x;
    float b = state.y;
    
    // Calculate Laplacian
    vec2 lap = laplacian(uv, sTD2DInputs[0], texelSize);
    
    // Reaction-diffusion equations
    float reaction = a * b * b;
    float da = (uDiffusionA * lap.x) - reaction + (uFeedRate * (1.0 - a));
    float db = (uDiffusionB * lap.y) + reaction - ((uKillRate + uFeedRate) * b);
    
    // Update state
    a += da * uDeltaTime;
    b += db * uDeltaTime;
    
    // Output (visualize chemical B)
    fragColor = TDOutputSwizzle(vec4(b, b, b, 1.0));
}
```

**TouchDesigner Setup**:
- Vectors 1 → `uDiffusionA` (float) = `0.2`
- Vectors 2 → `uDiffusionB` (float) = `0.1`
- Vectors 3 → `uFeedRate` (float) = `0.055`
- Vectors 4 → `uKillRate` (float) = `0.062`
- Vectors 5 → `uDeltaTime` (float) = `1.0`

**Setup**: Connect output to Feedback TOP, feed back as input.

---

## 4. Advanced Color Grading

Professional color correction with LUT support.

```glsl
// ============================================
// COLOR GRADING SHADER
// Professional color correction pipeline
// ============================================

// UNIFORMS
uniform float uExposure;        // EV adjustment (-2 to 2)
uniform float uContrast;        // Contrast (0.5 to 2.0)
uniform float uSaturation;      // Saturation (0 to 2.0)
uniform float uTemperature;     // Color temperature (-1 to 1)
uniform float uTint;            // Tint (-1 to 1)
uniform vec3 uLift;             // Shadows adjustment
uniform vec3 uGamma;            // Midtones adjustment
uniform vec3 uGain;             // Highlights adjustment

// CONSTANTS
const vec3 LUMINANCE_WEIGHTS = vec3(0.299, 0.587, 0.114);

// HELPER FUNCTIONS
vec3 adjustExposure(vec3 color, float exposure) {
    return color * pow(2.0, exposure);
}

vec3 adjustContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec3 adjustSaturation(vec3 color, float saturation) {
    float luminance = dot(color, LUMINANCE_WEIGHTS);
    return mix(vec3(luminance), color, saturation);
}

vec3 adjustTemperature(vec3 color, float temperature) {
    // Warm: add red/yellow, reduce blue
    // Cool: add blue, reduce red/yellow
    vec3 warm = vec3(1.0 + temperature * 0.5, 1.0 + temperature * 0.2, 1.0 - temperature * 0.5);
    return color * warm;
}

vec3 liftGammaGain(vec3 color, vec3 lift, vec3 gamma, vec3 gain) {
    // Industry-standard color grading
    vec3 liftAdjusted = color + lift;
    vec3 gammaAdjusted = pow(max(liftAdjusted, vec3(0.0)), 1.0 / gamma);
    vec3 gainAdjusted = gammaAdjusted * gain;
    return gainAdjusted;
}

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    // Sample input
    vec4 color = texture(sTD2DInputs[0], vUV.st);
    
    // Color grading pipeline
    color.rgb = adjustExposure(color.rgb, uExposure);
    color.rgb = adjustContrast(color.rgb, uContrast);
    color.rgb = adjustTemperature(color.rgb, uTemperature);
    color.rgb = adjustSaturation(color.rgb, uSaturation);
    color.rgb = liftGammaGain(color.rgb, uLift, uGamma, uGain);
    
    // Clamp to valid range
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    
    fragColor = TDOutputSwizzle(color);
}
```

**TouchDesigner Setup**:
- Vectors 1 → `uExposure` (float) = `0.0`
- Vectors 2 → `uContrast` (float) = `1.0`
- Vectors 3 → `uSaturation` (float) = `1.0`
- Vectors 4 → `uTemperature` (float) = `0.0`
- Vectors 5 → `uTint` (float) = `0.0`
- Colors 1 → `uLift` (vec3) = `0.0, 0.0, 0.0`
- Colors 2 → `uGamma` (vec3) = `1.0, 1.0, 1.0`
- Colors 3 → `uGain` (vec3) = `1.0, 1.0, 1.0`

---

## 5. Signed Distance Field Renderer

Raymarched 3D shapes using SDFs.

```glsl
// ============================================
// SDF RENDERER
// Raymarched signed distance field shapes
// ============================================

// UNIFORMS
uniform float uTime;
uniform vec3 uCameraPos;
uniform float uAspect;

// CONSTANTS
const int MAX_STEPS = 100;
const float MAX_DIST = 100.0;
const float SURF_DIST = 0.001;

// SDF PRIMITIVES
float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

float sdBox(vec3 p, vec3 size) {
    vec3 q = abs(p) - size;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// SCENE
float scene(vec3 p) {
    // Animated sphere
    vec3 spherePos = vec3(sin(uTime) * 2.0, 0.0, 0.0);
    float sphere = sdSphere(p - spherePos, 1.0);
    
    // Static box
    float box = sdBox(p - vec3(0.0, 0.0, 0.0), vec3(0.8));
    
    // Combine with smooth minimum
    float k = 0.5;
    float h = clamp(0.5 + 0.5 * (box - sphere) / k, 0.0, 1.0);
    return mix(box, sphere, h) - k * h * (1.0 - h);
}

// RAYMARCHING
float raymarch(vec3 ro, vec3 rd) {
    float dist = 0.0;
    
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dist;
        float d = scene(p);
        dist += d;
        
        if(d < SURF_DIST || dist > MAX_DIST) break;
    }
    
    return dist;
}

// NORMAL CALCULATION
vec3 getNormal(vec3 p) {
    float d = scene(p);
    vec2 e = vec2(0.001, 0.0);
    
    vec3 n = d - vec3(
        scene(p - e.xyy),
        scene(p - e.yxy),
        scene(p - e.yyx)
    );
    
    return normalize(n);
}

// OUTPUT
out vec4 fragColor;

// MAIN
void main() {
    // Setup camera
    vec2 uv = (vUV.st - 0.5) * 2.0;
    uv.x *= uAspect;
    
    vec3 ro = uCameraPos;  // Ray origin
    vec3 rd = normalize(vec3(uv, 1.0));  // Ray direction
    
    // Raymarch
    float dist = raymarch(ro, rd);
    
    // Shading
    vec3 color = vec3(0.0);
    if(dist < MAX_DIST) {
        vec3 p = ro + rd * dist;
        vec3 n = getNormal(p);
        
        // Simple lighting
        vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
        float diff = max(dot(n, lightDir), 0.0);
        
        color = vec3(diff);
    }
    
    fragColor = TDOutputSwizzle(vec4(color, 1.0));
}
```

**TouchDesigner Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uCameraPos` (vec3) = `0.0, 0.0, -5.0`
- Vectors 3 → `uAspect` (float) = `me.width / me.height`

---

These examples demonstrate:
- Proper code organization
- Helper functions
- Complex algorithms
- Performance considerations
- Professional workflows
