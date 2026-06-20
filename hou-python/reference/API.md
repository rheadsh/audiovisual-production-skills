# Houdini HOM Python API Reference

Core of the `hou` module. Full docs: https://www.sidefx.com/docs/houdini/hom/hou/index.html
`hou` is auto-imported in parameter expressions and `hython`; `import hou` everywhere else.

---

## Module-level functions

```python
hou.node(path)                  # -> hou.Node or None   (absolute or relative path)
hou.nodes(paths)                # -> tuple of nodes
hou.pwd()                       # -> the node running the current code
hou.parent()                    # -> parent of hou.pwd()
hou.selectedNodes()             # -> tuple of selected nodes
hou.ch(path)                    # -> float value of a parm (expression shorthand)
hou.chs(path)                   # -> string value of a parm

hou.frame()                     # current frame (float)
hou.setFrame(f)                 # jump to frame f
hou.time()                      # current time in seconds
hou.fps()                       # scene frames per second

hou.hipFile.path()              # current .hip path
hou.hipFile.load(path, ignore_load_warnings=False)
hou.hipFile.save(path=None)
hou.hipFile.clear()

hou.playbar.frameRange()        # -> (start, end)
hou.playbar.setFrameRange(s, e)
hou.playbar.setPlaybackRange(s, e)

hou.expandString(s)             # expand $HIP, $F, etc.
hou.getenv(name) / hou.putenv(name, value)
```

---

## hou.Node

```python
n = hou.node("/obj/geo1")

# Identity / hierarchy
n.name(); n.path(); n.type().name()
n.parent(); n.children(); n.allSubChildren()
n.glob("box*")                       # pattern-match children

# Create / wire / delete
child = n.createNode("box", "mybox", run_init_scripts=True)
child.setInput(input_index, source_node, output_index=0)
child.inputs(); child.outputs()
n.layoutChildren()
child.destroy()

# Flags
child.setDisplayFlag(True)
child.setRenderFlag(True)
child.setBypassFlag(False)
child.setTemplateFlag(False)

# Parameters
n.parm("tx")                          # -> hou.Parm (single component)
n.parmTuple("t")                      # -> hou.ParmTuple (vector)
n.evalParm("tx")                      # quick evaluated value
n.parms()                             # all parms
n.setParms({"tx": 1, "ty": 2})        # set several at once

# Cooking / geometry
n.cook(force=False)
n.cookCount()                         # times cooked (profiling)
n.geometry()                          # SOP output geometry (hou.Geometry)
n.needsToCook()

# Misc
n.setUserData("key", "value"); n.userData("key")
n.setColor(hou.Color((1, 0, 0)))
n.setComment("note"); n.setGenericFlag(hou.nodeFlag.DisplayComment, True)
```

---

## hou.Parm and hou.ParmTuple

```python
p = hou.node("/obj/geo1/xform1").parm("tx")

p.eval()                              # evaluated value (respects expr/keys)
p.evalAsString()
p.set(5.0)                            # set raw value
p.setExpression("hou.frame()/24.0", language=hou.exprLanguage.Python)
p.expression()                        # current expression string
p.deleteAllKeyframes()
p.keyframes()                         # -> tuple of hou.Keyframe
p.setKeyframe(keyframe)
p.isAtDefault(); p.revertToDefaults()

pt = hou.node("/obj/geo1/xform1").parmTuple("t")
pt.set((1, 2, 3)); pt.eval()          # -> (1.0, 2.0, 3.0)

# Expression languages
hou.exprLanguage.Python
hou.exprLanguage.Hscript
```

---

## hou.Keyframe

```python
k = hou.Keyframe()
k.setFrame(24)                        # or k.setTime(seconds)
k.setValue(5.0)
k.setSlope(0.0); k.setInSlope(...); k.setOutSlope(...)   # tangents
k.setInExpression("bezier()")         # interpolation in / out
k.setOutExpression("bezier()")
k.setExpression("linear()")           # both sides
parm.setKeyframe(k)

# Common interpolation functions (set via in/out expression):
#   constant()  linear()  bezier()  ease()  easein()  easeout()
#   cubic()  spline()  qlinear()
```

---

## hou.Geometry (Python SOP / read geometry)

```python
geo = hou.pwd().geometry()            # inside a Python SOP
geo = hou.node("/obj/geo1/OUT").geometry()   # read another SOP's output

# Points & prims
geo.points()                          # tuple of hou.Point  (avoid for huge counts)
geo.prims()
geo.iterPoints()                      # iterator (lighter)
geo.createPoint()                     # -> hou.Point
geo.createPoints([(0,0,0), (1,0,0)])  # bulk allocate, returns points
geo.createPolygon()                   # -> hou.Polygon (then .addVertex(point))

# Attributes
attrib = geo.addAttrib(hou.attribType.Point, "Cd", (1.0, 1.0, 1.0))
geo.addAttrib(hou.attribType.Prim,   "name", "")
geo.addAttrib(hou.attribType.Vertex, "uv", (0.0, 0.0, 0.0))
geo.addAttrib(hou.attribType.Global, "frame", 0.0)   # detail attribute
geo.findPointAttrib("Cd"); geo.pointAttribs()

# Per-element value
pt.setPosition((x, y, z)); pt.position()
pt.setAttribValue("Cd", (1, 0, 0)); pt.attribValue("Cd")

# BULK access — far faster than Python loops
geo.pointFloatAttribValues("P")              # -> flat tuple len 3*npoints
geo.setPointFloatAttribValues("P", flat_list)
geo.pointIntAttribValues("id")
geo.primFloatAttribValues("area")

hou.attribType.Point | Prim | Vertex | Global
```

---

## hou.Vector3 / hou.Matrix4 (math types)

```python
v = hou.Vector3(1, 2, 3)
v.length(); v.normalized(); v.dot(other); v.cross(other)
v * 2; v + other

m = hou.hmath.buildTranslate((1, 2, 3))
m = hou.hmath.buildRotate((0, 90, 0))
m = hou.hmath.buildScale((2, 2, 2))
v * m                                  # transform a vector
hou.hmath.degToRad(deg); hou.hmath.fit(x, omin, omax, nmin, nmax)
```

---

## Rendering — ROP / Karma / Mantra

```python
rop = hou.node("/out/karma1")          # or /stage/usdrender_rop1, /out/mantra1
rop.render(
    frame_range=(1, 240, 1),           # (start, end, inc)
    verbose=True,
    output_progress=True,
)
rop.parm("picture").set("$HIP/render/beauty.$F4.exr")
rop.parm("trange").set(1)              # 1 = render frame range

# Render dependency network (respects upstream ROP deps)
rop.render(method=hou.renderMethod.RopByRop)
```

---

## Performance Monitor (profiling from Python)

```python
profile = hou.perfMon.startProfile("my pass")
# ... do work / cook nodes ...
profile.stop()
profile.exportAsCSV("$HIP/profile.csv")

# Quick timing
import time
t0 = time.time(); hou.node("/obj/geo1").cook(force=True)
print("cook:", time.time() - t0)
```

---

## Events & callbacks

```python
# Node event callback (e.g. in a python module on an HDA)
def onCreated(node, **kwargs):
    node.setColor(hou.Color((0.2, 0.6, 1.0)))

# Add a callback to a parameter (in an Edit Parameter Interface "Callback Script",
# set language to Python):
#   hou.pwd().parm("ty").set(hou.frame())

# Scene event callbacks
hou.hipFile.addEventCallback(lambda event: print(event))
```

---

## Common enums quick list

```python
hou.attribType.Point / Prim / Vertex / Global
hou.exprLanguage.Python / Hscript
hou.nodeFlag.Display / Render / Bypass / Template
hou.renderMethod.RopByRop / FrameByFrame
hou.severityType.Message / Warning / Error
```
