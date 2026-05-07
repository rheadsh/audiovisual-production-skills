# TouchDesigner Python Best Practices

Organization, performance, and style guidelines.

---

## Code Organization

### Match script context to responsibility

| Context | Use for |
|---|---|
| Parameter expression | Reading a single value that auto-updates |
| Callback DAT | Reacting to an event (change, trigger, UI) |
| Script OP | Generating operator data (channels, image, geometry, table) |
| Extension | Adding stateful behavior and API to a component |
| Module DAT | Shared utilities and pure Python helpers |
| Execute DAT | System events (startup, save, frame) |

### Namespace by context, not by file

Don't put startup code, UI callbacks, and data generation all in one DAT. Each DAT should have a single job.

---

## Extensions: The Right Way to Build Components

Use extensions when you want a component to have:
- **State** (data that persists across frames)
- **Public API** (methods callable from outside)
- **Separation of logic from network wiring**

```python
class MyComp:
    def __init__(self, ownerComp):
        self.ownerComp = ownerComp
        # State goes here
        self._cache = {}
        self.Status = 'idle'   # uppercase = public

    # Public methods (uppercase = accessible outside the component)
    def Process(self, data):
        result = self._transform(data)
        self.Status = 'complete'
        return result

    # Private helpers (lowercase = internal only)
    def _transform(self, data):
        return [x * 2 for x in data]
```

**Rule**: capitalize everything you want accessible from outside. Keep internals lowercase.

---

## Module Pattern for Reusable Code

When the same logic appears in multiple DATs, extract it into a module DAT.

```python
# utils DAT — pure Python, no TD dependencies at root level

def remap(value, inMin, inMax, outMin, outMax):
    """Remap value from one range to another."""
    if inMax == inMin:
        return outMin
    t = (value - inMin) / (inMax - inMin)
    return outMin + t * (outMax - outMin)

def lerp(a, b, t):
    return a + (b - a) * t

def clamp(value, lo, hi):
    return max(lo, min(hi, value))

def easeInOut(t):
    return t * t * (3.0 - 2.0 * t)
```

Access anywhere via `mod.utils.remap(x, 0, 1, -100, 100)`.

---

## Never Access TD Objects at Module Root

```python
# ❌ BAD — runs every time the module is imported or the channel changes
speed = op('chop1')['speed']

def update():
    return speed * 2   # stale reference problem!


# ✅ GOOD — reads fresh every call
def update():
    speed = op('chop1')['speed']
    return speed * 2
```

---

## Always Use `debug()` for Logging

```python
# ❌ print() — no source info, harder to trace
print('value:', val)

# ✅ debug() — shows exactly which DAT and line this came from
debug('value:', val)
debug(f'Frame {absTime.frame}: speed={op("chop1")["speed"]:.3f}')
```

Structure debug output so it's filterable:

```python
# Add a prefix to group related messages
debug('[VideoPlayer] loaded:', path)
debug('[Seq] step:', stepIndex)
```

---

## Validate Operator References

```python
# ❌ Crashes if the op doesn't exist
op('missingOp').par.tx = 5

# ✅ Safe
def setParam(opPath, paramName, value):
    node = op(opPath)
    if not node:
        debug(f'[WARNING] op not found: {opPath}')
        return False
    setattr(node.par, paramName, value)
    return True
```

---

## `.eval()` Rule

Any time you pass a `par` object to a Python function (not a TD function), call `.eval()` first.

```python
# TD functions accept par objects directly:
op('geo1').par.tx = op('slider1').par.value0     # ✅ fine

# Python functions need the raw value:
round(op('slider1').par.value0.eval(), 2)        # ✅
math.sin(op('angle').par.value0.eval())          # ✅
str(op('n').par.name.eval())                     # ✅
```

---

## Performance in Frame-Rate Code

Code in `Execute DAT → onFrameStart` and `Script CHOP → onCook` runs every frame. Keep it fast.

```python
# ❌ SLOW — creates new list every frame
def onFrameStart(frame):
    values = [op(f'chop{i}')[0] for i in range(100)]

# ✅ FAST — cache references at startup, only read values
_chops = []

def onStart():
    global _chops
    _chops = [op(f'chop{i}') for i in range(100)]

def onFrameStart(frame):
    values = [c[0] for c in _chops]
```

Also: avoid creating Python objects, allocating memory, or doing heavy computation per-frame. Delegate expensive work to CHOPs, SOPs, and TOPs where possible — they run on the GPU or cook lazily.

---

## Commenting Style

Explain *why*, not *what*:

```python
# ❌ Obvious — what, not why
x = x * 2   # multiply by 2

# ✅ Useful — tells reader the purpose
x = x * 2   # remap 0–0.5 to 0–1 range for LED brightness curve
```

Document parameters and expected ranges in Script OPs:

```python
def onSetupParameters(scriptOp):
    page = scriptOp.appendCustomPage('Settings')
    # Frequency: 0.1 = very slow, 10 = very fast
    page.appendFloat('Freq', label='Frequency').default = 1.0
    # Amplitude: scale of displacement in world units
    page.appendFloat('Amp',  label='Amplitude').default = 0.1
```

---

## Testing Checklist

Before finalizing a script:

- [ ] Does it run cleanly with no Textport errors?
- [ ] Have you tested with edge cases (zero, negative, None)?
- [ ] Are all operator references validated before access?
- [ ] Are TD objects in functions, not at module root?
- [ ] Is frame-rate code (onFrameStart, onCook) as lean as possible?
- [ ] Are all public extension methods capitalized correctly?
- [ ] Have debug() calls been reviewed — too noisy? too sparse?
- [ ] Does the code work after a project reload (not just a cook)?
