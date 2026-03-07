# GLSL POP Best Practices

Optimization, organization, and workflow guidelines for TouchDesigner GLSL POP compute shaders.

## Code Organization

### Recommended Structure

```glsl
// 1. UNIFORMS (global scope, top of file)
uniform float uTime;
uniform float uForce;
uniform vec3 uAttractor;

// 2. CONSTANTS
const float PI = 3.14159265359;
const float EPSILON = 0.0001;

// 3. HELPER FUNCTIONS (before main)
vec3 calculateForce(vec3 pos, vec3 target, float strength) {
    vec3 dir = target - pos;
    float dist = max(length(dir), EPSILON);
    return normalize(dir) * (strength / (dist * dist));
}

// 4. MAIN FUNCTION
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // Read → Process → Write
    vec3 pos = TDIn_P();
    pos += calculateForce(pos, uAttractor, uForce) * uTime;
    P[id] = pos;
}
```

### Naming Conventions

**Uniforms**: Prefix with `u`
```glsl
uniform float uTime;
uniform vec3 uGravity;
uniform float uDamping;
```

**Constants**: UPPER_CASE
```glsl
const float MAX_SPEED = 10.0;
const int MAX_NEIGHBORS = 8;
```

**Helper functions**: camelCase, describe the action
```glsl
vec3 applyGravity(vec3 vel, float dt) { ... }
float calculateAge(float birth, float now) { ... }
```

---

## The Bounds-Check Pattern

Every GLSL POP shader must begin with a bounds check. The GPU dispatches threads in workgroup-sized blocks, so some threads will exceed the actual element count:

```glsl
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // Safe to access attributes below this point
}
```

Skipping this causes out-of-bounds memory writes that can crash TouchDesigner or produce garbage data.

---

## Output Initialization

Uninitialized output buffers contain undefined data. Reading from them in downstream operators causes unpredictable behavior and crashes.

**Option A — Enable "Initialize Output Attributes"** in the operator parameters. This copies input values for existing attributes and fills defaults for new ones. Convenient but has a small performance cost.

**Option B — Write every output element explicitly.** More performant when you're already computing all values:

```glsl
// Writing all outputs — no need for initialization toggle
P[id]  = newPosition;
v[id]  = newVelocity;
Cd[id] = newColor;
```

**Option C — Conditional writes with initialization enabled.** When only some elements change:

```glsl
// Enable "Initialize Output Attributes" so unchanged elements keep their values
if (shouldUpdate) {
    P[id] = newPosition;
}
// Elements where shouldUpdate == false retain their input values
```

---

## Performance Optimization

### Workgroup Size

The default "Auto" mode works well for most cases. For manual control:
- **NVIDIA GPUs**: multiples of 32 (warp size)
- **AMD GPUs**: multiples of 64 (wavefront size)

### Minimize Attribute Reads

```glsl
// Read once, reuse the value
vec3 pos = TDIn_P();
vec3 vel = TDIn_v();

// Use pos and vel multiple times without re-reading
vec3 force = calculateForce(pos);
vel += force;
pos += vel * uDeltaTime;

P[id] = pos;
v[id] = vel;
```

### Avoid Expensive Operations in Tight Loops

```glsl
// Precompute what you can outside loops
float invMaxDist = 1.0 / uMaxDist;

for (uint i = 0; i < neighborCount; i++) {
    // Use multiplication instead of division
    float normalizedDist = dist * invMaxDist;
}
```

### Use Built-in Functions

TouchDesigner's built-in math functions are GPU-optimized:

```glsl
// Use TDRemap instead of manual remap
float mapped = TDRemap(value, 0.0, 1.0, -1.0, 1.0);

// Use TDRotateOnAxis instead of building rotation matrices manually
mat3 rot = TDRotateOnAxis(angle, vec3(0.0, 1.0, 0.0));
vec3 rotated = rot * position;
```

### Multi-Pass for Complex Simulations

Use the "Passes" parameter for iterative algorithms (e.g., constraint solving, relaxation):

```glsl
// Pass 1: Apply forces and integrate position
// Pass 2: Resolve collisions
// Pass 3: Update velocity from corrected positions
```

Each pass can read the output of the previous pass when "Read-Write" access is enabled.

---

## Memory Considerations

### Attribute Pass-Through

Unmodified input attributes from the first input pass downstream by reference — no extra memory. Only list attributes in "Output Attributes" that you actually modify.

```
Output Attributes: P v    ← Only position and velocity
                           ← Cd, N, etc. pass through automatically
```

### Changing Element Counts

When output element count differs from input (GLSL Advanced POP), all attribute references break and new buffers are allocated. This is expected but worth knowing for memory-constrained projects.

### Temp Buffers

Use Temp Buffers for persistent data between passes or frames. Initialize them with sensible defaults to avoid first-frame artifacts.

---

## Debugging Strategies

### Visual Debugging with Color

Write diagnostic values to `Cd` to visualize them:

```glsl
// Visualize velocity magnitude as color
float speed = length(TDIn_v());
Cd[id] = vec4(speed, 0.0, 1.0 - speed, 1.0);

// Visualize force direction
vec3 force = normalize(uAttractor - TDIn_P());
Cd[id] = vec4(force * 0.5 + 0.5, 1.0);

// Visualize particle age as gradient
float ageRatio = TDIn_age() / TDIn_life();
Cd[id] = vec4(ageRatio, 1.0 - ageRatio, 0.0, 1.0);
```

### Isolate Problems

When debugging, strip your shader down to the minimum and add features back one at a time:

```glsl
// Step 1: Just pass through position — does geometry appear?
P[id] = TDIn_P();

// Step 2: Add a simple offset — is writing working?
P[id] = TDIn_P() + vec3(0.0, 1.0, 0.0);

// Step 3: Add time-based motion — are uniforms connected?
P[id] = TDIn_P() + vec3(0.0, sin(uTime), 0.0);

// Step 4: Add your actual logic
```

### Check the Info CHOP

Connect an Info CHOP to the GLSL POP to monitor:
- `cook_time` — shader execution time in ms
- `warnings` / `errors` — compile issues
- `total_cooks` — verify the operator is cooking

---

## TouchDesigner-Specific Tips

### Use CHOPs for Animated Uniforms

Instead of Python expressions like `absTime.seconds`:

1. Create a **Speed CHOP** (speed = 1, play mode = Locked)
2. Reference on the CHOP Uniforms page

This keeps time updates on the GPU timeline and avoids per-frame Python overhead.

### Combine with Other POPs

GLSL POPs slot into the standard POP chain:
- **Upstream**: Source geometry from Grid POP, Particle POP, File In POP, etc.
- **Downstream**: Render with Geometry COMP → Render TOP, or feed into other POPs
- **Feedback**: Connect output back to input via a Cache POP or Feedback COMP for iterative simulations

### Hardware Raytracing

GLSL POP and GLSL Advanced POP support hardware raytracing for collision detection:
- Connect a Collision POP with acceleration structures
- Choose Build Flags: "Fast Build" for dynamic geometry, "Fast Trace" for static
- Access collision data in the shader for physics simulations

---

## Common Pitfalls

1. **Using fragment-shader syntax** — No `fragColor`, `vUV`, `sTD2DInputs`, or `TDOutputSwizzle()` in POP compute shaders
2. **Missing bounds check** — Always `if (id >= TDNumElements()) return;`
3. **Not listing Output Attributes** — Attributes must be listed in the operator parameter or they won't exist as writable arrays
4. **Reading uninitialized outputs** — Enable initialization or write every element
5. **Wrong attribute class** — Make sure "Attribute Class" matches what you're processing (Point/Vertex/Primitive)
6. **Confusing GLSL POP and GLSL Advanced POP syntax** — `TDIn_P()` vs `TDInPoint_P()` are different operators
7. **Forgetting `TDUpdatePointGroups()` in Copy POP** — Group membership is lost without this call
8. **Division by zero in force calculations** — Always clamp distances: `max(dist, EPSILON)`
9. **Overwriting attributes you didn't mean to** — Only list modified attributes in Output Attributes
10. **Ignoring workgroup rounding** — `TDNumElements()` may be slightly larger than actual element count due to workgroup alignment
