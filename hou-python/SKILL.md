---
name: hou-python
description: Write Python (HOM) for SideFX Houdini — procedural modeling, animation, and render automation. Use when scripting the hou module, Python SOPs, parameter expressions, keyframe/animation rigs, ROP/Karma render farming, or translating sculpting and carving workflows into procedural code. Triggers on hou.node, hou.Geometry, Python SOP, hython, .hip automation, or any Houdini Python task.
---

# Houdini Python (HOM) Scripting

Write Python with the Houdini Object Model (HOM) for procedural modeling, animation, and optimized rendering. The `hou` package is the root of the API and is auto-imported inside parameter expressions and `hython`; everywhere else you `import hou`.

## Quick Start

There are four main places Python runs in Houdini:

```python
# 1. PARAMETER EXPRESSION (one-liner, language set to Python, auto-cooks)
hou.frame()                                  # current frame
hou.ch("../master/scale")                    # value of another parm
hou.pwd().parm("ty").eval() * 2

# 2. PYTHON SOP (generate/modify geometry per cook)
node = hou.pwd()
geo = node.geometry()
pt = geo.createPoint()
pt.setPosition((0, 1, 0))

# 3. SHELF / SCRIPT / hython (drive the whole scene)
import hou
geo_obj = hou.node("/obj").createNode("geo", "carved_block")
box = geo_obj.createNode("box")
box.parm("scale").set(2.0)

# 4. CALLBACKS & EVENTS (react to parm changes, scene events)
def onParmChanged(node, **kwargs):
    hou.node("/obj/light1").parm("dimmer").set(node.parm("intensity").eval())
```

## Critical Rules

1. **`hou.pwd()` is the running node** — inside a Python SOP it returns that SOP; `hou.pwd().geometry()` is the geometry to build into.
2. **`.eval()` to get a value, `.set()` to write** — `node.parm("tx").eval()` reads; `node.parm("tx").set(5)` writes. Use `parmTuple` for vectors: `node.parmTuple("t").set((1,2,3))`.
3. **Bulk attribute access beats per-element loops** — `geo.setPointFloatAttribValues(...)` / `geo.pointFloatAttribValues(...)` are an order of magnitude faster than iterating `geo.points()` in Python.
4. **Never trigger cooks in a tight loop** — batch edits, then let Houdini cook once. Wrap large scene edits in `with hou.undos.disabler():` for speed when undo isn't needed.
5. **Math runs once per cook in expressions** — keep expressions cheap; move heavy work into a Python SOP or cache it as an attribute. Prefer `hou.frame()`/`hou.time()` over recomputing time.
6. **Python is single-threaded; VEX is not** — for per-point math at scale, generate a Wrangle from Python rather than looping points in Python. (See `hou-vex`.)

## The Core Objects (under the `hou` module)

```python
hou.node("/obj/geo1")          # node by absolute path  -> hou.Node
hou.pwd()                       # the node running this code
hou.parent()                    # parent of the running node
hou.ch("../ctrl/speed")         # quick parm read (expression shorthand)
hou.frame()                     # current frame (float)
hou.time()                      # current time in seconds
hou.fps()                       # scene FPS
hou.playbar.setFrameRange(1,240)
hou.hipFile.path()              # current .hip path
hou.pwd().geometry()            # hou.Geometry of the running SOP
```

## Three Domains This Skill Covers

This skill maps three production domains onto HOM Python. Each has a dedicated reference:

**1. Procedural Modeling — carving & sculpting as code.**
Traditional craft splits into *subtractive* (carving wood, stone, wax — remove material from a mass) and *additive* (clay sculpting — push, pinch, and build up form). Both map cleanly to procedural operations. See [reference/MODELING.md](reference/MODELING.md) for the full translation table and recipes:
- Subtractive (boolean carving, displacement erosion, chiseling with VDBs)
- Additive (clay-like push/inflate, polymer vs. oil vs. water clay behaviour, smoothing)
- Build geometry from scratch in a Python SOP, drive HDA carving tools, VDB sculpt loops

**2. Animation — the 12 principles, expressions, optimized time math.**
See [reference/ANIMATION.md](reference/ANIMATION.md) for keyframing via HOM, expression-driven motion, and how the 12 classic principles (squash & stretch, anticipation, ease in/out, follow-through, etc.) become `hou.Keyframe`, bezier interpolation, and cheap time functions.

**3. Rendering — Python-driven, optimized.**
See [reference/RENDERING.md](reference/RENDERING.md) for batch ROP/Karma rendering, frame-range farming with `hython`, wedging, dependency-aware output, and the optimization checklist (cook once, freeze sims, defer-load, sane bucket/sample settings).

## Common Patterns

See [examples/PATTERNS.md](examples/PATTERNS.md) for copy-paste templates:
- Node creation, wiring, and layout
- Parameter read/write, keyframes, expressions
- Building geometry in a Python SOP (points, polys, attributes — bulk and per-element)
- Carving (boolean / VDB) and clay (smooth / inflate) recipes
- Animation rigs and the 12 principles in code
- Batch rendering and wedging

## Response Format

When providing Houdini Python, always include:

1. **Python code** with comments.
2. **Context** — where it goes (parameter expression, Python SOP, shelf tool, `hython` script, or event callback).
3. **Houdini setup** — which nodes to create, how to wire them, parameters to set, and whether the parm language must be switched to Python.
4. **Performance note** — if the operation could cook heavily, say how to keep it cheap (bulk attrib calls, freeze, cook once).

## Writing Process

1. Identify the context (expression / Python SOP / standalone `hython` / callback).
2. Choose Python vs. VEX — heavy per-point math should be VEX generated *from* Python.
3. Write the minimal working script, then add error handling.
4. Note required node connections, parm setup, and the cook/render cost.

## Additional Resources

- [examples/PATTERNS.md](examples/PATTERNS.md) — Ready-to-use templates per context
- [examples/COMPLETE.md](examples/COMPLETE.md) — Full systems (procedural carved relief, clay-sculpt setup, animation rig, render farm script)
- [reference/API.md](reference/API.md) — Core HOM API (hou.Node, hou.Geometry, hou.Parm, hou.Keyframe, ROPs)
- [reference/MODELING.md](reference/MODELING.md) — Carving & clay-sculpting workflows in Python
- [reference/ANIMATION.md](reference/ANIMATION.md) — 12 principles, expressions, optimized time math
- [reference/RENDERING.md](reference/RENDERING.md) — Render automation & optimization
- [reference/BEST-PRACTICES.md](reference/BEST-PRACTICES.md) — Performance, organization, style
- [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) — Common errors & fixes
- [templates/](templates/) — Starter scripts (Python SOP, animation, batch render)

## Key Differences from Other Languages

**From TouchDesigner Python (`td-python`):**
- `hou.pwd()` ≈ `me`; `hou.node(path)` ≈ `op(path)`; `.eval()`/`.set()` instead of direct par assignment.
- Houdini cooks a dependency graph on demand — there is no continuous per-frame `onCook` unless you render or scrub.

**From VEX (`hou-vex`):**
- Python is single-threaded and runs once per cook; VEX runs per-element in parallel.
- Use Python to *orchestrate* (build networks, set parms, render); use VEX/Wrangles for *per-point math at scale*.
