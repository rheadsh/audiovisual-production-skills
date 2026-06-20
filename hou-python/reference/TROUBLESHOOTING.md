# Houdini Python Troubleshooting

Common errors writing HOM Python and how to fix them.

---

## `AttributeError: 'NoneType' object has no attribute ...`

**Cause:** `hou.node(path)` returned `None` — the path is wrong or relative when you meant absolute.

```python
n = hou.node("geo1")            # relative to pwd — may be None
n = hou.node("/obj/geo1")       # absolute — robust
if n is None:
    raise hou.NodeError("node not found")
```

Inside expressions, relative paths are resolved from the node holding the expression. In `hython`/shelf, there's no "current node" unless you set one — use absolute paths.

---

## `hou.OperationFailed` / "Cannot create node of type X"

**Cause:** wrong node type name, or wrong network context (e.g. creating a SOP under `/obj` instead of inside a `geo`).

```python
# WRONG — box is a SOP, can't live directly in /obj
hou.node("/obj").createNode("box")

# RIGHT — make a geo container first
geo = hou.node("/obj").createNode("geo")
geo.createNode("box")
```

Check the exact operator type name from the node's tab menu or `node.type().name()`. Versioned types need the suffix: `"boolean::2.0"`.

---

## Parameter expression "fails to evaluate" / wrong value

**Cause 1 — language not set to Python.** A Python expression in an Hscript-language field won't work.

```python
parm.setExpression("hou.frame()", language=hou.exprLanguage.Python)
```

**Cause 2 — reading a parm object instead of its value.** Pass `.eval()` when you need a number.

```python
round(node.parm("tx"))            # TypeError
round(node.parm("tx").eval())     # works
```

**Cause 3 — `hou.ch()` path wrong.** `hou.ch` takes a *parameter* path, not a node path: `hou.ch("../ctrl/speed")`, not `hou.ch("../ctrl")`.

---

## Python SOP produces no geometry / "geometry is read-only"

**Cause:** you're not writing into `hou.pwd().geometry()`, or you're trying to edit input geometry directly.

```python
node = hou.pwd()
geo = node.geometry()             # THIS is writable inside a Python SOP
# build into geo...
```

If you set the Python SOP to pass input through, incoming geometry is editable; if it generates, start from the empty `geo`. Don't try to mutate `node.inputs()[0].geometry()` — copy what you need.

---

## Python SOP is extremely slow

**Cause:** per-element Python loop over points/prims.

**Fix:** use bulk attribute calls, or generate a Wrangle and compute in VEX.

```python
# Instead of looping geo.points():
P = geo.pointFloatAttribValues("P")
P = [v * 2 for v in P]
geo.setPointFloatAttribValues("P", P)
```

See BEST-PRACTICES.md → "Bulk attribute access".

---

## `hou.PermissionError` when setting a parm

**Cause:** the parm is locked, has an expression/keyframes, or the node is inside a locked HDA.

```python
parm.deleteAllKeyframes()         # remove keys before set()
parm.lock(False)                  # unlock if locked
parm.set(5)
```

To edit inside an HDA, allow editing of contents or work on an unlocked copy.

---

## `createPoint()` works in a Python SOP but errors in the shell

**Cause:** `hou.pwd()` has no geometry outside a SOP. Geometry creation methods need a real SOP's geometry. From the shell, target a Python SOP's geometry or build a detached `hou.Geometry()`:

```python
geo = hou.Geometry()              # standalone, detached
pt = geo.createPoint()
```

---

## Keyframes don't show / motion is wrong

- **Frame vs. seconds:** `key.setFrame(24)` vs `key.setTime(1.0)` — mixing them shifts timing. Pick one.
- **No interpolation set:** without an in/out expression, defaults may look linear. Set `bezier()` for ease.
- **Old keys remain:** call `parm.deleteAllKeyframes()` before re-keying or you'll layer onto stale channels.

---

## Render does nothing / "No output driver"

- **Wrong ROP path:** confirm with `hou.node(path)`; Karma in Solaris is usually `/stage/usdrender_rop1`, classic ROPs live in `/out`.
- **`trange` not set:** `rop.parm("trange").set(1)` to render a range; `0` renders only the current frame.
- **Output path unwritable:** `hou.expandString(rop.parm("picture").eval())` and check the directory exists / is writable.

---

## Render is correct but far too slow

Almost always cook time or sampling. See RENDERING.md → "Optimization checklist". Quick triage:

```python
# Find the heaviest-cooking nodes
for n in hou.node("/").allSubChildren():
    try:
        c = n.cookCount()
    except hou.OperationFailed:
        continue
    if c > 100:
        print(c, n.path())
```

Cache/freeze sims, lower ray depth, converge + denoise instead of brute samples.

---

## Changes don't take effect / stale results

**Cause:** Houdini cooks lazily; reading cached values, or display flag is on a different node.

```python
node.cook(force=True)             # force recook
node.setDisplayFlag(True)         # make sure you're viewing the right node
```

---

## `hou` not defined

**Cause:** outside expressions/`hython`, `hou` isn't auto-imported.

```python
import hou
```

---

## Unicode / path issues across OS

Use forward slashes and Houdini variables, expand explicitly:

```python
path = hou.expandString("$HIP/render/$OS.$F4.exr")
```

---

## Undo blowing up memory on big scripts

Wrap bulk programmatic edits so they don't each create undo entries:

```python
with hou.undos.disabler():
    for i in range(10000):
        ...
```

(Only when you genuinely don't need undo — it removes the ability to revert.)
