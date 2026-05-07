# Complete TouchDesigner Python Examples

Full, real-world scripts demonstrating best practices.

---

## 1. Generative Sequencer (Script CHOP + Parameter Execute)

A step sequencer that drives parameters from a Python-built pattern.

```python
# sequencer DAT — Script CHOP
# Reads a pattern from a Table DAT and generates trigger pulses

def onCook(scriptOp):
    scriptOp.clear()

    stepDat = op('../steps')       # Table DAT with one row of 0/1 values
    numSteps = stepDat.numCols
    beat = op('../beat1')['beat']  # Beat CHOP driving step index

    stepIndex = int(beat * numSteps) % numSteps

    # One trigger channel per step
    for i in range(numSteps):
        c = scriptOp.appendChan(f'step{i}')
        c[0] = 1.0 if (i == stepIndex and stepDat[0, i].val == '1') else 0.0
```

**Setup**:
- Script CHOP with 1 sample
- Table DAT named `steps` with one row of binary values (0 or 1)
- Beat CHOP connected via CHOP reference in the Script CHOP

---

## 2. Responsive Component (Extension)

A self-contained component with state, parameters, and external API.

```python
# VideoPlayerExt DAT (inside a Container COMP)

class VideoPlayerExt:
    def __init__(self, ownerComp):
        self.ownerComp = ownerComp
        self.playlist = []
        self.currentIndex = 0
        self.IsPlaying = False   # promoted: op('videoPlayer').IsPlaying

    # -- Public API --

    def LoadPlaylist(self, filePaths):
        """Load a list of video file paths."""
        self.playlist = list(filePaths)
        self.currentIndex = 0
        self._applyCurrentFile()

    def Play(self):
        """Start playback."""
        self.IsPlaying = True
        op('../moviefilein1').par.play = True

    def Pause(self):
        """Pause playback."""
        self.IsPlaying = False
        op('../moviefilein1').par.play = False

    def Next(self):
        """Advance to next clip."""
        if not self.playlist:
            return
        self.currentIndex = (self.currentIndex + 1) % len(self.playlist)
        self._applyCurrentFile()

    def Previous(self):
        """Go back to previous clip."""
        if not self.playlist:
            return
        self.currentIndex = (self.currentIndex - 1) % len(self.playlist)
        self._applyCurrentFile()

    # -- Private helpers --

    def _applyCurrentFile(self):
        if not self.playlist:
            return
        path = self.playlist[self.currentIndex]
        op('../moviefilein1').par.file = path
        debug(f'VideoPlayer: loading {path}')
```

**Accessing from outside the component**:

```python
vp = op('videoPlayer')
vp.LoadPlaylist(['/media/clip1.mov', '/media/clip2.mov'])
vp.Play()
vp.Next()
debug(vp.IsPlaying)
```

---

## 3. OSC-Driven Parameter Map (CHOP Execute + Module)

Map incoming OSC data to operator parameters using a lookup table.

```python
# mapping DAT (Text DAT, used as a module)
# Format: each function maps an OSC address to a TD parameter

OSC_MAP = {
    '/position/x':  ('geo1', 'tx'),
    '/position/y':  ('geo1', 'ty'),
    '/color/hue':   ('constantTOP1', 'colorr'),
    '/scale':       ('geo1', 'sx'),
}

def applyOSC(address, value):
    if address not in OSC_MAP:
        debug(f'Unmapped OSC: {address}')
        return
    opName, paramName = OSC_MAP[address]
    target = op(f'/project1/{opName}')
    if target:
        setattr(target.par, paramName, value)
    else:
        debug(f'Op not found: {opName}')
```

```python
# oscin_callbacks DAT (attached to OSC In CHOP)
def onReceiveOSC(dat, rowIndex, message, bytes, timeStamp, address, args, peer):
    value = args[0] if args else 0
    mod.mapping.applyOSC(address, float(value))
```

---

## 4. Data Dashboard (Script DAT + Table DAT)

Collect stats from multiple operators and display as a formatted table.

```python
# stats DAT — Script DAT

def onCook(scriptOp):
    scriptOp.clear()
    scriptOp.appendRow(['Operator', 'Cook Time (ms)', 'Bypassed', 'Inputs'])

    targets = [
        op('/project1/render1'),
        op('/project1/composite1'),
        op('/project1/blur1'),
        op('/project1/out1'),
    ]

    for node in targets:
        if node is None:
            continue
        scriptOp.appendRow([
            node.name,
            f'{node.cookTime * 1000:.2f}',
            str(node.bypass),
            str(len(node.inputs)),
        ])
```

**Usage**: Place a Script DAT in your network and view it in a Table TOP or Text TOP via `op('stats')[row, col].val`.

---

## 5. Generative Geometry (Script SOP)

Build procedural geometry with animated noise displacement.

```python
# noiseMeshCallbacks DAT — Script SOP

def onSetupParameters(scriptOp):
    page = scriptOp.appendCustomPage('Mesh')
    page.appendInt('Rows',    label='Rows')    .default = 20
    page.appendInt('Cols',    label='Columns') .default = 20
    page.appendFloat('Scale', label='Scale')   .default = 0.05

def onCook(scriptOp):
    scriptOp.clear()

    rows  = int(scriptOp.par.Rows.eval())
    cols  = int(scriptOp.par.Cols.eval())
    scale = scriptOp.par.Scale.eval()
    t     = absTime.seconds

    # Build grid points
    for r in range(rows + 1):
        for c in range(cols + 1):
            x = c / cols - 0.5
            y = r / rows - 0.5
            # Noise displacement on Z
            import noise  # TD ships with the 'noise' module
            z = noise.pnoise2(x * 4 + t, y * 4 + t) * scale
            p = scriptOp.appendPoint()
            p.P = (x, y, z)

    # Build quads
    for r in range(rows):
        for c in range(cols):
            i0 = r * (cols + 1) + c
            i1 = i0 + 1
            i2 = i0 + (cols + 1) + 1
            i3 = i0 + (cols + 1)
            poly = scriptOp.appendPoly(4, closed=True)
            poly[0].point = scriptOp.points[i0]
            poly[1].point = scriptOp.points[i1]
            poly[2].point = scriptOp.points[i2]
            poly[3].point = scriptOp.points[i3]
```

---

## 6. Startup Initializer (Execute DAT)

Run setup code when the project loads — connect devices, set defaults, load config.

```python
# execute DAT (system Execute DAT, onStart enabled)

def onStart():
    debug('=== Project Initializing ===')
    _loadConfig()
    _connectDevices()
    _setDefaults()
    debug('=== Init complete ===')

def _loadConfig():
    cfgDat = op('/project1/config')
    if not cfgDat:
        debug('WARNING: config DAT not found')
        return
    # Read values from a table DAT
    op('/project1/settings').par.BPM = float(cfgDat['bpm', 1].val)
    op('/project1/settings').par.Master = float(cfgDat['masterVolume', 1].val)
    debug('Config loaded')

def _connectDevices():
    midiIn = op('/project1/midiin1')
    if midiIn:
        midiIn.par.device = 'IAC Driver Bus 1'
        debug('MIDI connected')

def _setDefaults():
    op('/project1/geo1').par.tx = 0
    op('/project1/geo1').par.ty = 0
    debug('Defaults set')
```

---

These examples demonstrate:
- Correct separation of expression / callback / module contexts
- The `debug()` habit for all logging
- `.eval()` when raw values are needed
- Uppercase = public, lowercase = private (extensions)
- Module pattern for shared utilities
