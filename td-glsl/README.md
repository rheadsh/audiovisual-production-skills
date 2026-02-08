# TouchDesigner GLSL Skill

A comprehensive skill for writing GLSL shaders in TouchDesigner.

## Structure

```
td-glsl/
├── SKILL.md                      # Main skill file (concise, with links)
├── README.md                     # This file
├── examples/
│   ├── COMPLETE.md              # Full production examples
│   └── PATTERNS.md              # Common shader patterns (copy-paste ready)
├── reference/
│   ├── BEST-PRACTICES.md        # Optimization & organization
│   ├── FUNCTIONS.md             # Complete API reference
│   └── TROUBLESHOOTING.md       # Common errors & solutions
└── templates/
    ├── basic.glsl               # Basic shader template
    ├── generative.glsl          # Generative pattern template
    └── multi-input.glsl         # Multi-input blending template

```

## Installation

### For GitHub CoPilot

#### Workspace-specific

```bash
cp -r td-glsl <workspace-root>/.github/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-glsl ~/.copilot/skills/<skill-folder>/
```

### For Antigravity

#### Workspace-specific

```bash
cp -r td-glsl <workspace-root>/.agent/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-glsl ~/.gemini/antigravity/skills/<skill-folder>/
```


## Usage

LLM will automatically use this skill when you:
- Ask to create GLSL shaders
- Mention TouchDesigner, GLSL TOP, pixel shaders, etc.
- Work with .glsl or .frag files
- Request visual effects or image processing

Example prompts:
- "Create a ripple effect shader for TouchDesigner"
- "Write a GLSL shader that adds chromatic aberration, use /td-glsl skill"
- "Make a feedback loop shader with decay"

## Features

### Progressive Disclosure
The main `SKILL.md` is concise and links to detailed resources:
- Quick start template
- Critical rules
- Common patterns (with links)
- Troubleshooting (with links)

LLM only loads additional files when needed, keeping context efficient.

### Ready-to-Use Templates
- **PATTERNS.md**: 11 copy-paste shader patterns with TD setup instructions
- **Templates folder**: Clean starting points for new shaders
- **COMPLETE.md**: 5 production-ready complex examples

### Comprehensive Reference
- **FUNCTIONS.md**: Every TouchDesigner GLSL function documented
- **BEST-PRACTICES.md**: Performance, organization, debugging
- **TROUBLESHOOTING.md**: Solutions to common compilation errors

### Response Format
When LLM writes shaders using this skill, it provides:
1. **GLSL code** with proper structure and comments
2. **TouchDesigner setup** instructions:
   - Which parameter page to use
   - Exact uniform names and types
   - Values or Python expressions to enter

## Best Practices

When creating new shader patterns:
1. Add to `examples/PATTERNS.md` for common use cases
2. Add to `examples/COMPLETE.md` for complex examples
3. Update `TROUBLESHOOTING.md` if you discover new errors
4. Keep `SKILL.md` concise - link to details in other files

## Version

Current version: 2.0 
