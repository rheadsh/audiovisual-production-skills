# Rendering — Python Automation & Optimization

Drive Houdini's renderers (Karma, Mantra, and any ROP) from Python: batch ranges, farm chunks, wedge parameters, and keep cooks cheap. Karma (USD/Solaris) is the modern default; Mantra still works the same way from HOM.

Runnable scripts are in [../examples/COMPLETE.md](../examples/COMPLETE.md) (render farm + scene auditor) and [../examples/PATTERNS.md](../examples/PATTERNS.md).

---

## The render call

Every ROP renders the same way:

```python
rop = hou.node("/stage/usdrender_rop1")    # Karma (Solaris)
# rop = hou.node("/out/karma1")            # Karma ROP in /out
# rop = hou.node("/out/mantra1")           # Mantra
rop.render(
    frame_range=(1, 240, 1),               # (start, end, inc)
    verbose=True,
    output_progress=True,
)
```

Set output path with variables so frames and versions stay organized:

```python
rop.parm("picture").set("$HIP/render/v003/$OS.$F4.exr")
rop.parm("trange").set(1)                  # 1 = render the frame range
```

---

## Headless rendering with hython

UI cooking overhead disappears in `hython`, and it's farmable. Load, render, done:

```bash
hython -c "import hou; hou.hipFile.load('scene.hip'); \
hou.node('/stage/usdrender_rop1').render(frame_range=(1,240))"
```

Or a script that takes a chunk (see `render_chunk.py` in COMPLETE.md), launched once per frame range across machines.

---

## Frame-range farming (chunking)

Split a range into N jobs so machines render in parallel. Each job renders a contiguous slice:

```python
def chunks(start, end, n):
    total = end - start + 1
    size = -(-total // n)                   # ceil division
    for i in range(n):
        s = start + i * size
        e = min(s + size - 1, end)
        if s <= end:
            yield (s, e)

for s, e in chunks(1, 240, 4):
    print(f"job: {s}-{e}")                  # dispatch hython per (s, e)
```

---

## Wedging (parameter sweeps)

Render variations by sweeping a parm between renders. Great for look-dev and the modeling presets in MODELING.md:

```python
ctrl = hou.node("/obj/geo1/mountain1")
rop  = hou.node("/out/karma1")
for i, h in enumerate([0.5, 1.0, 1.5, 2.0]):
    ctrl.parm("height").set(h)
    rop.parm("picture").set(f"$HIP/render/wedge_{i:02d}.$F4.exr")
    rop.render(frame_range=(1, 1))
```

For production, the TOP/PDG `ropfetch` + `wedge` nodes do this with dependency tracking and parallel scheduling — drive their parms from Python and `cookWorkItems()`.

---

## Dependency-aware rendering

If ROPs depend on each other (sim cache → render), render by dependency so upstream caches build first:

```python
rop.render(method=hou.renderMethod.RopByRop)   # walk the ROP dependency graph
```

---

## Optimization checklist

Render time is mostly *cook* time plus *sampling* time. Attack both.

**Cook once, render many.**
- Cache sims and heavy SOPs to disk (`.bgeo.sc`, `.vdb`, USD) with a File Cache / ROP Geometry node, then read them back. A sim that re-solves every frame of every render is the classic farm killer.
- Freeze finished geometry to a File SOP so downstream tweaks don't recook it.
- Use `node.cookCount()` (see the scene auditor in COMPLETE.md) to find what cooks most.

**Sample smart, not hard.**
- Converge with a sane pixel-sample count and let the **denoiser** finish, rather than brute-forcing samples. (Karma: `samplesperpixel` + enable denoise.)
- Set per-light samples where noise actually is; don't globally crank samples.
- Limit ray depth (diffuse/reflect/refract bounces) to what the shot needs.

**Defer and instance.**
- Use packed primitives / instancing for repeated geometry instead of real copies — less RAM, faster load.
- Defer-load (delayed load / USD payloads) so the renderer only pulls what's visible.

**Scene hygiene from Python.**
- `with hou.undos.disabler():` around large programmatic scene edits.
- Avoid forcing cooks in loops; batch parm changes, then render.
- Resolve `hou.node()` handles once and reuse them in tight scripts.

**IO.**
- Write EXR (multi-part for AOVs), not per-AOV files, to cut disk overhead.
- Render to local/fast storage, then move — avoid hammering network storage frame-by-frame.

---

## Reading back / checking output

```python
import os, hou
out_dir = hou.expandString("$HIP/render/v003")
frames = sorted(f for f in os.listdir(out_dir) if f.endswith(".exr"))
expected = set(range(1, 241))
got = {int(f.split(".")[-2]) for f in frames}
missing = sorted(expected - got)
print("missing frames:", missing)          # re-render just these
```

---

## Profiling a render-prep pass

```python
profile = hou.perfMon.startProfile("render prep")
hou.node("/obj/sim/OUT").cook(force=True)   # warm caches
profile.stop()
profile.exportAsCSV("$HIP/profile_renderprep.csv")
```
