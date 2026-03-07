# GLSL POP Troubleshooting

Common errors and their solutions for TouchDesigner GLSL POP compute shaders.

## Crash or undefined behavior when reading downstream

**Cause**: Output attributes were not initialized, and downstream operators read garbage data.

**Fix**: Either enable "Initialize Output Attributes" on the GLSL POP, or make sure your shader writes every element of every output attribute:

```glsl
// Write ALL output attributes for every thread
P[id]  = TDIn_P();
v[id]  = TDIn_v();
Cd[id] = TDIn_Cd();
```

If you only modify some attributes, enable "Initialize Output Attributes" so the rest get copied from the input automatically.

---

## GPU hang or TouchDesigner freeze

**Cause**: Missing bounds check — threads beyond the element count write to invalid memory.

**Fix**: Always include the bounds check at the top of `main()`:

```glsl
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    // ... your code here
}
```

---

## Using fragment-shader syntax (compile errors)

**Cause**: GLSL POPs are compute shaders, not fragment shaders. Common mistakes:

```glsl
// WRONG — these do not exist in POP compute shaders
out vec4 fragColor;              // No fragment output
vec4 c = texture(sTD2DInputs[0], vUV.st);  // No texture inputs or UVs
fragColor = TDOutputSwizzle(c);  // No swizzle function
```

**Fix**: Use compute-shader attribute access instead:

```glsl
void main() {
    const uint id = TDIndex();
    if (id >= TDNumElements())
        return;

    vec3 pos = TDIn_P();    // Read position attribute
    P[id] = pos;             // Write to output array
}
```

---

## Attributes not appearing in output / downstream POP shows no data

**Cause**: Attributes not listed in the "Output Attributes" parameter on the operator.

**Fix**:
1. Open the GLSL POP parameters
2. In the "Output Attributes" field, list every attribute your shader writes to, separated by spaces:
   ```
   P v Cd
   ```
3. Make sure the attribute names match exactly (case-sensitive)

Also check that the "Attribute Class" parameter (Point/Vertex/Primitive) matches what you intend to modify.

---

## Error: undeclared identifier for TDInPoint_ / TDInVert_ / TDInPrim_

**Cause**: Using GLSL Advanced POP syntax in a regular GLSL POP (or vice versa).

**Fix**:

| Operator | Input syntax | Output syntax |
|---|---|---|
| GLSL POP | `TDIn_P()` | `P[id]` |
| GLSL Advanced POP | `TDInPoint_P()`, `TDInVert_N()`, `TDInPrim_X()` | `oTDPoint_P[id]`, `oTDVert_N[id]` |

---

## Uniform has no effect / undeclared identifier

**Cause**: Uniform declared in GLSL but not configured on the operator's parameter pages (or not used, so the compiler optimized it away).

**Fix**:
1. Declare in shader: `uniform float uForce;`
2. Actually use it in your code (unused uniforms are stripped by the compiler)
3. Configure on the appropriate parameter page:
   - **Vectors page**: for float, vec2, vec3, vec4
   - **Colors page**: for color values
   - **Samplers page**: for TOP texture inputs
4. Name must match exactly (case-sensitive)
5. Click "Load Uniform Names" if available

---

## Points don't move / position unchanged

**Cause**: Several possible issues:

1. **Not writing to `P[]`**: Make sure `P` is in your Output Attributes and you actually write `P[id] = ...`
2. **Time uniform not connected**: If using `uTime`, check that the Vectors page has `absTime.seconds` (or a CHOP reference)
3. **Velocity is zero**: If reading `TDIn_v()` and velocity was never set upstream, it's zero
4. **Scale is too small**: The offset might be happening but too tiny to see — try a large value like `P[id] = TDIn_P() + vec3(0.0, 5.0, 0.0);`

---

## GLSL Copy POP: copies overlap / no spread

**Cause**: Not using `TDCopyIndex()` to offset copies.

**Fix**: Use the copy index to spread copies apart:

```glsl
P[id] = TDIn_P() + float(TDCopyIndex()) * vec3(2.0, 0.0, 0.0);
```

If using a template input, read template point positions for placement:
```glsl
// Template positions drive copy placement
// (template data is accessible via the second input)
```

---

## GLSL Copy POP: point groups lost

**Cause**: Forgetting to call `TDUpdatePointGroups()` in the point shader.

**Fix**: Call the update function after writing point attributes:

```glsl
void main() {
    const uint id = TDIndex();
    if (id >= TDNumPoints())
        return;

    P[id] = TDIn_P() + float(TDCopyIndex()) * vec3(1.0, 0.0, 0.0);
    TDUpdatePointGroups();   // Preserve group membership
}
```

Similarly for vertex and primitive shaders:
```glsl
// Vertex shader:
TDUpdateTopology();

// Primitive shader:
TDUpdateLineStripsInfo();
TDUpdatePrimGroups();
```

---

## Performance issues with large point counts

**Causes and fixes**:

1. **Too many attribute reads**: Cache values in local variables instead of calling `TDIn_*()` multiple times
2. **Complex neighbor searches**: Use spatial data structures (store in textures via Samplers) instead of brute-force loops
3. **Dynamic loops**: Use fixed iteration counts when possible
4. **Expensive math in hot loops**: Precompute constants, use `TDRemap()` and built-in functions
5. **Unnecessary initialization**: Disable "Initialize Output Attributes" if you write everything

Check cook time with an Info CHOP to measure actual performance.

---

## Multi-pass: output from pass N not visible in pass N+1

**Cause**: Output access mode is set to "Write-Only" instead of "Read-Write".

**Fix**: Change the output access mode to "Read-Write" in the operator parameters. This allows subsequent passes to read the output of previous passes.

---

## Quick Diagnostic Checklist

When your GLSL POP doesn't work:

- [ ] Does `main()` start with `TDIndex()` + bounds check?
- [ ] Are all output attributes listed in the "Output Attributes" parameter?
- [ ] Is the correct "Attribute Class" selected (Point/Vertex/Primitive)?
- [ ] Are you using POP syntax (`TDIn_P`, `P[id]`) and NOT TOP syntax (`vUV`, `fragColor`)?
- [ ] Are all uniforms declared in the shader AND configured on parameter pages?
- [ ] Are uniform names exactly matching (case-sensitive)?
- [ ] Is "Initialize Output Attributes" enabled (if not writing every element)?
- [ ] For GLSL Copy POP: is `TDUpdatePointGroups()` called?
- [ ] For GLSL Advanced POP: are class prefixes correct (`TDInPoint_`, `oTDPoint_`)?
- [ ] Does the shader actually use all declared uniforms? (unused ones get optimized away)
