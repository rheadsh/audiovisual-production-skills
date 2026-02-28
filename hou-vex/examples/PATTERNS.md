# Common VEX Patterns for Houdini

Ready-to-use VEX snippets for wrangles. Copy directly into Point/Prim/Detail wrangles.

## Point Manipulation

### Move Points Along Normal

```c
// Point Wrangle
@P += @N * chf("distance");
```

**Parameters**: Create float parameter `distance`

### Scale Points from Center

```c
// Point Wrangle
vector center = getbbox_center(0);
vector dir = @P - center;
@P = center + dir * chf("scale");
```

### Jitter Points with Noise

```c
// Point Wrangle
vector offset = noise(@P * chf("freq")) * chf("amp");
@P += offset;
```

**Parameters**: 
- `freq` (float) = 1.0
- `amp` (float) = 0.1

### Smooth Points (Laplacian)

```c
// Point Wrangle
int pts[] = neighbours(0, @ptnum);
vector avg = {0,0,0};

foreach(int pt; pts) {
    avg += point(0, "P", pt);
}

avg /= len(pts);
@P = lerp(@P, avg, chf("smooth"));
```

**Parameters**: `smooth` (float) = 0.5

---

## Attribute Creation

### Create ID Attribute

```c
// Point Wrangle
i@id = @ptnum;
```

### Create Random Color

```c
// Point Wrangle
@Cd = random(@ptnum);
```

### Create Group Based on Condition

```c
// Point Wrangle
if (@P.y > chf("threshold")) {
    i@group_top = 1;
}
```

### Transfer Attribute from Nearest Point

```c
// Point Wrangle
int nearest = nearpoint(1, @P);  // Input 1
@Cd = point(1, "Cd", nearest);
```

---

## Neighbor Operations

### Average Position of Neighbors

```c
// Point Wrangle
int pts[] = neighbours(0, @ptnum);
vector avg = {0,0,0};

foreach(int pt; pts) {
    avg += point(0, "P", pt);
}

if (len(pts) > 0) {
    avg /= len(pts);
    @P = avg;
}
```

### Find Points Within Radius

```c
// Point Wrangle
int pts[] = nearpoints(0, @P, chf("radius"));

// Color based on neighbor count
@Cd = set(len(pts) / 10.0, 0, 0);
```

### Connect to Nearest N Points

```c
// Point Wrangle (set to "Create Lines")
int maxpts = chi("max_connections");
int pts[] = nearpoints(0, @P, chf("radius"), maxpts);

foreach(int pt; pts) {
    if (pt != @ptnum) {
        int prim = addprim(0, "polyline");
        addvertex(0, prim, @ptnum);
        addvertex(0, prim, pt);
    }
}
```

---

## Noise & Displacement

### Simple Noise Displacement

```c
// Point Wrangle
float n = noise(@P * chf("freq") + @Time);
@P += @N * n * chf("amp");
```

### Animated Curl Noise

```c
// Point Wrangle
vector n = curlnoise(@P * chf("freq") + vector(@Time) * chf("speed"));
@P += n * chf("amp");
```

### Fractal Noise (Multiple Octaves)

```c
// Point Wrangle
float freq = chf("freq");
float amp = chf("amp");
float result = 0;

for (int i = 0; i < chi("octaves"); i++) {
    result += noise(@P * freq) * amp;
    freq *= 2.0;
    amp *= 0.5;
}

@P += @N * result;
```

**Parameters**:
- `freq` (float) = 1.0
- `amp` (float) = 0.1
- `octaves` (int) = 3

---

## Color & Visualization

### Color by Height

```c
// Point Wrangle
float min = getbbox_min(0).y;
float max = getbbox_max(0).y;
float t = fit(@P.y, min, max, 0, 1);
@Cd = chramp("color", t);
```

**Parameters**: `color` (ramp)

### Color by Distance from Center

```c
// Point Wrangle
vector center = getbbox_center(0);
float dist = distance(@P, center);
float maxdist = length(getbbox_size(0)) * 0.5;
float t = fit(dist, 0, maxdist, 0, 1);
@Cd = chramp("color", t);
```

### Visualize Normal as Color

```c
// Point Wrangle
@Cd = @N * 0.5 + 0.5;  // Remap from [-1,1] to [0,1]
```

### Random Color Per Primitive

```c
// Primitive Wrangle
@Cd = random(@primnum);
```

---

## Particle Systems

### Basic Particle Update

```c
// Point Wrangle (on particle system)
v@v += v@force * @TimeInc;  // Update velocity
@P += v@v * @TimeInc;        // Update position
v@v *= chf("drag");          // Apply drag
```

### Particle Life & Death

```c
// Point Wrangle
f@age += @TimeInc;

if (@age > f@life) {
    removepoint(0, @ptnum);
}
```

### Attract Particles to Target

```c
// Point Wrangle
vector target = chv("target");
vector dir = target - @P;
float dist = length(dir);
dir = normalize(dir);

v@v += dir * chf("strength") / max(dist, 0.01);
```

---

## Primitive Operations

### Extrude Primitives

```c
// Primitive Wrangle
vector centroid = prim(0, "P", @primnum);
vector offset = prim(0, "N", @primnum) * chf("distance");

int pts[] = primpoints(0, @primnum);
foreach(int pt; pts) {
    vector pos = point(0, "P", pt);
    setpointattrib(0, "P", pt, pos + offset);
}
```

### Delete Small Primitives

```c
// Primitive Wrangle
float area = primintrinsic(0, "measuredarea", @primnum);

if (area < chf("min_area")) {
    removeprim(0, @primnum, 1);  // 1 = remove points too
}
```

### Subdivide Primitive

```c
// Primitive Wrangle (create new geometry)
int pts[] = primpoints(0, @primnum);
vector center = {0,0,0};

foreach(int pt; pts) {
    center += point(0, "P", pt);
}
center /= len(pts);

int newpt = addpoint(0, center);

foreach(int pt; pts) {
    int prim = addprim(0, "poly");
    addvertex(0, prim, newpt);
    addvertex(0, prim, pt);
}
```

---

## UV & Texture

### Create UV from Position

```c
// Point Wrangle
vector bbox_min = getbbox_min(0);
vector bbox_size = getbbox_size(0);

@uv.x = fit(@P.x, bbox_min.x, bbox_min.x + bbox_size.x, 0, 1);
@uv.y = fit(@P.z, bbox_min.z, bbox_min.z + bbox_size.z, 0, 1);
```

### Rotate UVs

```c
// Vertex Wrangle
float angle = radians(chf("angle"));
vector2 center = {0.5, 0.5};
vector2 uv = v@uv - center;

float c = cos(angle);
float s = sin(angle);
v@uv.x = uv.x * c - uv.y * s;
v@uv.y = uv.x * s + uv.y * c;
v@uv += center;
```

---

## Groups & Selection

### Create Group by Angle

```c
// Point Wrangle
vector up = {0, 1, 0};
float angle = degrees(acos(dot(normalize(@N), up)));

if (angle < chf("max_angle")) {
    i@group_facing_up = 1;
}
```

### Random Group Selection

```c
// Point Wrangle
if (random(@ptnum) < chf("probability")) {
    i@group_random = 1;
}
```

### Group Boundary Points

```c
// Point Wrangle
int edges[] = pointhedges(0, @ptnum);
int is_boundary = 0;

foreach(int edge; edges) {
    int prims[] = hedge_equivcount(0, edge);
    if (len(prims) == 1) {
        is_boundary = 1;
        break;
    }
}

if (is_boundary) {
    i@group_boundary = 1;
}
```

---

## Matrix & Transforms

### Transform Points by Matrix

```c
// Point Wrangle
matrix3 m = ident();
rotate(m, radians(chf("angle")), {0, 1, 0});
@P *= m;
```

### Orient to Direction

```c
// Point Wrangle
vector target = chv("target");
vector dir = normalize(target - @P);
vector up = {0, 1, 0};

v@N = dir;
matrix3 m = maketransform(dir, up);
@orient = quaternion(m);
```

### Copy to Points Transform

```c
// Point Wrangle (for copy to points)
@pscale = fit01(random(@ptnum), chf("min_scale"), chf("max_scale"));
@orient = quaternion(maketransform(@N, {0,1,0}));
```

---

## Utility Functions

### Remap Value

```c
// Point Wrangle
float value = @P.y;
float remapped = fit(value, chf("in_min"), chf("in_max"), chf("out_min"), chf("out_max"));
```

### Clamp to Range

```c
// Point Wrangle
@P.y = clamp(@P.y, chf("min"), chf("max"));
```

### Smoothstep Transition

```c
// Point Wrangle
float t = fit(@P.x, chf("start"), chf("end"), 0, 1);
t = smooth(0, 1, t);
@Cd = lerp({1,0,0}, {0,0,1}, t);
```
