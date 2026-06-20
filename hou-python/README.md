# Houdini Python Skill

A comprehensive skill for writing Python (HOM) in SideFX Houdini — procedural modeling, animation, and render automation.

## Structure

```
hou-python/
├── SKILL.md                      # Main skill file (concise, with links)
├── README.md                     # This file
├── examples/
│   ├── PATTERNS.md              # Copy-paste HOM snippets (nodes, parms, geo, carving, clay, render)
│   └── COMPLETE.md              # Full systems (carved relief, clay sculpt, bounce rig, render farm, auditor)
├── reference/
│   ├── API.md                   # Core HOM API (Node, Geometry, Parm, Keyframe, ROPs, math)
│   ├── MODELING.md              # Carving (subtractive) & clay (additive) workflows in Python
│   ├── ANIMATION.md             # 12 principles, expressions, optimized time math
│   ├── RENDERING.md             # Render automation & optimization
│   ├── BEST-PRACTICES.md        # Performance, organization, style, Python-vs-VEX
│   └── TROUBLESHOOTING.md       # Common errors & fixes
└── templates/
    ├── python_sop.py            # Python SOP starter (bulk geometry)
    ├── animation_setup.py       # Keyframe + expression rig starter
    └── batch_render.py          # Headless hython render starter
```

## Installation

### For GitHub CoPilot

```bash
cp -r hou-python <workspace-root>/.github/skills/     # workspace
cp -r hou-python ~/.copilot/skills/                    # global
```

### For Antigravity

```bash
cp -r hou-python <workspace-root>/.agent/skills/      # workspace
cp -r hou-python ~/.gemini/antigravity/skills/         # global
```

### For Claude Code

```bash
cp -r hou-python <workspace-root>/.claude/skills/     # workspace
cp -r hou-python ~/.claude/skills/                     # global
```

## Usage

The assistant automatically uses this skill when you:
- Ask to write Houdini Python / HOM (`hou` module) code
- Mention Python SOPs, parameter expressions, keyframes, or ROP/Karma rendering
- Want procedural modeling described as carving or clay sculpting
- Automate `.hip` files or render farms with `hython`

Example prompts:
- "Write a Python SOP that scatters points in a spiral, use /hou-python skill"
- "Build a procedural carved stone relief with booleans and VDB weathering"
- "Animate a bouncing ball from HOM keyframes applying squash & stretch"
- "Batch render frames 1-240 of my Karma scene headless and split into 4 jobs"

## Features

### Three production domains
- **Procedural modeling** — traditional carving (wood/stone/wax, subtractive) and clay sculpting (water/oil/polymer, additive) mapped onto Houdini operations and driven from Python.
- **Animation** — the 12 principles of animation expressed as `hou.Keyframe` interpolation and expressions, plus optimized time math.
- **Rendering** — Python-driven batch/farm rendering with a concrete optimization checklist.

### Progressive disclosure
`SKILL.md` is concise and links to detailed references and examples loaded on demand.

### Verified against HOM
API names and signatures checked against the Houdini 21 HOM documentation
(https://www.sidefx.com/docs/houdini/hom/index.html).

### Response format
When the assistant writes Houdini Python using this skill, it provides:
1. Python code with comments
2. Context — where it goes (expression / Python SOP / shelf / hython / callback)
3. Houdini setup — nodes to create, wiring, parms, and whether to switch parm language to Python
4. A performance note when the operation could cook or render heavily

## Best Practices

When adding new patterns:
1. Add common snippets to `examples/PATTERNS.md`
2. Add full systems to `examples/COMPLETE.md`
3. Record new errors in `reference/TROUBLESHOOTING.md`
4. Keep `SKILL.md` concise — link to details

## Version

Current version: 1.0
