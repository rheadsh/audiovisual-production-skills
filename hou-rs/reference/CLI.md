# Redshift CLI & Farm Rendering

How to render Redshift outside the Houdini UI: exporting `.rs` archives, the standalone `redshiftCmdLine` renderer, `hython`/`husk` rendering, the texture processor, and the environment variables that matter on a farm.

> Flags and behavior vary by Redshift version. Run each tool with `-h`/`--help` to confirm options on your install.

---

## Three ways to render headless

1. **`hython` driving the Redshift ROP** — full Houdini context, needs a Houdini Engine/license. Best when the scene must cook before rendering.
2. **`redshiftCmdLine` on exported `.rs` files** — license-light, fast to dispatch, no Houdini cook at render time. Best for farms.
3. **`husk`** — renders Solaris/USD stages with the Redshift Hydra delegate. Best for USD/Solaris pipelines.

---

## 1. Render via hython (drive the ROP)

```python
# render_rs.py  —  hython render_rs.py scene.hip 1 240
import sys, hou

def render(hip, start, end, rop="/out/Redshift_ROP"):
    hou.hipFile.load(hip, ignore_load_warnings=True)
    node = hou.node(rop)
    if node is None:
        raise hou.NodeError(f"ROP not found: {rop}")
    node.parm("RS_outputFileNamePrefix").set("$HIP/render/$OS.$F4.exr")  # confirm parm name
    node.render(frame_range=(start, end, 1), verbose=True)

if __name__ == "__main__":
    render(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
```

```bash
hython render_rs.py scene.hip 1 240
```

---

## 2. Export `.rs` archives, render with redshiftCmdLine

This decouples scene assembly (Houdini) from rendering (any machine with Redshift). On the Redshift ROP, enable **Export to .rs file** (archive) instead of rendering, and set a per-frame path like `$HIP/rs/frame.$F4.rs`.

```bash
# Export the .rs files from Houdini (ROP set to export mode)
hython -c "import hou; hou.hipFile.load('scene.hip'); \
hou.node('/out/Redshift_ROP').render(frame_range=(1,240))"

# Render each exported archive with the standalone CLI (no Houdini license)
for f in rs/frame.*.rs; do
    redshiftCmdLine "$f"
done
```

Common `redshiftCmdLine` usage:

```bash
redshiftCmdLine scene.0001.rs                 # render one archive
redshiftCmdLine scene.0001.rs -gpu 0,1        # choose GPUs (confirm flag with -h)
redshiftCmdLine -h                            # list all options for your version
```

The output path and AOVs are baked into the `.rs` at export time, so set them on the ROP before exporting.

---

## 3. Render Solaris/USD with husk + Redshift

```bash
# Render a USD stage with the Redshift Hydra delegate
husk --renderer Redshift --frame 1 --frame-count 240 \
     --output "$HIP/render/beauty.\$F4.exr" scene.usd
```

Use husk when your lighting/look is assembled in Solaris (LOPs) with a Redshift Render Settings prim.

---

## Texture processing CLI

Convert textures to `.rstexbin` ahead of render (see SHADERS-TEXTURES.md):

```bash
# Single file
redshiftTextureProcessor texture.exr

# Batch a folder (shell loop)
find textures/ -type f \( -name "*.exr" -o -name "*.png" -o -name "*.tif" \) \
    -exec redshiftTextureProcessor {} \;
```

Do this once per asset; the renderer then mip-maps and out-of-cores efficiently.

---

## Chunked farm dispatch

Split a range so machines render slices in parallel (same idea as any farm):

```bash
# 240 frames over 4 jobs, using exported .rs archives
total=240; jobs=4; size=$(( (total + jobs - 1) / jobs ))
for i in $(seq 0 $((jobs-1))); do
  s=$(( i*size + 1 )); e=$(( (i+1)*size )); [ $e -gt $total ] && e=$total
  ( for n in $(seq -w $s $e); do redshiftCmdLine "rs/frame.${n}.rs"; done ) &
done
wait
```

For real farms (Deadline, Tractor, HQueue), submit the Redshift ROP or the `.rs`/husk command per frame chunk; the renderer handles GPU assignment per node.

---

## Environment variables that matter

| Variable | Purpose |
| --- | --- |
| `REDSHIFT_COREDATAPATH` | Redshift install/data path |
| `REDSHIFT_LOCALDATAPATH` | local cache/log location |
| `REDSHIFT_CACHEPATH` | texture/irradiance cache directory (point at fast local disk) |
| `REDSHIFT_GPUDEVICES` | which GPUs Redshift uses (e.g. `0,1`) |
| `REDSHIFT_LICENSE...` | licensing config |
| `HOUDINI_PATH` | must include the Redshift Houdini plugin |

On a farm: put the **texture/irradiance cache on fast local storage** per node, pin GPUs with `REDSHIFT_GPUDEVICES`, and pre-convert textures so nodes don't each reprocess.

---

## CLI optimization checklist

1. Pre-convert textures to `.rstexbin` (once, shared).
2. Export `.rs` archives so render nodes don't cook Houdini.
3. Set output path + AOVs on the ROP **before** export.
4. Point `REDSHIFT_CACHEPATH` at local SSD per node.
5. Pin GPUs with `REDSHIFT_GPUDEVICES`.
6. Chunk the frame range across nodes; one renderer instance per node.
