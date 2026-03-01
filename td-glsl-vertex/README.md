# TouchDesigner GLSL Vertex Shader Skill

A comprehensive skill for writing GLSL vertex shaders for TouchDesigner's GLSL MAT operator.

## Structure

```
td-glsl-vertex/
├── SKILL.md                      # Main skill file (concise, with links)
├── README.md                     # This file
├── reference/
│   ├── LIGHTING.md               # Phong and PBR lighting in pixel shaders
│   ├── VARYINGS.md               # Varying patterns & interpolation modes
│   └── VERTEX-API.md             # Complete TD vertex function reference
└── templates/
    ├── basic.glsl                # Minimal vertex + pixel pair
    ├── displacement.glsl         # Vertex displacement + pixel
    ├── instancing.glsl           # Instancing-aware shader
    └── lit.glsl                  # Full Phong-lit material

```

## Installation

### For GitHub CoPilot

#### Workspace-specific

```bash
cp -r td-glsl-vertex <workspace-root>/.github/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-glsl-vertex ~/.copilot/skills/<skill-folder>/
```

### For Antigravity

#### Workspace-specific

```bash
cp -r td-glsl-vertex <workspace-root>/.agent/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-glsl-vertex ~/.gemini/antigravity/skills/<skill-folder>/
```


## Usage

LLM will automatically use this skill when you:
- Ask to create vertex shaders or 3D materials
- Mention TouchDesigner, GLSL MAT, vertex displacement, etc.
- Work with mesh deformation, instancing, or custom normals
- Request geometry animation or vertex-based effects

Example prompts:
- "Create a vertex displacement shader for TouchDesigner"
- "Write a GLSL MAT shader with wave deformation, use /td-glsl-vertex skill"
- "Make an instanced particle material with per-instance color"

## Features

### Progressive Disclosure
The main `SKILL.md` is concise and links to detailed resources:
- Quick start vertex + pixel shader pair
- Critical rules for GLSL MAT
- Common patterns (with links)
- Troubleshooting table

LLM only loads additional files when needed, keeping context efficient.

### Ready-to-Use Templates
- **Templates folder**: Clean starting points for new shaders
  - `basic.glsl` — Minimal vertex + pixel pair
  - `displacement.glsl` — Vertex displacement + pixel
  - `instancing.glsl` — Instancing-aware shader
  - `lit.glsl` — Full Phong-lit material

### Comprehensive Reference
- **VERTEX-API.md**: Complete TD vertex function reference
- **VARYINGS.md**: Varying patterns & interpolation modes
- **LIGHTING.md**: Phong and PBR lighting in pixel shaders

### Response Format
When LLM writes shaders using this skill, it provides:
1. **Vertex Shader** — complete GLSL code with comments
2. **Pixel Shader** — complete GLSL code, matching all varyings
3. **TouchDesigner setup** instructions:
   - Load Page: which DAT goes in Vertex Shader / Pixel Shader fields
   - Uniform names, types, values or expressions
   - Render setup notes for instancing or lighting

## Best Practices

When creating new shader patterns:
1. Add new reference material to the `reference/` folder
2. Add new templates to the `templates/` folder
3. Update `SKILL.md` troubleshooting table if you discover new errors
4. Keep `SKILL.md` concise — link to details in other files

## Version

Current version: 1.0
