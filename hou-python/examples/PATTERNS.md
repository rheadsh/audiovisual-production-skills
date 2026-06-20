# Common Houdini Python (HOM) Patterns

Ready-to-use templates. Copy and adapt. Unless noted, these run from a shelf tool, the Python Source Editor, or `hython`. Snippets marked **(Python SOP)** go inside a Python SOP; **(expression)** go in a parameter field with its language set to Python.

---

## Nodes — create, wire, lay out

```python
import hou

obj = hou.node("/obj")
geo = obj.createNode("geo", "carved_block")        # create child, name it
box = geo.createNode("box")
mountain = geo.createNode("mountain")              # displacement noise
mountain.setInput(0, box)                           # wire box -> mountain
mountain.setDisplayFlag(True)
mountain.setRenderFlag(True)
geo.layoutChildren()                                # tidy the network
```

```python
# Find / iterate / delete
n = hou.node("/obj/geo1/box1")
for child in hou.node("/obj/geo1").children():
    print(child.name(), child.type().name())
if n is not None:
    n.destroy()
```

---

## Parameters — read, write, vectors

```python
n = hou.node("/obj/geo1/transform1")

n.parm("tx").set(5.0)                 # set one component
n.parmTuple("t").set((1, 2, 3))       # set a vector parm at once
val = n.parm("tx").eval()             # read evaluated value
vec = n.parmTuple("t").eval()         # -> (x, y, z) tuple

# Reference another parm via expression (Python language)
n.parm("ty").setExpression('hou.ch("../master/height")',
                           language=hou.exprLanguage.Python)
```

```python
# (expression) — one-liners that live in a parm field, language = Python
hou.frame()                                  # current frame
hou.ch("../ctrl/speed") * hou.time()         # another parm * time
hou.pwd().parmTuple("t").eval()[1]           # this node's ty
```

---

## Keyframes & animation (HOM)

```python
import hou
n = hou.node("/obj/geo1/transform1")

# Single keyframe
key = hou.Keyframe()
key.setFrame(1)
key.setValue(0.0)
n.parm("ty").setKeyframe(key)

# Second key with ease (bezier) — see ANIMATION.md for the 12 principles
key2 = hou.Keyframe()
key2.setFrame(24)
key2.setValue(5.0)
key2.setInExpression("bezier()")     # smooth ease in/out
key2.setOutExpression("bezier()")
n.parm("ty").setKeyframe(key2)
```

```python
# Expression-driven (no baked keys) — bouncing ease, evaluated per frame
expr = "abs(sin(hou.time() * 3.0)) * 2.0"
n.parm("ty").setExpression(expr, language=hou.exprLanguage.Python)
```

---

## Build geometry in a Python SOP — per-element

```python
# (Python SOP) — small geometry, readable
node = hou.pwd()
geo = node.geometry()

cd = geo.addAttrib(hou.attribType.Point, "Cd", (1.0, 1.0, 1.0))
for i in range(20):
    pt = geo.createPoint()
    pt.setPosition((i * 0.5, 0, 0))
    pt.setAttribValue(cd, (i / 20.0, 0.2, 1.0 - i / 20.0))
```

## Build geometry in a Python SOP — bulk (fast)

```python
# (Python SOP) — many points: build flat lists, set in one call
import math
node = hou.pwd()
geo = node.geometry()

n = 50000
positions = []
for i in range(n):
    a = i * 0.01
    positions += [math.cos(a) * a, 0.0, math.sin(a) * a]   # flat [x,y,z,...]

geo.createPoints([(0, 0, 0)] * n)          # allocate n points
geo.setPointFloatAttribValues("P", positions)   # write all positions at once
```

```python
# Bulk READ then write back — vectorized-style edit
node = hou.pwd()
geo = node.geometry()
P = geo.pointFloatAttribValues("P")        # flat tuple, length = 3 * npoints
P = [v * 1.5 for v in P]                    # scale everything
geo.setPointFloatAttribValues("P", P)
```

---

## Make a polygon

```python
# (Python SOP) — a single quad
node = hou.pwd()
geo = node.geometry()
pts = [geo.createPoint() for _ in range(4)]
coords = [(0,0,0), (1,0,0), (1,0,1), (0,0,1)]
for pt, c in zip(pts, coords):
    pt.setPosition(c)
poly = geo.createPolygon()
for pt in pts:
    poly.addVertex(pt)
```

---

## Carving (subtractive) — boolean & VDB

```python
# Boolean "chisel": subtract a cutter from a block (network built via Python)
geo = hou.node("/obj").createNode("geo", "carve")
block  = geo.createNode("box")
cutter = geo.createNode("sphere")
cutter.parmTuple("t").set((0.4, 0.4, 0))
boolean = geo.createNode("boolean::2.0")
boolean.parm("booleanop").set("subtract")   # A minus B
boolean.setInput(0, block)
boolean.setInput(1, cutter)
boolean.setDisplayFlag(True)
geo.layoutChildren()
```

```python
# VDB erosion "weathering" — convert to VDB, smooth/erode, convert back
geo = hou.node("/obj/rock/OUT")             # incoming mesh SOP
container = geo.parent()
to_vdb   = container.createNode("vdbfrompolygons")
smooth   = container.createNode("vdbsmoothsdf")  # erode the surface
smooth.parm("iterations").set(3)
to_poly  = container.createNode("convertvdb")
to_poly.parm("conversion").set("convertToPolygons")
to_vdb.setInput(0, geo)
smooth.setInput(0, to_vdb)
to_poly.setInput(0, smooth)
container.layoutChildren()
```

---

## Clay (additive) — smooth & inflate

```python
# (Python SOP) — "inflate" along normals: additive build-up like pressing clay
import hou
node = hou.pwd()
geo = node.geometry()
amount = node.evalParm("amount") if node.parm("amount") else 0.1   # parm-driven

# Needs point normals on input (add a Normal SOP upstream)
P = geo.pointFloatAttribValues("P")
N = geo.pointFloatAttribValues("N")
P = [p + n * amount for p, n in zip(P, N)]
geo.setPointFloatAttribValues("P", P)
```

```python
# Clay smoothing chain (water-clay = very smooth, polymer = crisper)
container = hou.node("/obj/sculpt")
smooth = container.createNode("smooth")
smooth.parm("strength").set(0.8)      # higher = softer / water-clay
smooth.parm("iterations").set(10)
```

---

## Batch rendering

```python
# Render a frame range from a ROP / Karma node
import hou
rop = hou.node("/out/karma1")          # or /stage/usdrender_rop1, /out/mantra1
rop.render(frame_range=(1, 240, 1), verbose=True)
```

```python
# Render only what's needed and write versioned files
import hou
rop = hou.node("/out/karma1")
rop.parm("picture").set("$HIP/render/v003/beauty.$F4.exr")
rop.render(frame_range=(int(hou.playbar.frameRange()[0]),
                        int(hou.playbar.frameRange()[1])))
```

```bash
# Headless render from the command line (no UI = faster, farmable)
hython -c "import hou; hou.hipFile.load('scene.hip'); hou.node('/out/karma1').render(frame_range=(1,240))"
```

---

## Wedging (parameter sweeps)

```python
# Render several variations by sweeping a parameter
import hou
ctrl = hou.node("/obj/geo1/mountain1")
rop  = hou.node("/out/karma1")
for i, height in enumerate([0.5, 1.0, 1.5, 2.0]):
    ctrl.parm("height").set(height)
    rop.parm("picture").set(f"$HIP/render/wedge_{i:02d}.$F4.exr")
    rop.render(frame_range=(1, 1))
```

---

## Speed-ups you'll reuse

```python
# Disable undo while doing a big scene edit
with hou.undos.disabler():
    for i in range(1000):
        hou.node("/obj").createNode("null", f"n_{i}")

# Freeze a sim/heavy SOP to geometry so it stops cooking
src = hou.node("/obj/sim/OUT")
frozen = src.parent().createNode("file")
frozen.parm("file").set("$HIP/geo/frozen.bgeo.sc")
# (write it once with a ROP geometry node, then read it back)
```
