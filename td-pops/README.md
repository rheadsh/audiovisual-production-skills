# TouchDesigner GLSL POPs Skill

A comprehensive skill for writing GLSL compute shaders in TouchDesigner's POP (Point Operator) family.

## Structure

```
td-pops/
├── SKILL.md                      # Main skill file (concise, with links)
├── README.md                     # This file
├── examples/
│   ├── COMPLETE.md              # Full production examples
│   └── PATTERNS.md              # Common compute shader patterns (copy-paste ready)
├── reference/
│   ├── BEST-PRACTICES.md        # Optimization & workflow tips
│   ├── FUNCTIONS.md             # Complete GLSL POP API reference
│   └── TROUBLESHOOTING.md       # Common errors & solutions
└── templates/
    ├── basic-pop.glsl           # Basic GLSL POP template
    ├── advanced-pop.glsl        # GLSL Advanced POP template
    ├── copy-pop.glsl            # GLSL Copy POP instancing template
    └── particle-sim.glsl        # Particle simulation template

```

## Installation

### For GitHub CoPilot

#### Workspace-specific

```bash
cp -r td-pops <workspace-root>/.github/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-pops ~/.copilot/skills/<skill-folder>/
```

### For Antigravity

#### Workspace-specific

```bash
cp -r td-pops <workspace-root>/.agent/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-pops ~/.gemini/antigravity/skills/<skill-folder>/
```


## Usage

LLM will automatically use this skill when you:
- Ask to create GLSL compute shaders for particles or point clouds
- Mention GLSL POP, GLSL Advanced POP, GLSL Copy POP, or GLSL Select POP
- Work with particle systems, point manipulation, or instancing in TouchDesigner
- Request GPU-driven simulations or geometry processing in POP context

Example prompts:
- "Create a particle attraction system using GLSL POP"
- "Write a compute shader that displaces points with noise, use /td-pops skill"
- "Make an instancing shader with GLSL Copy POP"
- "Build a particle simulation with velocity and age"

## Features

### Progressive Disclosure
The main `SKILL.md` is concise and links to detailed resources:
- Quick start template
- Critical rules for compute shaders vs fragment shaders
- Operator selection guide (GLSL POP vs Advanced vs Copy)
- Common patterns (with links)
- Troubleshooting (with links)

LLM only loads additional files when needed, keeping context efficient.

### Ready-to-Use Templates
- **PATTERNS.md**: Copy-paste compute shader patterns with TD setup instructions
- **Templates folder**: Clean starting points for each POP operator type
- **COMPLETE.md**: Production-ready complex examples

### Comprehensive Reference
- **FUNCTIONS.md**: Every TouchDesigner GLSL POP function documented
- **BEST-PRACTICES.md**: Performance, SSBO management, debugging
- **TROUBLESHOOTING.md**: Solutions to common compute shader errors

### Response Format
When LLM writes compute shaders using this skill, it provides:
1. **Which POP operator** to use (GLSL POP, Advanced, Copy, or Select)
2. **GLSL code** with proper structure and comments
3. **Output Attributes** to configure in the operator parameters
4. **TouchDesigner setup** instructions:
   - Attribute class selection
   - Uniform names and types
   - Whether to enable "Initialize Output Attributes"
   - Additional inputs or operator wiring

## Best Practices

When creating new compute shader patterns:
1. Add to `examples/PATTERNS.md` for common use cases
2. Add to `examples/COMPLETE.md` for complex examples
3. Update `TROUBLESHOOTING.md` if you discover new errors
4. Keep `SKILL.md` concise - link to details in other files

## Version

Current version: 1.0
