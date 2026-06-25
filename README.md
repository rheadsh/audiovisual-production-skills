# Audiovisual Production Skills

A curated collection of production-ready Skills for audiovisual workflows. Build, optimize, and share expertise across creative coding, real-time graphics, video processing, and interactive media production.

## Installation

Copy any skill folder into the skills directory for your AI coding assistant.

### For Antigravity

```bash
cp -r <skill-folder> <workspace-root>/.agent/skills/      # workspace
cp -r <skill-folder> ~/.gemini/antigravity/skills/         # global
```

### For Claude Code

```bash
cp -r <skill-folder> <workspace-root>/.claude/skills/     # workspace
cp -r <skill-folder> ~/.claude/skills/                     # global
```

### For Codex

Codex reads skills from `.agents/skills` directories (scanned from your working directory up to the repo root) and from `~/.agents/skills` for user-global skills. See the [Codex skills docs](https://developers.openai.com/codex/skills).

```bash
cp -r <skill-folder> <repo-root>/.agents/skills/          # repo / workspace
cp -r <skill-folder> ~/.agents/skills/                     # user (global)
```

Codex detects skill changes automatically; restart Codex if a new skill doesn't appear. To disable a skill without removing it, add a `[[skills.config]]` entry pointing at its `SKILL.md` in `~/.codex/config.toml`:

```toml
[[skills.config]]
path = "/path/to/<skill-folder>/SKILL.md"
enabled = false
```

### For GitHub CoPilot

```bash
cp -r <skill-folder> <workspace-root>/.github/skills/     # workspace
cp -r <skill-folder> ~/.copilot/skills/                    # global
```

See each skill's `README.md` for exact folder names and usage examples.

## Available Skills

### TouchDesigner GLSL (`td-glsl`)
Pixel shader development skill with:
- 11 ready-to-use shader patterns
- 5 production examples (kaleidoscope, particles, reaction-diffusion, SDF rendering, color grading)
- Complete TouchDesigner GLSL API reference
- Performance optimization & best practices
- Troubleshooting guide for common errors
- Clean starter templates

### TouchDesigner GLSL Vertex (`td-glsl-vertex`)
Vertex shader development skill for TouchDesigner's GLSL MAT operator with:
- Complete vertex + pixel shader pair workflow
- Vertex displacement, wave deformation, and mesh animation patterns
- Instancing support with per-instance data sampling
- TD vertex function reference (TDDeform, TDWorldToProj, etc.)
- Varying patterns & interpolation modes
- Phong and PBR lighting reference
- Starter templates (basic, displacement, instancing, lit)

### TouchDesigner GLSL POPs (`td-pops`)
GLSL compute shader skill for TouchDesigner's POP (Point Operator) family with:
- GLSL POP, GLSL Advanced POP, GLSL Copy POP, and GLSL Select POP support
- Particle systems, point cloud manipulation, and GPU-driven simulations
- Compute shader patterns for attraction, noise displacement, age-based fading
- Instancing workflows with GLSL Copy POP
- Complete GLSL POP API reference (TDIndex, TDIn_ accessors, SSBO output arrays)
- Starter templates for each POP operator type

### TouchDesigner Python (`td-python`)
Python scripting skill for TouchDesigner with:
- Parameter expressions, callback DATs, Script OPs, Extensions, and module patterns
- 15+ ready-to-use templates (expressions, CHOP/parameter/panel execute, Script CHOP/TOP/SOP/DAT, extensions, modules)
- 6 complete real-world examples (sequencer, responsive component, OSC mapper, data dashboard, generative geometry, startup initializer)
- Full TD Python API reference (me, op, par, absTime, ext, mod, DATs, CHOPs, TOPs, SOPs)
- Troubleshooting guide for common errors (.eval(), module recompile, None references, threading)
- Best practices for performance, organization, and extension design

### Houdini VEX (`hou-vex`)
Complete VEX programming skill for SideFX Houdini with:
- 40+ ready-to-use VEX snippets
- All wrangle contexts (Point, Prim, Detail, Vertex)
- Complete VEX function reference
- Performance optimization & best practices
- Troubleshooting guide for common errors
- Starter templates for each context

### Houdini Python (`hou-python`)
Python (HOM) scripting skill for SideFX Houdini with:
- Procedural modeling translated from traditional craft: carving (wood/stone/wax, subtractive) and clay sculpting (water/oil/polymer, additive)
- Animation via HOM: the 12 principles as keyframe interpolation + expressions, and optimized time math
- Python-driven render automation (Karma/Mantra/ROP), frame-range farming, wedging, and an optimization checklist
- Full HOM API reference (Node, Geometry, Parm, Keyframe, ROPs, math) verified against the Houdini 21 docs
- Copy-paste patterns, complete systems (carved relief, clay sculpt, bounce rig, render farm, scene auditor)
- Best practices (bulk attributes, Python-vs-VEX) and a troubleshooting guide
- Starter templates (Python SOP, animation rig, headless batch render)

### Houdini Redshift (`hou-rs`)
Redshift render optimization skill for SideFX Houdini with:
- Two fully specified render targets: hyperrealistic (full GI, fine sampling) and stylistic (art-directed light, faked/low GI, clamped highlights)
- Sampling, GI engine selection, trace depth, and denoise guidance with concrete presets
- Lighting optimization: per-light samples, placement, dome/IBL importance sampling, portals, GI control
- Shaders & textures: RS Standard Material PBR, displacement, and the `.rstexbin` texture pipeline
- CLI / farm rendering: `redshiftCmdLine`, `.rs` archive export, hython/husk, env vars, chunked dispatch
- Optimization-first advice that names the noise source and trade-off for every knob
- Best practices (VRAM, proxies, animation flicker) and a troubleshooting guide
- Starter templates (configure ROP preset, batch render, texture processing)

### SuperCollider Sound Design (`sc-designer`)
Sound design and algorithmic composition skill with:
- SynthDef creation with idiomatic SC style
- Pattern-based composition (Pbind, Pdef, JITLib)
- Synthesis techniques (FM, granular, physical modeling, additive, subtractive)
- DSP effects chains (filters, reverb, delay, spectral processing)
- Creative vocabulary rooted in Chion's listening modes
- Adaptive skill level detection (intermediate/advanced)