# TouchDesigner Python API Reference

Core objects, classes, and methods available in all TD Python contexts.

---

## Global Objects (No Import Needed)

### `me`
The operator this script belongs to.

```python
me.name           # operator name (str)
me.path           # full path, e.g. '/project1/geo1'
me.type           # operator type string, e.g. 'geo'
me.digits         # trailing number, e.g. 1 for 'geo1'
me.width          # pixel width (TOPs only)
me.height         # pixel height (TOPs only)
me.inputs         # list of connected input operators
me.outputs        # list of connected output operators
me.par            # access parameters (see Par section)
me.bypass         # bool — is op bypassed?
me.cookTime       # seconds spent cooking last frame
```

### `op(path)`
Find an operator by path. Returns `None` if not found.

```python
op('noise1')               # relative path (sibling)
op('../geo1')              # relative, one level up
op('./inner1')             # relative, inside me
op('/project1/audio')      # absolute path from root
op.MyGlobal                # Global OP Shortcut
```

### `parent(n=1)`
Navigate upward in the hierarchy.

```python
parent()           # immediate parent component
parent(2)          # grandparent
parent.MyShortcut  # search upward for Parent Shortcut
```

### `absTime`
Project-wide time object.

```python
absTime.frame         # current frame (int)
absTime.frames        # alias for frame
absTime.seconds       # elapsed seconds (float)
absTime.rate          # project FPS
absTime.stepFrame     # True on step frames
```

### `ext`
Access extensions on this component or parents.

```python
ext.MyExt           # finds MyExt extension searching upward
ext.MyExt.MyMethod()
ext.MyExt.MyAttribute
```

### `mod`
Access DATs as modules (no import needed).

```python
mod.myDat                       # DAT named 'myDat' (relative search)
mod.myDat.myFunction()
mod('myDat').myFunction()       # same, string form
mod('/project1/utils').helper() # absolute path
```

### `project`
Project-level information.

```python
project.name          # name of the .toe file
project.folder        # directory containing the project
project.saveVersion   # last save build version
```

---

## Parameters (`par`)

```python
op('geo1').par.tx            # parameter object
op('geo1').par.tx.eval()     # raw Python value (always use for math)
op('geo1').par.tx.val        # value in constant mode
op('geo1').par.tx.expr       # get/set expression string
op('geo1').par.tx.mode       # ParMode.CONSTANT / EXPRESSION / EXPORT / BIND

# Set value
op('geo1').par.tx = 5.0
op('geo1').par.tx.val = 5.0

# Set expression
op('geo1').par.tx.expr = 'absTime.seconds * 10'
op('geo1').par.tx.mode = ParMode.EXPRESSION

# Pulse trigger parameter
op('moviein1').par.reload.pulse()

# String parameter
op('text1').par.text = 'Hello'
op('text1').par.text.val = 'Hello'

# Iterate all parameters
for p in op('geo1').pars():
    debug(p.name, p.eval())
```

---

## CHOP Channels

```python
chop = op('noise1')

chop['chan1']        # channel by name
chop[0]             # channel by index
chop.numChans       # number of channels
chop.numSamples     # samples per channel

# Multi-sample access
chan = chop['chan1']
chan[0]              # sample 0
chan[10]             # sample 10

# Iterate
for c in chop.chans():
    debug(c.name, c[0])
```

---

## DAT Tables

```python
dat = op('table1')

dat.numRows         # row count
dat.numCols         # column count
dat[0, 0]           # cell object (row 0, col 0)
dat[0, 0].val       # string value of cell
dat['key', 'value'] # look up by header names

# Modify (Script DAT only, inside onCook)
dat.clear()
dat.appendRow(['col1', 'col2'])
dat.appendRow(['a', 'b'])
dat.appendCol(['x', '1', '2'])
dat[1, 0] = 'newvalue'

# Iterate
for row in dat.rows():
    debug([cell.val for cell in row])
for col in dat.cols():
    debug([cell.val for cell in col])
```

---

## TOPs (Texture Operators)

```python
top = op('moviefilein1')
top.width           # pixel width
top.height          # pixel height
top.numColorBuffers # number of color buffers

# Script TOP — numpy pixel access
def onCook(scriptOp):
    import numpy as np
    arr = scriptOp.inputs[0].numpyArray()  # read pixels from input
    # arr shape: (height, width, 4) float32, RGBA 0-1
    arr[:, :, 0] = 1.0  # set red channel to 1
    scriptOp.copyNumpyArray(arr)
```

---

## SOPs (Surface Operators)

```python
sop = op('sphere1')
sop.numPoints      # point count
sop.numPrims       # primitive count

# Script SOP — build geometry
def onCook(scriptOp):
    scriptOp.clear()
    p = scriptOp.appendPoint()
    p.P = (0, 0, 0)           # position
    p.N = (0, 1, 0)           # normal (if applicable)

    poly = scriptOp.appendPoly(3, closed=True)
    poly[0].point = scriptOp.points[0]
```

---

## Network Navigation

```python
comp = op('/project1')
comp.children              # list of direct children
comp.ops('geo*')           # children matching glob
comp.findChildren(type=opType.GEO, maxDepth=3)  # recursive search
comp.create(opType.GEO, 'myGeo')  # create a new operator
comp.copy(op('template'))         # copy an operator into this comp

op('geo1').destroy()       # delete an operator
op('geo1').bypass = True   # bypass it
op('geo1').viewer = True   # open viewer

# Wiring
op('noise1').outputConnectors[0].connect(op('chop2'))
op('geo1').inputConnectors[0].disconnect()
```

---

## Useful Built-in Modules (Auto-Imported in `td`)

```python
# math — standard Python math
math.sin(x), math.cos(x), math.pi, math.floor(x)

# These need explicit import in DATs:
import random
random.random()         # 0.0 – 1.0
random.randint(0, 10)
random.choice(['a', 'b'])

import json
data = json.loads(op('jsonDat').text)
text = json.dumps({'key': 'val'}, indent=2)

import os
os.path.exists('/some/path')
os.listdir('/some/folder')

import sys
sys.path.append('/my/packages')
```

---

## Debug and Error Handling

```python
# Always use debug() instead of print in TD
debug('Hello')                    # shows source location
debug('value:', op('x').par.tx)   # multiple args
debug(f'Frame: {absTime.frame}')  # f-string

# Try/except to prevent network errors
try:
    result = op('data1')['missing', 0].val
except Exception as e:
    debug(f'Error accessing data: {e}')
    result = 0

# Check before accessing
node = op('myOp')
if node:
    debug(node.par.tx.eval())
else:
    debug('operator not found')
```

---

## Run DAT Scripts Manually

```python
# Run a script DAT as a one-shot
op('myScript').run()

# Run with arguments
op('myScript').run('arg1', 42)   # accessible as args[] inside the DAT

# Delay a run
op('myScript').run(delayFrames=10)
op('myScript').run(delayMilliSeconds=500)
```
