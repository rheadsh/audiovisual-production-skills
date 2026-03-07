# GLSL POP Functions Reference

Complete API reference for TouchDesigner GLSL POP compute shaders.

## Thread Indexing

### Core Index Functions

```glsl
uint TDIndex();          // 1D thread index (undefined in manual 3D dispatch)
uint TDNumElements();    // Total requested threads (rounded up to workgroup size)
```

Always bounds-check before accessing attributes:
```glsl
const uint id = TDIndex();
if (id >= TDNumElements())
    return;
```

### Element Count Functions

```glsl
uint TDInputNumPoints(uint inputIndex);   // Point count for input N
uint TDInputNumPrims(uint inputIndex);    // Primitive count for input N
uint TDInputNumVerts(uint inputIndex);    // Vertex count for input N
```

Shorthand (defaults to input 0):
```glsl
uint TDInputNumPoints();   // = TDInputNumPoints(0)
```

---

## Input Attribute Access

### GLSL POP (single attribute class)

Pattern:
```glsl
attribType TDIn_AttribName(uint inputIndex, uint elementId, uint arrayIndex);
```

Shorthand (inputIndex=0, elementId=TDIndex(), arrayIndex=0):
```glsl
attribType TDIn_AttribName();
```

Common attributes:
```glsl
vec3  TDIn_P();        // Position
vec3  TDIn_v();        // Velocity
vec4  TDIn_Cd();       // Color (RGBA)
vec3  TDIn_N();        // Normal
float TDIn_pscale();   // Point scale
float TDIn_age();      // Particle age
float TDIn_life();     // Particle lifetime
int   TDIn_id();       // Particle ID
```

### GLSL Advanced POP (multi-class)

Point attributes:
```glsl
attribType TDInPoint_AttribName(uint inputIndex, uint pointId, uint arrayIndex);
attribType TDInPoint_AttribName();   // shorthand
```

Vertex attributes:
```glsl
attribType TDInVert_AttribName(uint inputIndex, uint vertId, uint arrayIndex);
attribType TDInVert_AttribName();
```

Primitive attributes:
```glsl
attribType TDInPrim_AttribName(uint inputIndex, uint primId, uint arrayIndex);
attribType TDInPrim_AttribName();
```

### GLSL Copy POP

Uses the same `TDIn_AttribName()` pattern as GLSL POP, plus copy-specific functions (see Copy POP section below).

---

## Output Attribute Declaration

Output attributes are SSBO arrays. They must be listed in the operator's "Output Attributes" parameter.

### GLSL POP

```glsl
vec3  P[];        // Position
vec3  v[];        // Velocity
vec4  Cd[];       // Color
vec3  N[];        // Normal
float pscale[];   // Point scale
float age[];      // Age
float life[];     // Lifetime
```

Write by index:
```glsl
P[id] = vec3(1.0, 2.0, 3.0);
Cd[id] = vec4(1.0, 0.0, 0.0, 1.0);
```

### GLSL Advanced POP

Class-prefixed output arrays:
```glsl
oTDPoint_P[];        // Point position
oTDPoint_Cd[];       // Point color
oTDVert_N[];         // Vertex normal
oTDPrim_primtype[];  // Primitive type
```

### Array Attributes

```glsl
const uint cTDArraySize_AttribName;   // Array dimension constant
attribType AttribName[];              // Access with [id * arraySize + arrayIndex]
```

### Output Access Modes

Set per-attribute in the operator parameters:
- **Write-Only**: Faster, cannot read back what you wrote in the same pass
- **Read-Write**: Allows reading your own output (needed for atomic operations, multi-pass feedback)

---

## Index Buffer Operations

### Reading Index Data

```glsl
uint TDInputPointIndex(uint inputIndex, uint vertIndex);
uint TDInputPointIndex(uint vertIndex);   // shorthand for input 0
```

### Writing Index Data (GLSL Advanced POP only)

When custom max primitives are set:
```glsl
uint I[];   // Index buffer array
```

---

## Primitive Topology

### Batch Information

```glsl
uint TDInputPrimIndex(uint vertIndex);              // Primitive index for a vertex
uint TDInputVertPrimIndex(uint vertIndex);           // Vertex position within its primitive
uint TDInputPrimType(uint primIndex);                // Primitive type ID
uint TDInputNumVertsPerPrim(uint inputIndex, uint primIndex);
uint TDInputPrimVertsStartIndex(uint inputIndex, uint primIndex);
uint TDInputPrimsStartIndex(uint inputIndex, uint primType);
uint TDInputVertsStartIndex(uint inputIndex, uint primType);
```

### Primitive Type Constants

```glsl
const uint cTDTrianglesType   = 0;
const uint cTDQuadsType       = 1;
const uint cTDLineStripsType  = 2;
const uint cTDLinesType       = 3;
const uint cTDPointPrimsType  = 4;
```

### Primitive Restart

```glsl
const uint cTDPrimIndexRestart;   // 0xFFFFFFFF
```

---

## GLSL Copy POP Functions

```glsl
uint TDNumPoints();           // Total output point count (across all copies)
uint TDInputPointIndex();     // Matching input point for current thread
uint TDCopyIndex();           // Current copy iteration (0-based)
uint TDTemplateNumPoints();   // Number of template points (if template input connected)
```

### Topology Update Functions

Call these to preserve group membership and topology across copies:
```glsl
void TDUpdatePointGroups();      // In point shader
void TDUpdateTopology();         // In vertex shader
void TDUpdateLineStripsInfo();   // In primitive shader
void TDUpdatePrimGroups();       // In primitive shader
```

---

## GLSL Advanced POP — Per-Primitive-Batch Mode

When dispatch mode is set to "Per Primitive Batch":
```glsl
uint TDInputPrimType();          // Constant across the batch
uint TDInputNumVertsPerPrim();   // Vertices per primitive in this batch
uint TDInputPrimsStartIndex();   // Input start index for this batch
uint TDPrimsStartIndex();        // Output start index
uint TDNumPrimsBatch();          // Number of primitives in this batch
```

This mode eliminates conditional logic when all primitives in a batch share the same type.

---

## Cache / Multi-Frame Access

Access previous frames via Cache POPs:
```glsl
attribType TDInCachePoint_AttribName(uint inputIndex, uint cacheIndex, uint elemId, uint arrayIndex);
attribType TDInCacheVert_AttribName(...);
attribType TDInCachePrim_AttribName(...);
```

---

## Dimensional Data

```glsl
const uint cTDDimSizeN;                              // Dimension count for input N
uint[cTDDimSizeN] TDDimensionN();                    // Dimension array
uint[cTDDimSizeN] TDDimCoordsN(uint pointIndex);     // Point coordinates in grid
uint TDDimPointIndexN(uint[cTDDimSizeN] coords);     // Index from coordinates
```

Convenience (omit N for input 0):
```glsl
uint[cTDDimSize] TDDimCoords(uint pointIndex);
```

---

## Math Helper Functions

### Rotation Matrices

```glsl
mat3 TDRotateOnAxis(float radians, vec3 axis);
mat3 TDRotateX(float radians);
mat3 TDRotateY(float radians);
mat3 TDRotateZ(float radians);
mat3 TDRotateToVector(vec3 forward, vec3 up);
mat3 TDCreateRotMatrix(vec3 from, vec3 to);
mat3 TDCreateTBNMatrix(vec3 normal, vec3 tangent, float handedness);
```

### Noise

```glsl
float TDSimplexNoise(vec2 v);
float TDSimplexNoise(vec3 v);
float TDSimplexNoise(vec4 v);

float TDPerlinNoise(vec2 v);
float TDPerlinNoise(vec3 v);
float TDPerlinNoise(vec4 v);
```

Quality mode selectable in operator parameters (Performance vs Quality).

### Color Conversion

```glsl
vec3 TDHSVToRGB(vec3 hsv);   // HSV → RGB
vec3 TDRGBToHSV(vec3 rgb);   // RGB → HSV
```

### Remapping

```glsl
float TDRemap(float val, float oldMin, float oldMax, float newMin, float newMax);
float TDLoop(float val, float low, float high);
float TDZigZag(float val, float low, float high);
```

### Coordinate Conversion

```glsl
vec3 TDEquirectangularToCubeMap(vec2 equiCoord);
vec2 TDCubeMapToEquirectangular(vec3 cubemapCoord);
```

---

## Uniform Types

Configurable on the operator's parameter pages:

| Page | Types |
|---|---|
| **Vectors** | float, vec2, vec3, vec4, int, ivec2-4, uint, uvec2-4, double, dvec2-4 |
| **Colors** | RGB + Alpha, with optional pre-multiply and sRGB/linear toggle |
| **Samplers** | TOP texture references with extend modes (Hold/Zero/Repeat/Mirror) and filter (Nearest/Interpolate) |
| **Arrays** | CHOP-driven uniform arrays or texture buffers |
| **Matrices** | Matrix uniforms |
| **Temp Buffers** | Persistent GPU buffers for inter-pass communication |
| **Constants** | Specialization constants (compile-time optimization) |
| **POP Buffers** | Cross-POP attribute access (GLSL Copy POP) |

---

## Performance Notes

- **Workgroup sizing**: 32 threads (NVIDIA) / 64 threads (AMD) is optimal
- **Unmodified attributes pass by reference** from input to output — no extra memory cost
- **Changing element counts** (GLSL Advanced POP) breaks references, allocating new buffers
- **Enable "Initialize Output Attributes" only when needed** — disable when you write every value explicitly for better performance
