# Redshift in Houdini — Patterns

Copy-paste recipes: setting presets, `hou` scripts to configure the ROP, lighting/shader/CLI snippets.

> Parameter names (e.g. `RS_unifiedMaxSamples`) follow common Redshift ROP spare-parm conventions but **vary by version**. Confirm with `for p in node.parms(): print(p.name())` before scripting, then swap in the real names.

---

## Inspect the Redshift ROP's real parm names

```python
import hou
rop = hou.node("/out/Redshift_ROP")
for p in rop.parms():
    if "ample" in p.name() or "GI" in p.name() or "race" in p.name():
        print(p.name(), "=", p.eval())
```

Run this once per Redshift version to get exact names, then use them below.

---

## Hyperrealistic preset (script)

```python
import hou
rop = hou.node("/out/Redshift_ROP")

settings = {
    # Unified sampling — threshold does the work
    "RS_unifiedMinSamples": 16,
    "RS_unifiedMaxSamples": 512,
    "RS_unifiedAdaptiveErrorThreshold": 0.003,
    # Global illumination
    "RS_GIEnabled": 1,
    "RS_GIPrimaryEngine": 0,     # Brute Force (confirm enum)
    "RS_GISecondaryEngine": 0,   # Brute Force (or IPC for animation)
    # Trace depth
    "RS_reflectionMaxTraceDepth": 6,
    "RS_refractionMaxTraceDepth": 8,
}
for name, val in settings.items():
    p = rop.parm(name)
    if p:                         # skip names that differ in your version
        p.set(val)
    else:
        print("parm not found, confirm name:", name)
```

---

## Stylistic preset (script)

```python
import hou
rop = hou.node("/out/Redshift_ROP")
stylized = {
    "RS_unifiedMinSamples": 8,
    "RS_unifiedMaxSamples": 128,
    "RS_unifiedAdaptiveErrorThreshold": 0.015,   # looser; denoise finishes
    "RS_GIEnabled": 0,                            # fake bounce with fill lights
    "RS_reflectionMaxTraceDepth": 2,
    "RS_refractionMaxTraceDepth": 2,
}
for name, val in stylized.items():
    p = rop.parm(name)
    if p: p.set(val)
```

---

## Set output path & frame range

```python
import hou
rop = hou.node("/out/Redshift_ROP")
op = rop.parm("RS_outputFileNamePrefix") or rop.parm("RS_outputFilePath")
if op: op.set("$HIP/render/$OS.$F4.exr")
rop.parm("trange").set(1)                  # render frame range
rop.parmTuple("f").set((1, 240, 1))        # start, end, inc (confirm parm)
```

---

## Per-light samples (find and balance)

```python
import hou
# Raise samples on noisy lights, lower on clean dim ones
for light in hou.node("/obj").recursiveGlob("*", hou.nodeTypeFilter.ObjLight):
    s = light.parm("RS_light_samples") or light.parm("Samples")  # confirm name
    if s:
        print(light.name(), "samples =", s.eval())

# Example: bump the key light
key = hou.node("/obj/key_light")
s = key.parm("RS_light_samples")
if s: s.set(48)
```

---

## Enable dome (HDRI) importance sampling

```python
import hou
dome = hou.node("/obj/rs_dome")
# Confirm exact parm names in your version:
for cand in ("RS_dome_importanceSampling", "importanceSampling"):
    p = dome.parm(cand)
    if p: p.set(1)
```

---

## Build a minimal RS Standard Material (network)

```python
import hou
# Create a Redshift material network at /mat (or inside a geo)
mat = hou.node("/mat") or hou.node("/obj").createNode("matnet", "mat")
vop = mat.createNode("redshift_vopnet", "RS_metal")
std = vop.node("StandardMaterial1") or vop.createNode("redshift::StandardMaterial")
out = vop.node("redshift_material1")
if out: out.setNamedInput("Surface", std, "outColor")

# Brushed metal
std.parm("base_color_weight").set(1) if std.parm("base_color_weight") else None
std.parm("metalness").set(1.0) if std.parm("metalness") else None
std.parm("refl_roughness").set(0.25) if std.parm("refl_roughness") else None
vop.layoutChildren()
```

(Confirm node type names — `redshift::StandardMaterial` and parm names differ by version. Use the Tab menu / `node.type().name()`.)

---

## Add a texture as .rstexbin (color space matters)

```python
import hou
vop = hou.node("/mat/RS_metal")
tex = vop.createNode("redshift::TextureSampler")
tex.parm("tex0").set("$HIP/tex/metal_albedo.rstexbin")
# Color map -> sRGB; data maps -> raw. Confirm the colorspace parm name.
cs = tex.parm("tex0_colorSpace") or tex.parm("colorSpace")
if cs: cs.set("sRGB")
```

---

## CLI: process textures

```bash
# Convert a folder of source maps to .rstexbin
find textures/ -type f \( -name "*.exr" -o -name "*.png" -o -name "*.tif" \) \
    -exec redshiftTextureProcessor {} \;
```

## CLI: render exported archives

```bash
# Export .rs from Houdini (ROP set to export mode), then:
for f in rs/frame.*.rs; do redshiftCmdLine "$f"; done
redshiftCmdLine -h        # confirm flags for your version
```

## CLI: hython render

```bash
hython -c "import hou; hou.hipFile.load('scene.hip'); \
hou.node('/out/Redshift_ROP').render(frame_range=(1,240))"
```

---

## Wedge: sweep a setting for look-dev

```python
import hou
rop = hou.node("/out/Redshift_ROP")
thr = rop.parm("RS_unifiedAdaptiveErrorThreshold")
op  = rop.parm("RS_outputFileNamePrefix")
for i, t in enumerate([0.02, 0.01, 0.005, 0.002]):
    if thr: thr.set(t)
    if op:  op.set(f"$HIP/render/thr_{i}.$F4.exr")
    rop.render(frame_range=(1, 1))
```
