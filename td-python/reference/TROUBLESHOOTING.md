# TouchDesigner Python Troubleshooting

Common errors, their causes, and fixes.

---

## `td.Par doesn't define __round__ method` (or similar)

**Cause**: Passing a `par` object directly to a Python function that expects a raw number.

**Fix**: Use `.eval()` to extract the value:

```python
# ❌ Fails
round(op('slider1').par.value0, 2)

# ✅ Works
round(op('slider1').par.value0.eval(), 2)

# ❌ Fails
math.sqrt(op('geo1').par.tx)

# ✅ Works
math.sqrt(op('geo1').par.tx.eval())
```

**Rule of thumb**: If you're passing a `par` into any standard Python function, add `.eval()`.

---

## Expression parameter turns red / shows error

**Cause**: Syntax error, or referencing something that doesn't exist yet.

**Fix steps**:
1. Hover over the red parameter — the tooltip shows the error message.
2. Click the red X on the node for full details.
3. Open the Textport (alt-T) and test your expression there.

```python
# Test in Textport before putting in a parameter:
op('noise1')['chan1']   # does this return a number?
```

---

## Module recompiles constantly / unexpected slowdown

**Cause**: Accessing a TD object (CHOP channel, parameter) at the **root level** of a module (Text DAT). TD re-cooks the module every time that object changes.

```python
# ❌ BAD — recompiles every frame
value = op('constant1').par.value0

# ✅ GOOD — only evaluates inside a function
def getValue():
    return op('constant1').par.value0.eval()
```

---

## `NoneType object has no attribute 'par'`

**Cause**: `op()` returned `None` because the path is wrong or the operator doesn't exist.

**Fix**: Always check before accessing:

```python
# ❌ Crashes if 'geo1' doesn't exist
op('geo1').par.tx = 5

# ✅ Safe
node = op('geo1')
if node:
    node.par.tx = 5
else:
    debug('geo1 not found — check path')
```

Also verify:
- The path is correct (relative vs absolute)
- You're running this code from the right location in the network

---

## Callback isn't firing

**Cause**: The Execute DAT isn't configured to watch the right operator or event.

**Checklist**:
- [ ] Is the DAT's `Active` toggle enabled?
- [ ] Is the `OP` parameter pointing to the right operator?
- [ ] Is the specific callback (e.g. `Value Change`, `Off to On`) enabled in the DAT parameters?
- [ ] For `chopexec`, is the CHOP actually changing? Check its viewer.
- [ ] For `parexec`, is the `Parameters` field matching the correct parameter name (e.g. `value0`, not `Value`)?

---

## `import` can't find my module

**Cause**: The module DAT isn't in the search path TouchDesigner uses.

TouchDesigner `import` searches in this order:
1. Same component
2. `local/modules` inside the current component
3. `local/modules` in each parent, up to root
4. `/sys` internal modules
5. Disk (standard Python path)

**Fix**:
```python
# If import fails, use mod with an explicit path instead:
result = mod('/project1/myUtils').myFunction()

# Or use the .module member:
result = op('/project1/myUtils').module.myFunction()
```

Also check: are there any DATs named the same as a standard Python module in your component? They'll shadow the standard library.

---

## Extension not accessible

**Cause**: Extension isn't promoted, or component name/path is wrong.

```python
# Only uppercase attributes/methods are accessible from outside:
op('myComp').MyMethod()   # ✅ works (uppercase M)
op('myComp').myHelper()   # ❌ AttributeError (lowercase m = private)

# From inside the component, ext works for everything:
ext.MyExt.myHelper()      # ✅ works from inside
```

Also check:
- Is the extension DAT referenced correctly in the component's Extension parameter?
- Has the component been re-cooked after editing the extension?
- Try RMB on component → Reload Extension.

---

## `debug()` output not appearing

**Cause**: Textport isn't open or is filtering.

**Fix**: Open the Textport with `alt-T` or `Dialogs → Textport`. Make sure the filter is set to show all output.

Use `debug()` (not `print()`) — `debug()` shows the source path, making it easier to locate where a message came from.

---

## Script TOP producing black output

**Cause**: numpy array not passed correctly, or wrong dtype/shape.

```python
# ✅ Correct shape for a Script TOP
import numpy as np
w, h = scriptOp.width, scriptOp.height
img = np.zeros((h, w, 4), dtype=np.float32)  # (height, width, RGBA)
img[:, :, 3] = 1.0  # alpha must be 1 to be visible
scriptOp.copyNumpyArray(img)
```

Check:
- Shape is `(height, width, 4)` — height first!
- dtype is `float32`
- Alpha channel is not zero

---

## Python threads can't access TD objects

**Cause**: TouchDesigner's Python objects are not thread-safe and can't be accessed from threads.

**Fix**: As of TD 2023.31500+, use the built-in Thread Manager palette component. For older builds, schedule work back to the main thread using `op.td.run()` or Execute DATs.

```python
# ❌ Will crash or produce garbage
import threading
def worker():
    op('geo1').par.tx = 5   # unsafe!
t = threading.Thread(target=worker)
t.start()

# ✅ Use Thread Manager (palette) for safe async work
# Or: use Execute DAT onFrameStart to poll results from a queue
```

---

## Quick Diagnostic Checklist

When a script isn't working:

- [ ] Is there an error in the Textport? (alt-T)
- [ ] Does hovering over the red parameter show an error message?
- [ ] Are you using `debug()` to trace execution?
- [ ] Are all `op()` paths returning the right operator? (test in Textport)
- [ ] Are you calling `.eval()` when passing `par` values to Python functions?
- [ ] Is your module-level code accessing TD objects? (wrap in functions)
- [ ] For callbacks — is the Active toggle on, and the correct events enabled?
- [ ] For extensions — are public members capitalized?
