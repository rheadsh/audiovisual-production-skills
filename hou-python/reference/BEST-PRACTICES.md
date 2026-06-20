# Houdini Python Best Practices

Performance, organization, and style for HOM Python.

---

## Performance

### Bulk attribute access, always

The single biggest win in a Python SOP. Python loops over `geo.points()` are slow because each `.position()` / `.setAttribValue()` crosses the C++ boundary per element.

```python
# SLOW — per-element, crosses into C++ N times
for pt in geo.points():
    p = pt.position()
    pt.setPosition(p * 1.5)

# FAST — two calls total, regardless of point count
P = geo.pointFloatAttribValues("P")
P = [v * 1.5 for v in P]
geo.setPointFloatAttribValues("P", P)
```

### Push heavy per-point math to VEX

Python is single-threaded and runs on the main thread. For real per-point computation at scale, generate a Wrangle from Python and let VEX parallelize across cores. Use Python to *orchestrate*, VEX to *crunch*. (See the `hou-vex` skill.)

### Don't trigger cooks in loops

Each `.eval()` on a dirty parm, or `.set()` that dirties downstream, can cause a cook. Batch your edits, then read/render once.

```python
# Batch parm changes
node.setParms({"tx": 1, "ty": 2, "tz": 3})   # one call

# Disable undo for big programmatic edits
with hou.undos.disabler():
    for i in range(5000):
        ...
```

### Cache node lookups

`hou.node("/long/path")` resolves a string every call. In hot loops or per-frame scripts, resolve once:

```python
n = hou.node("/obj/geo1/xform1")        # once
for f in range(1, 241):
    hou.setFrame(f)
    do_something(n)                       # reuse handle
```

### Cache heavy geometry / sims to disk

Anything that re-solves or re-cooks expensively should be written to `.bgeo.sc` / `.vdb` / USD and read back. Freeze finished work with a File SOP.

### Profile, don't guess

```python
n.cookCount()                            # how often a node cooked
hou.perfMon.startProfile("name")         # then .stop() and .exportAsCSV(...)
```

---

## Organization

### Where code lives

| Context | Use for | Notes |
| --- | --- | --- |
| Parameter expression | small derived values | language must be Python; keep cheap |
| Python SOP | generate/modify geometry | `hou.pwd().geometry()` |
| Shelf tool / Source Editor | one-off scene actions | interactive |
| `hython` script | headless automation, farm | `import hou` |
| HDA Python module | reusable tool logic | callable as `hou.phm()` |
| Event callbacks | react to parm/scene events | keep side-effect-free where possible |

### Reusable logic in modules

Put shared functions in a Python module (a Python SOP-less module, a `scripts/python/` file on the path, or an HDA's Python module section) and import it, rather than copy-pasting into many parm fields.

```python
# In an HDA's Python Module:
def setup(node):
    node.parm("tx").set(0)

# Called from a callback as:
hou.phm().setup(hou.pwd())
```

### Use `evalParm` / `setParms` over many single calls

```python
node.evalParm("height")                   # quick read
node.setParms({"a": 1, "b": 2})           # grouped write
```

### Guard node lookups

`hou.node()` returns `None` for missing paths. Check before use to avoid `AttributeError`.

```python
n = hou.node("/obj/geo1")
if n is None:
    raise hou.NodeError("expected /obj/geo1")
```

---

## Style

- **Be explicit about expression language.** Always pass `language=hou.exprLanguage.Python` to `setExpression`; don't rely on the default.
- **Use `$HIP`, `$F`, `$OS`** in paths via `hou.expandString` so scenes stay portable.
- **Prefer `parmTuple` for vectors** — `parmTuple("t").set((x,y,z))` over three `parm` calls.
- **Name nodes you create** — `createNode("box", "carve_block")` makes networks readable and scripts robust to renames.
- **Lay out networks** — call `parent.layoutChildren()` after building so the result is navigable.
- **Fail loudly** — raise `hou.NodeError` / `hou.OperationFailed` with a clear message instead of silently continuing.
- **Keep expressions one-liners** — if it needs branching or loops, it belongs in a Python SOP or module, not a parm field.

---

## Python vs. VEX — choosing

| Task | Python | VEX |
| --- | --- | --- |
| Build/wire networks | ✅ | ✗ |
| Set parms, keyframes, render | ✅ | ✗ |
| Per-point math at scale | ✗ (slow) | ✅ (parallel) |
| Small geometry generation | ✅ | ✅ |
| Orchestration / pipeline | ✅ | ✗ |
| Shaders | ✗ | ✅ |

Default: **Python orchestrates, VEX computes.**

---

## Safety

- Wrap large edits in `hou.undos.disabler()` *only* when you don't need undo — otherwise users can't revert.
- `hou.hipFile.save()` before risky batch operations.
- In `hython`, pass `ignore_load_warnings=True` to `hou.hipFile.load` for unattended runs, but log what you skipped.
