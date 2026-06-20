# Complete Houdini Python Systems

Full, production-shaped examples. Each is self-contained and notes where it runs.

---

## 1. Procedural carved relief — subtractive workflow

Builds a stone slab and "chisels" a pattern into it with boolean cutters, then weathers the edges with a VDB smooth. Run from a shelf tool or the Python Source Editor.

```python
import hou
import math

def build_carved_relief(n_cuts=12, weather=2):
    """Carve a radial pattern into a slab and weather the surface."""
    obj = hou.node("/obj")
    geo = obj.node("carved_relief") or obj.createNode("geo", "carved_relief")
    for c in geo.children():
        c.destroy()

    # The mass we carve FROM (subtractive: start solid, remove material)
    slab = geo.createNode("box")
    slab.parmTuple("scale").set((4, 0.4, 4))

    # Merge all cutters, then subtract them in one boolean
    cutters = geo.createNode("merge", "cutters")
    for i in range(n_cuts):
        a = (i / n_cuts) * math.tau
        tube = geo.createNode("tube", f"chisel_{i}")
        tube.parm("rad1").set(0.15)
        tube.parm("rad2").set(0.05)        # tapered like a real gouge
        tube.parmTuple("t").set((math.cos(a) * 1.4, 0, math.sin(a) * 1.4))
        tube.parm("rx").set(90)
        cutters.setInput(i, tube)

    boolean = geo.createNode("boolean::2.0")
    boolean.parm("booleanop").set("subtract")
    boolean.setInput(0, slab)
    boolean.setInput(1, cutters)

    # Weathering: SDF smooth erodes sharp boolean seams (like aged stone)
    to_vdb = geo.createNode("vdbfrompolygons")
    to_vdb.setInput(0, boolean)
    erode = geo.createNode("vdbsmoothsdf")
    erode.parm("iterations").set(weather)
    erode.setInput(0, to_vdb)
    back = geo.createNode("convertvdb")
    back.parm("conversion").set("convertToPolygons")
    back.setInput(0, erode)

    normals = geo.createNode("normal")
    normals.setInput(0, back)
    normals.setDisplayFlag(True)
    normals.setRenderFlag(True)
    geo.layoutChildren()
    return geo

build_carved_relief()
```

---

## 2. Clay sculpt setup — additive workflow

Builds a base mass and a stack that behaves like the three clay types: a coarse displace (rough block-in), an inflate (pressing material on), and a smoothing pass whose strength chooses the "clay" — water clay (very soft) vs. polymer (crisper).

```python
import hou

CLAY = {                      # smoothing strength / iterations per medium
    "water":   (0.9, 14),     # smoothest, fingers blur everything
    "oil":     (0.6, 8),      # holds form, still soft
    "polymer": (0.35, 4),     # crisp, keeps tool marks
}

def build_clay_sculpt(medium="oil"):
    strength, iters = CLAY[medium]
    obj = hou.node("/obj")
    geo = obj.node("clay") or obj.createNode("geo", "clay")
    for c in geo.children():
        c.destroy()

    base = geo.createNode("sphere")
    base.parm("type").set("polymesh")
    base.parm("rows").set(80)
    base.parm("cols").set(80)

    # Rough block-in: mountain = layered noise displacement
    blockin = geo.createNode("mountain")
    blockin.parm("height").set(0.4)
    blockin.parm("elementsize").set(1.2)
    blockin.setInput(0, base)

    # Additive build-up: peak/inflate via a point Wrangle generated from Python
    inflate = geo.createNode("attribwrangle", "inflate")
    inflate.parm("snippet").set(
        '@P += @N * fit(noise(@P * 2.0), 0, 1, -0.05, 0.25);')
    inflate.setInput(0, blockin)

    # Smoothing pass = the chosen clay's softness
    smooth = geo.createNode("smooth")
    smooth.parm("strength").set(strength)
    smooth.parm("iterations").set(iters)
    smooth.setInput(0, inflate)
    smooth.setDisplayFlag(True)
    smooth.setRenderFlag(True)
    geo.layoutChildren()
    return geo

build_clay_sculpt("oil")
```

---

## 3. Animation rig applying the 12 principles

Animates a "bouncing, squashing" ball entirely from HOM keyframes, demonstrating squash & stretch, anticipation, ease in/out, and follow-through. Run once; scrub the timeline to see it.

```python
import hou

def animate_bounce(path="/obj/ball", peak=4.0, ground=0.5,
                   start=1, bounce_len=20, bounces=3):
    obj = hou.node(path) or hou.node("/obj").createNode("geo", "ball")
    sphere = obj.node("sphere1") or obj.createNode("sphere")
    sphere.parm("type").set("polymesh")
    xform = obj.node("ctrl") or obj.createNode("xform", "ctrl")
    xform.setInput(0, sphere)
    xform.setDisplayFlag(True)

    ty, sy = xform.parm("ty"), xform.parm("sy")
    ty.deleteAllKeyframes(); sy.deleteAllKeyframes()
    f = start
    h = peak
    for b in range(bounces):
        # --- Anticipation + ease out of the top (slow at apex) ---
        apex = hou.Keyframe(); apex.setFrame(f); apex.setValue(h)
        apex.setInExpression("bezier()"); apex.setOutExpression("bezier()")
        ty.setKeyframe(apex)
        s_apex = hou.Keyframe(); s_apex.setFrame(f); s_apex.setValue(1.15)  # stretch falling
        sy.setKeyframe(s_apex)

        # --- Contact: ease IN (fast), squash on impact ---
        f += bounce_len // 2
        hit = hou.Keyframe(); hit.setFrame(f); hit.setValue(ground)
        hit.setInExpression("bezier()")
        ty.setKeyframe(hit)
        squash = hou.Keyframe(); squash.setFrame(f); squash.setValue(0.6)   # squash & stretch
        sy.setKeyframe(squash)

        # --- Follow-through: pop back to round just after impact ---
        recover = hou.Keyframe(); recover.setFrame(f + 2); recover.setValue(1.0)
        sy.setKeyframe(recover)

        f += bounce_len // 2
        h *= 0.55          # each bounce loses energy (slow in/out + decay)

    hou.playbar.setFrameRange(start, f)
    hou.playbar.setPlaybackRange(start, f)

animate_bounce()
```

Optimized-math alternative (no baked keys — one cheap expression per cook). Set the parm language to Python on `ty`:

```python
# Procedural decaying bounce — abs(sin) gives the bounce, exp() the decay
expr = "abs(sin(hou.time() * 6.0)) * 4.0 * exp(-hou.time() * 0.4) + 0.5"
hou.node("/obj/ball/ctrl").parm("ty").setExpression(
    expr, language=hou.exprLanguage.Python)
```

---

## 4. Render farm script (headless, optimized)

A standalone script for `hython` that loads a scene, sets sane Karma settings, splits the range into chunks, and renders. Designed to be launched per-chunk on a farm.

```python
# render_chunk.py  — run: hython render_chunk.py scene.hip 1 60
import sys
import hou

def render_chunk(hip, start, end, rop_path="/stage/usdrender_rop1"):
    hou.hipFile.load(hip, ignore_load_warnings=True)
    rop = hou.node(rop_path)
    if rop is None:
        raise RuntimeError(f"ROP not found: {rop_path}")

    # --- Optimization: keep it cheap and reproducible ---
    if rop.parm("samplesperpixel"):
        rop.parm("samplesperpixel").set(256)      # converge, don't over-sample
    if rop.parm("denoise"):
        rop.parm("denoise").set(1)                 # denoise instead of brute force
    rop.parm("picture").set("$HIP/render/$OS.$F4.exr")

    # Disable UI cooking overhead is automatic in hython; just render
    rop.render(frame_range=(start, end, 1), verbose=True)
    print(f"Done frames {start}-{end}")

if __name__ == "__main__":
    hip = sys.argv[1]
    a, b = int(sys.argv[2]), int(sys.argv[3])
    render_chunk(hip, a, b)
```

```bash
# Split 240 frames into 4 farm jobs
for i in 0 1 2 3; do
  s=$((i*60 + 1)); e=$(((i+1)*60))
  hython render_chunk.py scene.hip $s $e &
done
wait
```

---

## 5. Scene auditor — find what's slow before you render

Walks the scene, reports the heaviest cooking nodes and any sims that should be cached/frozen.

```python
import hou

def audit_scene(top=10):
    rows = []
    for node in hou.node("/").allSubChildren():
        try:
            t = node.cookCount()           # how many times it has cooked
        except hou.OperationFailed:
            continue
        rows.append((t, node.path(), node.type().name()))
    rows.sort(reverse=True)
    print(f"{'cooks':>7}  {'type':<20} path")
    for t, path, typ in rows[:top]:
        flag = "  <-- consider caching" if typ in ("dopnet", "flipsolver",
                                                    "pyrosolver") else ""
        print(f"{t:>7}  {typ:<20} {path}{flag}")

audit_scene()
```
