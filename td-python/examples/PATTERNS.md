# Common TouchDesigner Python Patterns

Ready-to-use templates. Copy and adapt for your needs.

---

## Parameter Expressions

One-liners that live directly in a parameter field. Auto-evaluate every cook.

```python
# Time
absTime.frame              # current frame
absTime.seconds            # seconds elapsed

# Self-reference
me.name                    # name of this operator
me.par.tx                  # value of my own tx parameter
me.width                   # pixel width (TOPs)
me.height                  # pixel height (TOPs)

# Other operators
op('noise1')['chan1']               # CHOP channel by name
op('noise1')[0]                     # CHOP channel by index
op('rectangle1').par.sizex          # another operator's parameter
op('rectangle1').par.sizex.eval()   # as a raw number (use when .eval() is needed)

# Navigation
parent().name              # name of the parent component
parent(2).name             # grandparent name
parent.MyComp.par.Speed    # Parent Shortcut lookup
op.GlobalWidget.par.Value  # Global OP Shortcut lookup

# Math helpers (math module auto-imported)
math.sin(absTime.seconds)
math.floor(me.par.value0.eval())
```

---

## Callbacks — Parameter Execute DAT

Fires when a watched parameter changes value.

```python
# parexec DAT — watches op('mySlider'), parameter 'value0'
def onValueChange(par, prev):
    debug(f'{par.name} changed: {prev} → {par.eval()}')
    op('target').par.tx = par.eval() * 100

def onPulse(par):
    debug('Button pressed:', par.name)
```

**Setup**: Set `parexec` OP parameter to your watched operator; set Parameters field to the parameter name (e.g. `value0`).

---

## Callbacks — CHOP Execute DAT

Fires when a CHOP channel value changes.

```python
# chopexec DAT
def onValueChange(channel, sampleIndex, val, prev):
    debug(f'{channel.name}[{sampleIndex}] = {val}')
    op('geo1').par.tx = val

def onOffToOn(channel, sampleIndex, val, prev):
    debug('Triggered on:', channel.name)
    op('audiodevin1').par.record.pulse()

def onOnToOff(channel, sampleIndex, val, prev):
    debug('Released:', channel.name)
```

**Setup**: Set `chopexec` OP parameter to your CHOP; enable the specific callbacks you need.

---

## Callbacks — Panel Execute DAT

Fires on UI interactions (buttons, sliders inside a Panel Component).

```python
# panelexec DAT
def onOffToOn(panelValue):
    # Button pressed
    op('../audioout1').par.play.pulse()

def onValueChange(panelValue):
    debug('Panel value:', panelValue)

def onSelect(info):
    debug('Selected:', info['select'])
```

---

## Callbacks — Execute DAT

System-level events: startup, file save, operator creation.

```python
# execute DAT
def onStart():
    debug('Project started')
    op('/project1/init').run()

def onFileLoad():
    debug('File loaded:', project.name)

def onFrameStart(frame):
    # Runs every frame — keep this FAST
    if frame % 60 == 0:
        debug('One second elapsed')
```

---

## Script CHOP

Use Python to generate CHOP channels.

```python
# scriptCHOP callbacks DAT
def onCook(scriptOp):
    scriptOp.clear()

    # Create a channel with 100 samples
    c = scriptOp.appendChan('wave')
    for i in range(scriptOp.numSamples):
        t = i / scriptOp.numSamples
        c[i] = math.sin(t * math.pi * 2)
```

---

## Script TOP

Use Python to generate or modify image data (pixel-level access via numpy).

```python
# scriptTOP callbacks DAT
def onSetupParameters(scriptOp):
    page = scriptOp.appendCustomPage('Custom')
    page.appendFloat('Speed', label='Speed')

def onCook(scriptOp):
    scriptOp.copyNumpyArray(createImage(scriptOp))

def createImage(scriptOp):
    import numpy as np
    w, h = scriptOp.width, scriptOp.height
    img = np.zeros((h, w, 4), dtype=np.float32)

    for y in range(h):
        for x in range(w):
            img[y, x] = [x/w, y/h, 0.5, 1.0]

    return img
```

---

## Script SOP

Use Python to create geometry.

```python
# scriptSOP callbacks DAT
def onCook(scriptOp):
    scriptOp.clear()

    # Create a grid of points
    for x in range(10):
        for y in range(10):
            p = scriptOp.appendPoint()
            p.P = (x * 0.1, y * 0.1, 0)

    # Create polygons connecting those points
    poly = scriptOp.appendPoly(4, closed=True)
    poly[0].point = scriptOp.points[0]
    poly[1].point = scriptOp.points[1]
    poly[2].point = scriptOp.points[11]
    poly[3].point = scriptOp.points[10]
```

---

## Script DAT

Use Python to generate table data.

```python
# scriptDAT callbacks DAT
def onCook(scriptOp):
    scriptOp.clear()

    # Build a table from scratch
    scriptOp.appendRow(['name', 'value', 'active'])
    scriptOp.appendRow(['speed',  1.5, True])
    scriptOp.appendRow(['offset', 0.3, True])
    scriptOp.appendRow(['scale',  2.0, False])
```

---

## Extensions

A Python class that adds behavior and state to a custom component.

```python
# MyCompExt DAT (inside your component)
class MyCompExt:
    def __init__(self, ownerComp):
        self.ownerComp = ownerComp
        self.count = 0       # private (lowercase = not promoted)
        self.State = 'idle'  # public (uppercase = promoted to component)

    def Reset(self):         # public method (uppercase)
        self.count = 0
        self.State = 'idle'

    def Increment(self, amount=1):  # public method
        self.count += amount
        self.State = 'running'
        return self.count

    def _helper(self):       # private helper
        pass
```

**Accessing the extension**:

```python
# From inside the component (any depth):
ext.MyCompExt.Reset()
ext.MyCompExt.State

# From outside the component (promoted members only):
op('myComp').Reset()
op('myComp').State
op('myComp').Increment(5)
```

**Setup**: RMB on component → Customize Component → Extension Code → Add name → Edit DAT.

---

## DATs as Modules

Reuse Python code across your project.

```python
# utils DAT — define helpers here
def remap(value, inMin, inMax, outMin, outMax):
    return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin)

def clamp(value, lo, hi):
    return max(lo, min(hi, value))
```

```python
# Anywhere in your project — three ways to import:

# 1. import statement (module must be in same component or local/modules)
import utils
result = utils.remap(0.5, 0, 1, -100, 100)

# 2. mod object (no import needed, works in expressions too)
result = mod.utils.remap(0.5, 0, 1, -100, 100)

# 3. mod with path (absolute or relative)
result = mod('/project1/utils').remap(0.5, 0, 1, -100, 100)

# 4. .module member (explicit, no search)
result = op('/project1/utils').module.remap(0.5, 0, 1, -100, 100)
```

---

## Setting Parameters in Scripts

```python
# Set value directly
op('geo1').par.tx = 5.0

# Pulse a button/trigger parameter
op('moviein1').par.reload.pulse()

# Set string parameter
op('text1').par.text = 'Hello'

# Set expression on a parameter
op('geo1').par.tx.expr = 'absTime.seconds'

# Return to constant mode
op('geo1').par.tx.mode = ParMode.CONSTANT
op('geo1').par.tx.val = 0
```

---

## Reading DAT Table Data

```python
dat = op('table1')

# By row/col index
val = dat[0, 0]          # top-left cell
val = dat[1, 2]          # row 1, col 2

# By cell name (when headers exist)
val = dat['speed', 'value']

# Iterate rows
for row in dat.rows():
    debug([cell.val for cell in row])

# Number of rows/cols
nRows = dat.numRows
nCols = dat.numCols
```
