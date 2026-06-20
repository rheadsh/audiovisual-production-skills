# Animation — The 12 Principles, Expressions & Optimized Time Math

How to animate in Houdini from Python: setting keyframes with `hou.Keyframe`, driving motion with expressions, and writing time math that stays cheap. The 12 classic Disney principles are the vocabulary; HOM is the implementation.

Runnable rigs are in [../examples/COMPLETE.md](../examples/COMPLETE.md) (`animate_bounce`).

---

## Two ways to animate from Python

**Keyframes** — explicit, art-directable, baked into channels. Use for hero motion you want to hand-tune.

```python
k = hou.Keyframe()
k.setFrame(24)
k.setValue(5.0)
k.setInExpression("bezier()")    # interpolation coming into the key
k.setOutExpression("bezier()")   # leaving the key
parm.setKeyframe(k)
```

**Expressions** — procedural, no baked data, evaluated each cook. Use for cyclic, math-driven, or controllable motion. Set the parm language to Python.

```python
parm.setExpression("sin(hou.time() * 2.0) * amplitude",
                   language=hou.exprLanguage.Python)
```

Rule of thumb: keyframe what the eye must read precisely; express what repeats or derives from other values.

---

## Interpolation functions (set via in/out expression on a key)

| Function | Feel | Principle served |
| --- | --- | --- |
| `constant()` | hold, snap | staging, holds |
| `linear()` | mechanical, even | robotic motion |
| `bezier()` | smooth, hand-tunable tangents | **ease in / ease out**, slow in/out |
| `ease()` / `easein()` / `easeout()` | auto-eased | slow in/out |
| `cubic()` / `spline()` | smooth through many keys | arcs, overlap |
| `qlinear()` | quaternion linear (rotations) | clean rotation |

---

## The 12 principles → HOM

1. **Squash & stretch** — animate non-uniform scale opposite to translate. Volume preservation: when `sy < 1` (squash), widen `sx`/`sz`. Drive `sx = 1/sqrt(sy)` with an expression so volume holds.
2. **Anticipation** — a small key in the opposite direction *before* the main move. Add a pre-key with `bezier()` out.
3. **Staging** — composition/timing; controlled by which channels you key and the playbar range (`hou.playbar.setFrameRange`).
4. **Straight-ahead vs. pose-to-pose** — straight-ahead ≈ per-frame expression; pose-to-pose ≈ sparse keyframes with bezier between.
5. **Follow-through & overlapping action** — secondary parts lag. Offset a child's keys by a few frames, or drive a child parm from the parent by sampling the parent's channel a few frames earlier: `hou.node("../parent").parm("ty").evalAtFrame(hou.frame() - 3)`.
6. **Slow in & slow out** — the everyday case: `bezier()`/`ease()` on both sides of keys. Almost never use `linear()` for organic motion.
7. **Arcs** — motion follows curved paths. Drive position along a parametric curve, or keep X linear while Y eases so the path bows.
8. **Secondary action** — extra channels (a tail wag) running off the main move via expression, scaled down.
9. **Timing** — spacing of keys = perceived weight. Heavier = more frames between extremes. Control via `setFrame` spacing.
10. **Exaggeration** — push amplitudes past realism. Multiply expression amplitudes or scale keyed extremes by a `boost` parm.
11. **Solid drawing** — volume/weight consistency; enforce with the squash/stretch volume formula above.
12. **Appeal** — readability; serve with clear staging, strong silhouettes, clean arcs.

### Squash & stretch with volume preservation (expression)

```python
# On sy: keyed or expression-driven squash.
# On sx and sz, preserve volume automatically:
node.parm("sx").setExpression('1.0 / sqrt(max(hou.ch("./sy"), 0.001))',
                              language=hou.exprLanguage.Python)
node.parm("sz").setExpression('1.0 / sqrt(max(hou.ch("./sy"), 0.001))',
                              language=hou.exprLanguage.Python)
```

---

## Optimized time math

Expressions evaluate **every cook of every dependent node**, so keep them cheap and correct.

**Use the built-in time, don't recompute it.**
```python
hou.frame()         # current frame as float          (preferred)
hou.time()          # seconds = frame / fps
hou.frame() / hou.fps()   # only if you specifically need this form
```

**Frames vs. seconds — be deliberate.** `hou.time()` is FPS-independent (a 2 s cycle stays 2 s at any FPS). `hou.frame()` is frame-locked. For motion that should survive an FPS change, animate in seconds.

**Precompute constants outside the per-cook hot path.** Don't recompute `math.tau`, table lookups, or expensive transcendentals inside an expression that fires thousands of times — bake them into an attribute or a detail value upstream, or move the logic into a single Python SOP that cooks once per frame.

**Prefer cheap periodic functions.**
Python parameter expressions auto-import `sin, cos, tan, exp, sqrt, log, pow, floor, ceil, fabs, radians, degrees` (and more) from `math`, plus everything from `hou` — so `sin()`, `exp()`, `bezier()`, `ch()`, `time()`, `frame()` all work *without* a prefix. Trig from `math` is in **radians**.

```python
sin(hou.time() * w)                       # smooth cycle
abs(sin(hou.time() * w))                   # bounce (rectified)
sin(hou.time()*w) * exp(-hou.time()*d)     # damped oscillation (settle)
hou.frame() % period                       # sawtooth / loop counter
```

**Hscript-only functions:** `noise()`, `rand()`, `fit()`, `fit01()`, `chramp()` are Hscript expression functions — they are **not** in the Python expression namespace. To use them, switch that parm's expression language to Hscript (`'fit01(noise($T), -1, 1)'`), or compute the value in a Python SOP / Wrangle instead. For fit/clamp in Python use `hou.hmath.fit(...)` or plain arithmetic.

**Avoid these in expressions:** opening files, `hou.node()` lookups by string every cook (cache the node), Python loops, and anything O(points). If you need per-point time math, do it in a Wrangle (VEX, parallel) — Python expressions are single-threaded and run on the main thread.

**Cache node lookups.** String path resolution isn't free if it's in a hot expression. For per-frame scripts (not field expressions), resolve `hou.node(...)` once and reuse the handle.

---

## Procedural cycles (no keys)

A walk cycle, idle bob, or flicker is often cleaner as one expression than dozens of keys, and it's instantly retimeable:

```python
# Idle bob + sway
node.parm("ty").setExpression(
    "0.1 * sin(hou.time() * 1.5)", language=hou.exprLanguage.Python)
node.parm("rz").setExpression(
    "3.0 * sin(hou.time() * 0.8 + 1.0)", language=hou.exprLanguage.Python)
```

When you later need to hand-tweak, bake the expression to keys (right-click parm → Keyframes → Bake, or `parm.keyframes()` after setting per-frame values).

---

## Baking an expression to keyframes (Python)

```python
import hou
parm = hou.node("/obj/ball/ctrl").parm("ty")
start, end = (int(x) for x in hou.playbar.frameRange())
parm.deleteAllKeyframes()
for f in range(start, end + 1):
    v = parm.evalAtFrame(f)        # sample the expression
    k = hou.Keyframe(); k.setFrame(f); k.setValue(v)
    k.setExpression("bezier()")
    parm.setKeyframe(k)
```
