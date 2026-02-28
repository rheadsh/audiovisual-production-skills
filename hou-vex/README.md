# Houdini VEX Skill

A comprehensive Claude Code skill for writing VEX code in SideFX Houdini.

## Structure

```
houdini-vex/
├── SKILL.md                      # Main skill file
├── README.md                     # This file
├── examples/
│   ├── PATTERNS.md              # 40+ ready-to-use VEX snippets
│   └── COMPLETE.md              # Full procedural systems (TODO)
├── reference/
│   ├── FUNCTIONS.md             # Complete VEX function reference (TODO)
│   ├── CONTEXTS.md              # Deep dive into contexts (TODO)
│   ├── BEST-PRACTICES.md        # Optimization guide (TODO)
│   └── TROUBLESHOOTING.md       # Common errors & solutions
└── templates/
    ├── point_wrangle.vfl        # Point wrangle starter
    ├── primitive_wrangle.vfl    # Primitive wrangle starter (TODO)
    └── detail_wrangle.vfl       # Detail wrangle starter (TODO)
```

## Installation

### For Personal Use
```bash
cp -r houdini-vex ~/.claude/skills/
```

### For Team/Project
```bash
cp -r houdini-vex /path/to/project/.claude/skills/
git add .claude/skills/houdini-vex
git commit -m "Add Houdini VEX skill"
```

## Usage

Claude will automatically use this skill when you:
- Ask to write VEX code
- Mention Houdini, wrangles, VOPs
- Work with .vfl files
- Request geometry manipulation or procedural modeling

Example prompts:
- "Create a VEX snippet to scatter points on a surface"
- "Write a point wrangle that creates a spiral pattern"
- "Make a particle system with VEX"

## Features

### Ready-to-Use Patterns
**PATTERNS.md** includes 40+ copy-paste snippets:
- Point manipulation (move, scale, smooth)
- Attribute creation and transfer
- Neighbor operations
- Noise and displacement
- Color and visualization
- Particle systems
- Primitive operations
- UV manipulation
- Groups and selection
- Matrix transforms

### Comprehensive Troubleshooting
**TROUBLESHOOTING.md** covers:
- Type mismatch errors
- Attribute not found
- Performance issues
- Wrong results in loops
- Group problems
- Random number generation
- Normal calculation
- Matrix transforms
- Common gotchas

### Progressive Disclosure
Main skill file is concise and links to detailed resources loaded on-demand.

## Key Concepts

### @ Syntax
VEX uses `@` to access geometry attributes:
```c
@P      // Position
@N      // Normal
@Cd     // Color
@ptnum  // Point number
```

### Type Prefixes
Specify attribute types with prefixes:
```c
v@velocity  // vector
i@id        // integer
s@name      // string
f@custom    // float
```

### Context-Aware
Code runs per-element based on wrangle type:
- **Point Wrangle**: Runs per point
- **Primitive Wrangle**: Runs per primitive
- **Detail Wrangle**: Runs once for all geometry
- **Vertex Wrangle**: Runs per vertex

### Multi-threaded
VEX automatically parallelizes - no threading code needed!

## Response Format

When Claude writes VEX using this skill, it provides:
1. **VEX code** with clear comments
2. **Wrangle type** (Point/Prim/Detail/Vertex)
3. **Required inputs** if any
4. **Expected attributes** that must exist
5. **Parameters** to create using "Edit Parameter Interface"

## Version

Current version: 1.0 (Initial release)

## Contributing

Feel free to add more patterns, examples, and documentation!

## License

Free to use and modify.
