# SuperCollider Sound Design Skill

A comprehensive skill for sound design and algorithmic composition in SuperCollider.

## Structure

```
sc-designer/
├── SKILL.md                      # Main skill file
├── README.md                     # This file
└── references/
    ├── synthesis.md              # FM, granular, physical modeling, additive, subtractive
    ├── patterns_events.md        # Pbind, Pdef, event types, time control, JITLib
    ├── dsp_effects.md            # Filters, reverb, delay, feedback, FFT/spectral
    └── creative_vocabulary.md    # Chion framework, texture language, compositional gestures
```

## Installation

### For GitHub CoPilot

#### Workspace-specific

```bash
cp -r sc-designer <workspace-root>/.github/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r sc-designer ~/.copilot/skills/<skill-folder>/
```

### For Antigravity

#### Workspace-specific

```bash
cp -r sc-designer <workspace-root>/.agent/skills/<skill-folder>/
```

#### Global (all workspaces)

```bash
cp -r sc-designer ~/.gemini/antigravity/skills/<skill-folder>/
```

## Usage

LLM will automatically use this skill when you:
- Ask for SuperCollider code or synthesis patches
- Mention SynthDefs, Pbind, UGens, or sclang
- Request sound design, algorithmic composition, or granular synthesis
- Describe a sonic texture or musical idea needing SC implementation

Example prompts:
- "Create a warm evolving pad in SuperCollider"
- "Write a granular synthesis patch with irregular density"
- "Make a generative piece with Pdef and multiple voices"

## Features

### Sound-First Philosophy
Every response begins with a **Sonic Intent** statement describing what the sound should *feel* like before any code is written, rooted in Michel Chion's listening modes (causal, semantic, reduced).

### Adaptive Skill Detection
Automatically calibrates depth based on user language:
- **Intermediate**: explains UGen choices, signal flow, and what to tweak
- **Advanced**: sophisticated patches, tradeoffs, alternative approaches

### Complete Reference Library
- **synthesis.md**: FM, granular, physical modeling, additive, subtractive techniques
- **patterns_events.md**: Pbind, Pdef, event types, time control, JITLib live coding
- **dsp_effects.md**: Filters, reverb, delay, feedback, FFT/spectral processing
- **creative_vocabulary.md**: Chion framework, texture language, compositional gestures

### Progressive Disclosure
Main skill file is concise and links to detailed reference files loaded on-demand.

## Response Format

When LLM writes SuperCollider code using this skill, it provides:
1. **Sonic Intent** - perceptual description of the sound
2. **Architecture** - synthesis approach and signal flow
3. **Code** - runnable, clean, commented SuperCollider code
4. **What to Tweak** - 3-5 parameters with sonic descriptions
5. **Go Further** - 2 creative extensions pushing the patch further

## Version

Current version: 1.0 (Initial release)
