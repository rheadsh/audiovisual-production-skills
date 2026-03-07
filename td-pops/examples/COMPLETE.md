# Complete GLSL POP Examples

Full, production-ready compute shaders demonstrating best practices.

## 1. GPU Particle Simulation with Gravity and Boundaries

A complete particle physics system with gravity, floor bounce, and velocity damping.

```glsl
// ============================================
// PARTICLE PHYSICS SIMULATION
// Gravity + floor collision + damping
// ============================================

// UNIFORMS
uniform float uDeltaTime;      // Time step
uniform vec3  uGravity;        // Gravity vector (e.g., 0, -9.81, 0)
uniform float uDamping;        // Velocity damping (0.98 typical)
uniform float uBounciness;     // Bounce coefficient (0.0-1.0)
uniform float uFloorY;         // Floor height

// CONSTANTS
const float EPSILON = 0.0001;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    vec3 vel = TDIn_v();

    // Apply gravity
    vel += uGravity * uDeltaTime;

    // Apply damping
    vel *= uDamping;

    // Integrate position
    pos += vel * uDeltaTime;

    // Floor collision
    if (pos.y < uFloorY) {
        pos.y = uFloorY;
        vel.y = abs(vel.y) * uBounciness;

        // Friction on horizontal velocity when hitting floor
        vel.xz *= 0.95;
    }

    P[id] = pos;
    v[id] = vel;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P v`
**TD Setup**:
- Vectors 1 → `uDeltaTime` (float) = `1.0 / me.time.rate`
- Vectors 2 → `uGravity` (vec3) = `0.0, -9.81, 0.0`
- Vectors 3 → `uDamping` (float) = `0.98`
- Vectors 4 → `uBounciness` (float) = `0.6`
- Vectors 5 → `uFloorY` (float) = `-1.0`

**Upstream**: Particle POP or Grid POP as point source
**Downstream**: Geometry COMP → Render TOP for visualization

---

## 2. Flocking / Boids Behavior (Simplified)

A simplified boids system using center-of-mass attraction and velocity alignment. For a full N-body neighbor search you'd encode positions into a texture; this version uses global averages for efficiency.

```glsl
// ============================================
// SIMPLIFIED FLOCKING SYSTEM
// Global-average cohesion + alignment + boundary
// ============================================

// UNIFORMS
uniform float uDeltaTime;
uniform float uCohesion;         // Pull toward center (0.5)
uniform float uAlignment;        // Match average velocity (0.3)
uniform float uMaxSpeed;         // Speed clamp (2.0)
uniform float uBoundarySize;     // Soft boundary radius (5.0)
uniform float uBoundaryForce;    // Boundary push strength (1.0)
uniform vec3  uCenterOfMass;     // Pre-computed average position (from CHOP)
uniform vec3  uAverageVelocity;  // Pre-computed average velocity (from CHOP)

const float EPSILON = 0.0001;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    vec3 vel = TDIn_v();

    // Cohesion: steer toward center of mass
    vec3 toCenter = uCenterOfMass - pos;
    vel += normalize(toCenter + vec3(EPSILON)) * uCohesion * uDeltaTime;

    // Alignment: match average velocity
    vel += (uAverageVelocity - vel) * uAlignment * uDeltaTime;

    // Boundary: soft push back toward origin
    float distFromOrigin = length(pos);
    if (distFromOrigin > uBoundarySize) {
        vec3 pushBack = -normalize(pos) * (distFromOrigin - uBoundarySize) * uBoundaryForce;
        vel += pushBack * uDeltaTime;
    }

    // Clamp speed
    float speed = length(vel);
    if (speed > uMaxSpeed) {
        vel = normalize(vel) * uMaxSpeed;
    }

    // Integrate
    pos += vel * uDeltaTime;

    P[id] = pos;
    v[id] = vel;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P v`
**TD Setup**:
- Vectors 1 → `uDeltaTime` (float) = `1.0 / me.time.rate`
- Vectors 2 → `uCohesion` (float) = `0.5`
- Vectors 3 → `uAlignment` (float) = `0.3`
- Vectors 4 → `uMaxSpeed` (float) = `2.0`
- Vectors 5 → `uBoundarySize` (float) = `5.0`
- Vectors 6 → `uBoundaryForce` (float) = `1.0`
- Vectors 7 → `uCenterOfMass` (vec3) — from CHOP analyzing upstream points
- Vectors 8 → `uAverageVelocity` (vec3) — from CHOP analyzing upstream points

**Note**: For true local-neighbor interactions, encode point positions into a TOP texture (using a POP to TOP) and sample neighbors via a Sampler uniform.

---

## 3. Curl Noise Flow Field

Particles advected through a 3D curl noise field for fluid-like motion.

```glsl
// ============================================
// CURL NOISE FLOW FIELD
// Divergence-free noise for fluid-like motion
// ============================================

uniform float uTime;
uniform float uNoiseScale;       // Spatial frequency (1.0)
uniform float uFlowSpeed;        // Advection speed (0.5)
uniform float uEvolution;        // Noise time evolution speed (0.2)

// Compute curl of 3D noise field
// Curl gives a divergence-free vector field — particles never converge to a point
vec3 curlNoise(vec3 p) {
    float eps = 0.01;

    // Partial derivatives via finite differences
    float nx = TDSimplexNoise(p + vec3(eps, 0.0, 0.0)) - TDSimplexNoise(p - vec3(eps, 0.0, 0.0));
    float ny = TDSimplexNoise(p + vec3(0.0, eps, 0.0)) - TDSimplexNoise(p - vec3(0.0, eps, 0.0));
    float nz = TDSimplexNoise(p + vec3(0.0, 0.0, eps)) - TDSimplexNoise(p - vec3(0.0, 0.0, eps));

    // Second noise field for cross-derivative
    vec3 offset = vec3(31.416, 47.853, 12.679);
    float nx2 = TDSimplexNoise(p + offset + vec3(eps, 0.0, 0.0)) - TDSimplexNoise(p + offset - vec3(eps, 0.0, 0.0));
    float ny2 = TDSimplexNoise(p + offset + vec3(0.0, eps, 0.0)) - TDSimplexNoise(p + offset - vec3(0.0, eps, 0.0));
    float nz2 = TDSimplexNoise(p + offset + vec3(0.0, 0.0, eps)) - TDSimplexNoise(p + offset - vec3(0.0, 0.0, eps));

    // Curl = cross product of gradients
    return vec3(
        ny2 - nz,
        nz - nx2,
        nx - ny2
    ) / (2.0 * eps);
}

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();

    // Sample curl noise at particle position
    vec3 noisePos = pos * uNoiseScale + vec3(0.0, 0.0, uTime * uEvolution);
    vec3 flowVelocity = curlNoise(noisePos);

    // Advect particle
    pos += flowVelocity * uFlowSpeed;

    // Store velocity for downstream visualization
    v[id] = flowVelocity;
    P[id] = pos;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P v`
**TD Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uNoiseScale` (float) = `1.0`
- Vectors 3 → `uFlowSpeed` (float) = `0.5`
- Vectors 4 → `uEvolution` (float) = `0.2`

**Tip**: Feed output back through a Cache POP for continuous advection. Color by velocity magnitude for visual feedback.

---

## 4. GLSL Copy POP — Scattered Instancing with Rotation

Place copies at template points with random rotation and scale.

```glsl
// ============================================
// SCATTERED INSTANCING
// Per-copy rotation, scale, and color variation
// ============================================

uniform float uTime;
uniform float uScaleMin;        // Minimum scale (0.5)
uniform float uScaleMax;        // Maximum scale (1.5)
uniform float uRotationSpeed;   // Spin speed (1.0)

const float PI = 3.14159265359;

// Simple hash for per-copy randomness
float hash(uint n) {
    n = (n << 13u) ^ n;
    n = n * (n * n * 15731u + 789221u) + 1376312589u;
    return float(n & 0x7fffffffu) / float(0x7fffffff);
}

void main() {
    const uint id = TDIndex();
    if (id >= TDNumPoints())
        return;

    uint copyId = TDCopyIndex();
    vec3 pos = TDIn_P();

    // Per-copy random values
    float rand1 = hash(copyId);
    float rand2 = hash(copyId + 1000u);
    float rand3 = hash(copyId + 2000u);

    // Random rotation per copy
    float angle = uTime * uRotationSpeed * (rand1 * 2.0 - 1.0);
    vec3 rotAxis = normalize(vec3(rand1, rand2, rand3));
    mat3 rot = TDRotateOnAxis(angle, rotAxis);

    // Apply rotation
    pos = rot * pos;

    // Random scale
    float scale = mix(uScaleMin, uScaleMax, rand2);
    pos *= scale;

    // Per-copy color variation
    vec3 hsvColor = vec3(rand3, 0.7, 0.9);
    Cd[id] = vec4(TDHSVToRGB(hsvColor), 1.0);

    P[id] = pos;
    pscale[id] = scale;
    TDUpdatePointGroups();
}
```

**Operator**: GLSL Copy POP
**Output Attributes**: `P Cd pscale`
**Number of Copies**: set by template input point count, or manual value
**TD Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uScaleMin` (float) = `0.5`
- Vectors 3 → `uScaleMax` (float) = `1.5`
- Vectors 4 → `uRotationSpeed` (float) = `1.0`
- Enable "Initialize Output Attributes"

**Input 0**: Source geometry (e.g., Box POP, Sphere POP)
**Input 1** (optional): Template POP with scatter points for placement

---

## 5. GLSL Advanced POP — Mesh Deformer with Normals

Deform a mesh and recalculate vertex normals, reading both point and vertex data.

```glsl
// ============================================
// MESH DEFORMER WITH NORMAL UPDATE
// Sine-wave deformation + approximate normal recalculation
// ============================================

uniform float uTime;
uniform float uWaveFreq;       // Wave frequency (3.0)
uniform float uWaveAmp;        // Wave amplitude (0.5)
uniform float uNormalEps;      // Epsilon for normal estimation (0.01)

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // Read original position
    vec3 pos = TDInPoint_P();

    // Deformation: sine wave along X axis
    float wave = sin(pos.x * uWaveFreq + uTime) * uWaveAmp;
    pos.y += wave;

    // Estimate new normal via finite differences
    // Sample the deformation at neighboring positions
    vec3 posRight = TDInPoint_P();
    posRight.x += uNormalEps;
    posRight.y += sin(posRight.x * uWaveFreq + uTime) * uWaveAmp;

    vec3 posForward = TDInPoint_P();
    posForward.z += uNormalEps;
    posForward.y += sin(posForward.x * uWaveFreq + uTime) * uWaveAmp;

    // Compute tangent vectors
    vec3 tangentX = posRight - pos;
    vec3 tangentZ = posForward - pos;

    // Normal = cross product of tangents
    vec3 newNormal = normalize(cross(tangentZ, tangentX));

    // Write outputs
    oTDPoint_P[id] = pos;
    oTDPoint_N[id] = newNormal;
}
```

**Operator**: GLSL Advanced POP
**Point Output Attributes**: `P N`
**TD Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uWaveFreq` (float) = `3.0`
- Vectors 3 → `uWaveAmp` (float) = `0.5`
- Vectors 4 → `uNormalEps` (float) = `0.01`
- Enable "Initialize Output Attributes"

**Input**: Any mesh POP (Grid POP, Sphere POP, etc.)

---

These examples demonstrate:
- Proper bounds checking and code organization
- Physics simulation patterns (gravity, collision, damping)
- Noise-driven procedural motion (curl noise, simplex displacement)
- Instancing workflows with GLSL Copy POP
- Multi-class attribute access with GLSL Advanced POP
- Helper function usage (rotation, noise, color, hashing)
- Practical uniform configuration for TouchDesigner
