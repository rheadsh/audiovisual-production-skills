# Houdini VEX Troubleshooting

Common errors and their solutions.

## Error: "Type mismatch" or "Cannot convert"

**Cause**: Trying to assign wrong type to attribute or variable.

**Fix**: Use correct type prefix or explicit casting:

```c
// ❌ WRONG - Type mismatch
@Cd = 1.0;  // Cd is vector, not float

// ✅ CORRECT
@Cd = {1.0, 1.0, 1.0};
// or
@Cd = set(1.0);
```

**Type Prefixes**:
```c
f@myattr = 1.0;        // float
i@myattr = 1;          // integer
v@myattr = {1,2,3};    // vector
s@myattr = "text";     // string
2@myattr = {1,2};      // vector2
3@myattr = matrix3();  // matrix3
4@myattr = matrix();   // matrix (4x4)
p@myattr = {0,0,0,1};  // vector4 (quaternion)
```

---

## Error: "Attribute not found"

**Cause**: Trying to read attribute that doesn't exist on geometry.

**Fix**: Check attribute exists or create it first:

```c
// ❌ WRONG - Attribute might not exist
vector vel = v@velocity;

// ✅ CORRECT - Check if exists
vector vel = {0,0,0};
if (hasattrib(0, "point", "velocity")) {
    vel = v@velocity;
}

// ✅ BETTER - Use default value
vector vel = v@velocity;  // Auto-creates if missing
```

**Create with default**:
```c
// Declare at top of wrangle with default value
vector @velocity = {0,0,0};
float @age = 0.0;
```

---

## Error: "Invalid source for destination"

**Cause**: Reading from wrong input or geometry.

**Fix**: Verify input index and geometry type:

```c
// ❌ WRONG - Input 1 might be empty
@Cd = point(1, "Cd", @ptnum);

// ✅ CORRECT - Check input exists
if (npoints(1) > 0) {
    @Cd = point(1, "Cd", @ptnum);
}
```

---

## Performance: Code Runs Very Slowly

**Cause**: Inefficient loops, excessive function calls, or reading from detail attributes.

**Optimizations**:

### 1. Minimize Geometry Queries

```c
// ❌ SLOW - Queries in loop
for (int i = 0; i < npoints(0); i++) {
    vector p = point(0, "P", i);
}

// ✅ FASTER - Cache count
int numpts = npoints(0);
for (int i = 0; i < numpts; i++) {
    vector p = point(0, "P", i);
}
```

### 2. Avoid Detail Attributes in Point Wrangles

```c
// ❌ SLOW - Detail attribute in point wrangle
@P += @detailattr;  // Fetched per point!

// ✅ FAST - Use parameter instead
@P += chv("offset");  // Evaluated once
```

### 3. Use Compiled Mode

In wrangle node:
- Set "VEX Precision" to "32-bit" if high precision not needed
- Enable "Enforce Prototypes" for better optimization

---

## Error: "Undefined variable"

**Cause**: Variable used before declaration.

**Fix**: Declare all variables before use:

```c
// ❌ WRONG
result = value * 2;  // result not declared

// ✅ CORRECT
float result = value * 2;
```

---

## Wrong Results in Foreach Loops

**Cause**: VEX doesn't handle local scope like other languages.

**Fix**: Be careful with loop variable reuse:

```c
// ❌ PROBLEMATIC
for (int i = 0; i < 10; i++) {
    for (int i = 0; i < 5; i++) {  // Reuses same 'i'!
        // Inner loop affects outer
    }
}

// ✅ CORRECT
for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 5; j++) {  // Different variable
        // Works correctly
    }
}
```

---

## Attribute Changes Not Visible

**Cause**: Writing to wrong geometry stream or using wrong wrangle type.

**Fix**: Match wrangle type to attribute type:

- Point attributes → Point Wrangle
- Primitive attributes → Primitive Wrangle
- Detail attributes → Detail Wrangle
- Vertex attributes → Vertex Wrangle

**Verify you're modifying the right thing**:
```c
// In Point Wrangle:
@P = {0,0,0};           // ✅ Works - point attribute
@Cd = {1,0,0};          // ✅ Works - point attribute  
setprimattrib(0, "Cd", @primnum, {1,0,0});  // ✅ Can set prim attrib
```

---

## Groups Not Working

**Cause**: Incorrect group syntax or type mismatch.

**Fix**: Use correct group attribute:

```c
// ❌ WRONG
@group_mygroup = 1.0;  // Float, not int

// ✅ CORRECT
i@group_mygroup = 1;   // Must be integer

// ✅ ALSO CORRECT - Automatic type
@group_mygroup = 1;    // 'group_' prefix auto-typed as int
```

**Check if point in group**:
```c
if (inpointgroup(0, "mygroup", @ptnum)) {
    // Point is in group
}
```

---

## Randomness Not Random

**Cause**: Using same seed for random() calls.

**Fix**: Vary seed per element:

```c
// ❌ WRONG - Same result for all points
float r = random(1.0);

// ✅ CORRECT - Different per point
float r = random(@ptnum);

// ✅ DIFFERENT EACH FRAME
float r = random(@ptnum + @Frame);

// ✅ MULTIPLE RANDOMS PER POINT
float r1 = random(@ptnum);
float r2 = random(@ptnum + 123);  // Different seed
```

---

## Normals Look Wrong

**Cause**: Normals not normalized or calculated incorrectly.

**Fix**: Always normalize normals:

```c
// ❌ WRONG - May not be unit length
@N = @N + noise(@P);

// ✅ CORRECT
@N = normalize(@N + noise(@P));
```

**Recalculate normals**:
After modifying geometry, recalculate with Normal SOP or:
```c
// Point Wrangle (after topology change)
// Use a Normal SOP instead - this is just for reference
int prims[] = pointprims(0, @ptnum);
vector avg = {0,0,0};
foreach(int prim; prims) {
    avg += prim(0, "N", prim);
}
@N = normalize(avg);
```

---

## VEX vs Python Performance

**When to use VEX**:
- Manipulating points/primitives
- Per-element operations
- Real-time/interactive work
- Needs to be fast

**When to use Python**:
- Complex logic and algorithms
- File I/O
- External API calls
- Non-geometry tasks
- Recursion needed

**Hybrid approach**:
```python
# Python for setup
node = hou.pwd()
geo = node.geometry()

# VEX for per-point work (in wrangle)
@P += @N * chf("offset");
```

---

## Can't Access Parameter Value

**Cause**: Wrong parameter fetch function or parameter doesn't exist.

**Fix**: Use correct `ch*()` function:

```c
chf("param_name")    // float
chi("param_name")    // integer  
chv("param_name")    // vector (returns vector)
chs("param_name")    // string
chramp("param_name") // ramp (needs float 0-1)
```

**Check parameter exists**:
Create parameter first via "Create Spare Parameters" or "Edit Parameter Interface"

---

## Geometry Explodes or Goes to Origin

**Cause**: Division by zero or uninitialized vectors.

**Fix**: Add safety checks:

```c
// ❌ DANGEROUS
vector dir = @targetP - @P;
@P += normalize(dir) * 0.1;

// ✅ SAFE
vector dir = @targetP - @P;
float dist = length(dir);
if (dist > 0.001) {  // Avoid division by zero
    @P += normalize(dir) * 0.1;
}
```

---

## Matrix Transform Not Working

**Cause**: Wrong matrix order or incorrect construction.

**Fix**: Remember matrix multiplication order:

```c
// ❌ WRONG ORDER
@P *= translate_matrix;  // Usually wrong

// ✅ CORRECT ORDER  
@P = @P * xform_matrix;

// ✅ BUILD MATRIX CORRECTLY
matrix3 m = ident();
scale(m, {2, 2, 2});
rotate(m, radians(45), {0, 1, 0});
@P *= m;  // Scale then rotate
```

---

## Wrangle Shows No Errors But Does Nothing

**Cause**: Operating on empty geometry or wrong input.

**Fix**: Verify inputs:

```c
// Add debug output
printf("Points: %d\n", npoints(0));
printf("Ptnum: %d\n", @ptnum);
printf("Position: %g\n", @P);
```

**Check**:
- Input is connected
- Input has geometry
- Geometry has the expected attributes
- Wrangle is set to correct mode (Point/Prim/Detail)

---

## Common Gotchas

1. **No @ prefix = local variable**
   ```c
   vector P = @P;  // Local copy
   P.y = 0;        // Modifies local, not attribute!
   @P = P;         // Must reassign to attribute
   ```

2. **VEX runs per-element**
   ```c
   // This runs for EVERY point independently
   @P.y = 0;  // Each point processed in parallel
   ```

3. **Functions are inlined (no recursion)**
   ```c
   // ❌ WRONG - Recursion not supported
   float factorial(int n) {
       return n <= 1 ? 1 : n * factorial(n-1);
   }
   ```

4. **Detail attributes are expensive in point wrangles**
   ```c
   // ❌ SLOW
   @P += detail(0, "offset", 0);  // Fetched per point
   
   // ✅ FAST
   @P += chv("offset");  // Fetched once via parameter
   ```
