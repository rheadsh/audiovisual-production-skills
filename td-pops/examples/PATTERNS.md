# Common GLSL POP Patterns

Ready-to-use compute shader templates. Copy and modify for your needs.

## Position Pass-Through

The minimal GLSL POP shader — reads position, writes it unchanged.

```glsl
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    P[id] = TDIn_P();
}
```

**Operator**: GLSL POP
**Output Attributes**: `P`
**Attribute Class**: Point

---

## Simple Position Offset

Displace all points along an axis.

```glsl
uniform float uOffset;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    pos.y += uOffset;
    P[id] = pos;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P`
**TD Setup**: Vectors → `uOffset` (float) = `1.0`

---

## Time-Based Animation

Animate position with a sine wave.

```glsl
uniform float uTime;
uniform float uAmplitude;
uniform float uFrequency;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    pos.y += sin(pos.x * uFrequency + uTime) * uAmplitude;
    P[id] = pos;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P`
**TD Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uAmplitude` (float) = `0.5`
- Vectors 3 → `uFrequency` (float) = `3.0`

---

## Velocity-Driven Motion

Update position from velocity with damping.

```glsl
uniform float uDeltaTime;
uniform float uDamping;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    vec3 vel = TDIn_v();

    // Apply damping
    vel *= uDamping;

    // Integrate position
    pos += vel * uDeltaTime;

    P[id] = pos;
    v[id] = vel;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P v`
**TD Setup**:
- Vectors 1 → `uDeltaTime` (float) = `1.0 / me.time.rate`
- Vectors 2 → `uDamping` (float) = `0.99`

---

## Noise-Based Displacement

Displace points using Simplex noise for organic motion.

```glsl
uniform float uTime;
uniform float uNoiseScale;
uniform float uNoiseAmount;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();

    // 3D noise field based on position + time
    vec3 noiseInput = pos * uNoiseScale + vec3(0.0, 0.0, uTime * 0.5);

    vec3 displacement;
    displacement.x = TDSimplexNoise(noiseInput);
    displacement.y = TDSimplexNoise(noiseInput + vec3(100.0));
    displacement.z = TDSimplexNoise(noiseInput + vec3(200.0));

    pos += displacement * uNoiseAmount;
    P[id] = pos;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P`
**TD Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uNoiseScale` (float) = `2.0`
- Vectors 3 → `uNoiseAmount` (float) = `0.3`

---

## Point Attractor

Pull points toward a target position with falloff.

```glsl
uniform vec3 uAttractor;
uniform float uStrength;
uniform float uDeltaTime;

const float EPSILON = 0.0001;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    vec3 vel = TDIn_v();

    // Force toward attractor with inverse-distance falloff
    vec3 toTarget = uAttractor - pos;
    float dist = max(length(toTarget), EPSILON);
    vec3 force = normalize(toTarget) * uStrength / dist;

    vel += force * uDeltaTime;
    pos += vel * uDeltaTime;

    P[id] = pos;
    v[id] = vel;
}
```

**Operator**: GLSL POP
**Output Attributes**: `P v`
**TD Setup**:
- Vectors 1 → `uAttractor` (vec3) = `0.0, 2.0, 0.0`
- Vectors 2 → `uStrength` (float) = `5.0`
- Vectors 3 → `uDeltaTime` (float) = `1.0 / me.time.rate`

---

## Age-Based Color and Fade

Color particles by their age-to-life ratio and fade alpha near death.

```glsl
uniform vec3 uColorYoung;
uniform vec3 uColorOld;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    float age  = TDIn_age();
    float life = TDIn_life();
    float ratio = clamp(age / max(life, 0.001), 0.0, 1.0);

    // Color gradient from young to old
    vec3 rgb = mix(uColorYoung, uColorOld, ratio);

    // Fade alpha near end of life
    float alpha = smoothstep(1.0, 0.8, ratio);

    Cd[id] = vec4(rgb, alpha);
}
```

**Operator**: GLSL POP
**Output Attributes**: `Cd`
**TD Setup**:
- Colors 1 → `uColorYoung` (vec3) = `0.2, 0.6, 1.0`
- Colors 2 → `uColorOld` (vec3) = `1.0, 0.3, 0.1`

---

## Per-Point Scale from Noise

Vary point scale procedurally for organic particle sizes.

```glsl
uniform float uTime;
uniform float uBaseScale;
uniform float uVariation;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();
    float noise = TDSimplexNoise(vec3(pos.xy * 3.0, uTime * 0.3));

    // Remap noise from [-1,1] to scale range
    float scale = uBaseScale + noise * uVariation;
    scale = max(scale, 0.001);   // prevent negative scale

    pscale[id] = scale;
}
```

**Operator**: GLSL POP
**Output Attributes**: `pscale`
**TD Setup**:
- Vectors 1 → `uTime` (float) = `absTime.seconds`
- Vectors 2 → `uBaseScale` (float) = `0.05`
- Vectors 3 → `uVariation` (float) = `0.03`

---

## GLSL Copy POP — Linear Instancing

Duplicate geometry in a row with per-copy offset.

```glsl
uniform float uSpacing;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumPoints())
        return;

    vec3 pos = TDIn_P();
    pos.x += float(TDCopyIndex()) * uSpacing;

    P[id] = pos;
    TDUpdatePointGroups();
}
```

**Operator**: GLSL Copy POP
**Output Attributes**: `P`
**Number of Copies**: `10` (or desired count)
**TD Setup**: Vectors → `uSpacing` (float) = `2.0`

---

## GLSL Copy POP — Circular Array

Arrange copies in a circle with rotation.

```glsl
uniform float uRadius;

const float PI = 3.14159265359;
const float TAU = PI * 2.0;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumPoints())
        return;

    // Angle for this copy
    float angle = TAU * float(TDCopyIndex()) / float(TDNumPoints() / TDInputNumPoints(0));

    // Rotate the original position around Y axis, then offset to circle
    mat3 rot = TDRotateY(angle);
    vec3 pos = rot * TDIn_P();
    pos.x += cos(angle) * uRadius;
    pos.z += sin(angle) * uRadius;

    P[id] = pos;
    TDUpdatePointGroups();
}
```

**Operator**: GLSL Copy POP
**Output Attributes**: `P`
**Number of Copies**: `12`
**TD Setup**: Vectors → `uRadius` (float) = `5.0`

---

## GLSL Advanced POP — Simultaneous Point + Primitive

Modify points and primitive attributes in a single shader.

```glsl
uniform float uTime;

void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // Modify point position
    vec3 pos = TDInPoint_P();
    pos.y += sin(pos.x + uTime) * 0.5;
    oTDPoint_P[id] = pos;

    // Modify point color based on height
    float heightNorm = clamp(pos.y * 0.5 + 0.5, 0.0, 1.0);
    oTDPoint_Cd[id] = vec4(heightNorm, 0.3, 1.0 - heightNorm, 1.0);
}
```

**Operator**: GLSL Advanced POP
**Point Output Attributes**: `P Cd`
**TD Setup**: Vectors → `uTime` (float) = `absTime.seconds`
