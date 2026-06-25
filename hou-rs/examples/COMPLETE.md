# Complete Redshift Setups (Houdini)

End-to-end recipes. Scripts use defensive parm setting (`if p:`) because Redshift parm names vary by version — confirm with `node.parms()` and substitute real names.

---

## 1. Hyperrealistic product shot

Goal: clean, physically accurate hero still of a product on a sweep.

**Lighting**
- Large soft **key** area light (Samples ~48), 45° camera-left.
- **Dome** HDRI fill, importance sampling on, low intensity.
- Small **rim** area light behind, Samples ~16.
- Light groups on all three for comp rebalancing.

**Render settings**
- Unified: Min 16 / Max 512 / Threshold 0.003.
- GI: Brute Force + Brute Force, GI rays 256.
- Reflection depth 6, refraction depth 8.
- Clamp gentle; denoise (Altus) as a finishing pass.

**Materials**
- RS Standard Material, metalness PBR, roughness from `.rstexbin` (raw).
- Round corners for cheap edge highlights.

```python
import hou

def setup_hyperreal(rop_path="/out/Redshift_ROP"):
    rop = hou.node(rop_path)
    cfg = {
        "RS_unifiedMinSamples": 16,
        "RS_unifiedMaxSamples": 512,
        "RS_unifiedAdaptiveErrorThreshold": 0.003,
        "RS_GIEnabled": 1,
        "RS_GIPrimaryEngine": 0,    # Brute Force
        "RS_GISecondaryEngine": 0,  # Brute Force
        "RS_numGIBounces": 4,
        "RS_reflectionMaxTraceDepth": 6,
        "RS_refractionMaxTraceDepth": 8,
    }
    for n, v in cfg.items():
        p = rop.parm(n)
        if p: p.set(v)
        else: print("confirm parm:", n)

    # Per-light samples
    for name, s in (("key_light", 48), ("rim_light", 16)):
        n = hou.node(f"/obj/{name}")
        if n:
            sp = n.parm("RS_light_samples") or n.parm("Samples")
            if sp: sp.set(s)

setup_hyperreal()
```

---

## 2. Stylized / motion-graphics look

Goal: clean, flat, fast frames; light is art direction, not simulation.

**Lighting**
- Shaped **key** with hard-ish shadow.
- Two flat **fill** lights replacing GI.
- Bright **rim** for silhouette.
- GI off.

**Render settings**
- Unified: Min 8 / Max 128 / Threshold 0.015.
- GI disabled (fake bounce with fills).
- Trace depth 2 / 2.
- Clamp harder for clean highlights; OptiX denoise aggressive.

**Materials**
- Ramp-driven base color for banded shading.
- Roughness clamped to a few values.
- Emission/constant for flat fills.

```python
import hou

def setup_stylized(rop_path="/out/Redshift_ROP"):
    rop = hou.node(rop_path)
    cfg = {
        "RS_unifiedMinSamples": 8,
        "RS_unifiedMaxSamples": 128,
        "RS_unifiedAdaptiveErrorThreshold": 0.015,
        "RS_GIEnabled": 0,
        "RS_reflectionMaxTraceDepth": 2,
        "RS_refractionMaxTraceDepth": 2,
    }
    for n, v in cfg.items():
        p = rop.parm(n)
        if p: p.set(v)

setup_stylized()
```

---

## 3. Flicker-free animation GI

Goal: a moving-camera interior with no GI flicker.

**Strategy**
- Primary GI **Brute Force**, secondary **Irradiance Point Cloud** (precomputed → stable).
- Dome HDRI sky + **portals** on every window.
- Physical Sun for direct beams.
- Consistent samples/threshold across frames; temporal denoise if available.

```python
import hou

def setup_anim_gi(rop_path="/out/Redshift_ROP"):
    rop = hou.node(rop_path)
    cfg = {
        "RS_GIEnabled": 1,
        "RS_GIPrimaryEngine": 0,     # Brute Force
        "RS_GISecondaryEngine": 2,   # Irradiance Point Cloud (confirm enum)
        "RS_numGIBounces": 3,
        "RS_unifiedMinSamples": 16,
        "RS_unifiedMaxSamples": 256,
        "RS_unifiedAdaptiveErrorThreshold": 0.005,
    }
    for n, v in cfg.items():
        p = rop.parm(n)
        if p: p.set(v)
    print("Add light portals on windows; enable dome importance sampling.")

setup_anim_gi()
```

> Render a 20-frame test before committing the farm — verify no GI flicker and stable denoise.

---

## 4. Farm pipeline — export .rs and render with redshiftCmdLine

```python
# export_rs.py  — hython export_rs.py scene.hip 1 240
import sys, hou

def export_archives(hip, start, end, rop="/out/Redshift_ROP"):
    hou.hipFile.load(hip, ignore_load_warnings=True)
    node = hou.node(rop)
    # Put the ROP in "export .rs" mode and set the archive path.
    for cand in ("RS_archive_enable", "RS_exportToFile"):
        p = node.parm(cand)
        if p: p.set(1)
    ap = node.parm("RS_archive_file") or node.parm("RS_outputFileNamePrefix")
    if ap: ap.set("$HIP/rs/frame.$F4.rs")
    node.render(frame_range=(start, end, 1), verbose=True)

if __name__ == "__main__":
    export_archives(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
```

```bash
# 1) Process textures once (shared, fast storage)
find textures/ -type f \( -name "*.exr" -o -name "*.png" \) \
    -exec redshiftTextureProcessor {} \;

# 2) Export archives
hython export_rs.py scene.hip 1 240

# 3) Render archives across 4 parallel workers
total=240; jobs=4; size=$(((total+jobs-1)/jobs))
for i in $(seq 0 $((jobs-1))); do
  s=$((i*size+1)); e=$(((i+1)*size)); [ $e -gt $total ] && e=$total
  ( for n in $(seq -w $s $e); do redshiftCmdLine "rs/frame.${n}.rs"; done ) &
done
wait
```

Env on each node: `REDSHIFT_CACHEPATH` → local SSD, `REDSHIFT_GPUDEVICES` → that node's GPUs.

---

## 5. Render-time noise audit (AOVs)

Before optimizing, output diagnostic AOVs so you can see *where* noise lives, then apply the targeted fix:

| AOV noisy? | Fix |
| --- | --- |
| Global Illumination | raise Brute Force GI rays / change engine |
| Reflection | raise reflection samples / roughness |
| Shadows | raise the responsible light's samples |
| SSS | raise SSS samples |
| Specular fireflies | lower clamp |

Add the AOV set (diffuse, reflection, refraction, GI, SSS, shadow, depth, motion, cryptomatte) on the ROP so comp can also rebalance and denoise per pass.
