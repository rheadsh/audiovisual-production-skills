---
name: hou-vex
description: Write VEX code for Houdini SOPs, DOPs, COPs, and shaders. Use when creating geometry manipulation scripts, particle systems, procedural modeling, shaders, or working with .vfl files, wrangles, or VOPs in SideFX Houdini.
---

# Houdini VEX Programming

Write high-performance VEX code for geometry manipulation, simulation, and shading in Houdini.

## Quick Start

Basic Point Wrangle pattern:

```c
// Access and modify point position
@P += @N * 0.1;

// Set color based on position
@Cd = normalize(@P);
```

## Critical Concepts

1. **@ Syntax**: Use `@` to access attributes (`@P`, `@Cd`, `@N`)
2. **Type Prefixes**: Specify types with prefixes (`v@`, `i@`, `s@`, `f@`)
3. **Context Matters**: Code runs per-point, per-prim, or per-detail depending on wrangle type
4. **No Recursion**: Functions are inlined by compiler
5. **Multi-threaded**: Code runs in parallel automatically

## Attribute Access

```c
// Automatic type detection for known attributes
@P         // vector - position
@N         // vector - normal  
@Cd        // vector - color
@pscale    // float - point scale

// Manual type specification for custom attributes
v@velocity  // vector
i@id        // integer
s@name      // string
f@custom    // float
```

## Common Patterns

See [examples/PATTERNS.md](examples/PATTERNS.md) for ready-to-use code:
- Point manipulation
- Neighbor operations
- Group creation
- Attribute transfer
- Noise displacement
- Particle systems

## VEX Contexts

**Point Wrangle**: Runs per-point (most common)
- Access: `@ptnum`, `@numpt`
- Use: Deform, scatter, color

**Primitive Wrangle**: Runs per-primitive
- Access: `@primnum`, `@numprim`
- Use: Primitive operations, extrusions

**Detail Wrangle**: Runs once for entire geometry
- Access: Detail attributes only
- Use: Global calculations, metadata

**Vertex Wrangle**: Runs per-vertex
- Access: `@vtxnum`, `@numvtx`
- Use: UV manipulation, vertex colors

## Essential Functions

```c
// Geometry queries
int nearpoints(geometry; vector pos; float radius)
int neighbours(geometry; int ptnum)
vector point(geometry; string attr; int ptnum)

// Attribute creation
addpoint(geometry; vector pos)
removepoint(geometry; int ptnum)
setpointattrib(geometry; string name; int ptnum; value)

// Noise
float noise(vector pos)
vector curlnoise(vector pos)
vnoise(vector pos)

// Math
normalize(vector)
distance(vector, vector)
dot(vector, vector)
cross(vector, vector)
```

## Response Format

When providing VEX code, always include:

1. **VEX Code** with comments explaining logic
2. **Wrangle Type** (Point/Prim/Detail/Vertex)
3. **Required Inputs** if any
4. **Expected Attributes** that must exist
5. **Parameters** to create if using `ch()` functions

## Common Functions

See [reference/FUNCTIONS.md](reference/FUNCTIONS.md) for complete API including:
- Geometry manipulation
- Attribute operations
- Math and vectors
- Noise and randomness
- Groups and selection

## Best Practices

See [reference/BEST-PRACTICES.md](reference/BEST-PRACTICES.md) for:
- Performance optimization
- Memory efficiency
- Code organization
- Debugging strategies

## Troubleshooting

See [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) for solutions to:
- Type mismatch errors
- Attribute not found
- Performance issues
- Common syntax mistakes

## Additional Resources

- [examples/COMPLETE.md](examples/COMPLETE.md) - Full procedural systems
- [templates/](templates/) - Starter code for common tasks
- [reference/CONTEXTS.md](reference/CONTEXTS.md) - Deep dive into each context

## Key Differences from Other Languages

**From Python:**
- No recursion
- Strongly typed
- Runs per-element (parallel)
- Use @ for attributes, not variable names

**From C/C++:**
- Context-specific entry points
- No pointers
- Built-in vector/matrix types
- Automatic parallelization

**From GLSL:**
- Geometry manipulation focus
- Different attribute system
- More procedural modeling functions
- Different execution model
