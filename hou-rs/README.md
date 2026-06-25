# Houdini Redshift Skill

A skill for optimizing Redshift rendering in SideFX Houdini — render settings, sampling, global illumination, lighting, shaders/textures, and command-line/farm rendering.

## Structure

```
hou-rs/
├── SKILL.md                      # Main skill file (concise, with links)
├── README.md                     # This file
├── examples/
│   ├── PATTERNS.md              # Setting presets & hou scripts (ROP, lights, shaders, CLI)
│   └── COMPLETE.md              # Full setups (hyperreal product, stylized, animation GI, farm, AOV audit)
└── reference/
│   ├── RENDER-SETTINGS.md       # Sampling, GI, trace depth, denoise — hyperreal + stylistic presets
│   ├── LIGHTING.md              # Per-light samples, placement, dome/IBL, GI control
│   ├── SHADERS-TEXTURES.md      # RS Standard Material, PBR, displacement, .rstexbin pipeline
│   ├── CLI.md                   # redshiftCmdLine, .rs export, hython/husk, env vars, farming
│   ├── BEST-PRACTICES.md        # VRAM, proxies, animation flicker, speed checklist
│   └── TROUBLESHOOTING.md       # Splotches, flicker, fireflies, OOM, slow renders
└── templates/
    ├── configure_rop.py         # Apply a hyperreal/stylized preset to the Redshift ROP
    ├── batch_render.py          # Headless hython render starter
    └── process_textures.sh      # Batch convert textures to .rstexbin
```

## Installation

### For GitHub CoPilot

```bash
cp -r hou-rs <workspace-root>/.github/skills/     # workspace
cp -r hou-rs ~/.copilot/skills/                    # global
```

### For Antigravity

```bash
cp -r hou-rs <workspace-root>/.agent/skills/      # workspace
cp -r hou-rs ~/.gemini/antigravity/skills/         # global
```

### For Claude Code

```bash
cp -r hou-rs <workspace-root>/.claude/skills/     # workspace
cp -r hou-rs ~/.claude/skills/                     # global
```

### For Codex

```bash
cp -r hou-rs <repo-root>/.agents/skills/          # repo / workspace
cp -r hou-rs ~/.agents/skills/                     # user (global)
```

## Usage

The assistant automatically uses this skill when you:
- Ask to optimize, speed up, or clean up a Redshift render in Houdini
- Mention sampling, GI engines, noise, fireflies, or flicker
- Want hyperrealistic vs. stylized render settings
- Build RS Standard Material networks or process textures
- Render Redshift from the command line / a farm

Example prompts:
- "Give me clean hyperrealistic Redshift settings for a product still"
- "My animation has GI flicker — what GI engine combo should I use?"
- "Reduce noise in my soft shadows without slowing the whole frame"
- "Set up a Redshift farm render with exported .rs files"

## Features

### Two render targets, fully specified
- **Hyperrealistic** — accurate light transport, full GI, fine sampling.
- **Stylistic** — art-directed light, faked/low GI, clamped highlights, heavy denoise.

### Optimization-first philosophy
Every recommendation names the noise source it targets and the trade-off it costs — so you raise the *right* knob (per-light samples, GI rays, trace depth) instead of brute-forcing global samples.

### Covers the full pipeline
Render settings, lighting, shaders/textures, and CLI/farm rendering, plus VRAM and animation-flicker guidance.

### Version-aware
Redshift parm names drift across releases, so scripts set parameters defensively and tell you to confirm names with `node.parms()`. Official docs: https://help.maxon.net/r3d/houdini/en-us/

## Response Format

When the assistant advises on Redshift using this skill, it provides:
1. **What to change and where** — node + parameter
2. **Why** — the noise source or cost it targets
3. **A starting value** — concrete numbers + direction to push
4. **The trade-off** — what gets slower or what look you give up

## Relation to Other Skills

- **`hou-python`** — HOM scripting to drive the ROP, wedge settings, and submit farm jobs.
- **`hou-vex`** — VEX prepares geometry/attributes the renderer consumes.

## Version

Current version: 1.0
