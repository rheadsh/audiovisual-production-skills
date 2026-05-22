# TouchDesigner Python Skill

A comprehensive skill for writing Python scripts in TouchDesigner.

## Structure

```
td-python/
├── SKILL.md                      # Main skill file (concise, with links)
├── README.md                     # This file
├── examples/
│   ├── COMPLETE.md              # Full real-world examples
│   └── PATTERNS.md              # Common scripting patterns (copy-paste ready)
└── reference/
    ├── API.md                   # Complete TD Python API reference
    ├── BEST-PRACTICES.md        # Performance, organization & extension design
    └── TROUBLESHOOTING.md       # Common errors & solutions

```

## Installation

### For GitHub CoPilot

#### Workspace-specific

```bash
cp -r td-python <workspace-root>/.github/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-python ~/.copilot/skills/<skill-folder>/
```

### For Antigravity

#### Workspace-specific

```bash
cp -r td-python <workspace-root>/.agent/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r td-python ~/.gemini/antigravity/skills/<skill-folder>/
```

### For Claude Code

#### Workspace-specific

```bash
cp -r td-python <workspace-root>/.claude/skills/
```

#### Global (all workspaces)

```bash
cp -r td-python ~/.claude/skills/
```


## Usage

LLM will automatically use this skill when you:
- Ask to write Python expressions or callback scripts in TouchDesigner
- Mention DAT scripts, Script OPs, Execute DATs, or Extensions
- Work with parameter automation, OSC, or data-driven components
- Request TouchDesigner Python automation, interaction, or data scripting

Example prompts:
- "Write a Python expression to drive a parameter from audio level"
- "Create a component Extension with custom methods, use /td-python skill"
- "Make an OSC mapper that routes incoming messages to parameters"

## Features

### Progressive Disclosure
The main `SKILL.md` is concise and links to detailed resources:
- Quick start templates for expressions, callbacks, and Script OPs
- Critical rules for TD Python context and scope
- Common patterns (with links)
- Troubleshooting (with links)

LLM only loads additional files when needed, keeping context efficient.

### Ready-to-Use Templates
- **PATTERNS.md**: 15+ copy-paste templates (expressions, CHOP/parameter/panel execute, Script CHOP/TOP/SOP/DAT, extensions, modules)
- **COMPLETE.md**: 6 production-ready examples (sequencer, responsive component, OSC mapper, data dashboard, generative geometry, startup initializer)

### Comprehensive Reference
- **API.md**: Complete TD Python API reference (me, op, par, absTime, ext, mod, DATs, CHOPs, TOPs, SOPs)
- **BEST-PRACTICES.md**: Performance, organization, and extension design patterns
- **TROUBLESHOOTING.md**: Solutions to common errors (parameter access, module recompile, None references, threading)

### Response Format
When LLM writes Python using this skill, it provides:
1. **Python code** with proper TD context and comments
2. **Where to place it** (DAT type, parameter, or Script OP)
3. **TouchDesigner setup** instructions:
   - Which operator and parameter page to use
   - Any required inputs or dependencies
   - Extensions or modules to register

## Best Practices

When creating new scripting patterns:
1. Add to `examples/PATTERNS.md` for common use cases
2. Add to `examples/COMPLETE.md` for complex examples
3. Update `TROUBLESHOOTING.md` if you discover new errors
4. Keep `SKILL.md` concise - link to details in other files

## Version

Current version: 1.0
