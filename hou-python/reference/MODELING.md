# Procedural Modeling — Carving & Sculpting as Code

Traditional sculpting divides into two families. **Subtractive** craft (carving wood, stone, wax) starts from a solid mass and *removes* material. **Additive** craft (clay sculpting) starts from an armature and *builds up* form. Both translate directly into procedural Houdini operations driven from Python.

This reference is the conceptual map; runnable snippets are in [../examples/PATTERNS.md](../examples/PATTERNS.md) and full systems in [../examples/COMPLETE.md](../examples/COMPLETE.md).

---

## Translation table

| Craft action | Physical meaning | Houdini operation | Driven from Python |
| --- | --- | --- | --- |
| Rough out / block in | knock off big chunks | `boolean` subtract, `mountain` displace | `createNode`, set `height` |
| Chisel / gouge | remove a controlled cut | `boolean` with tapered cutter | merge cutters, subtract |
| Whittle a curve | shave along grain | `polyextrude` inward, `peak` negative | parm-driven peak |
| Sand / weather | erode sharp edges | VDB → `vdbsmoothsdf` → convert | iterations parm |
| Press clay on | add material | `peak`/inflate along `@N` | bulk `setPointFloatAttribValues` |
| Pinch / pull | local deformation | point Wrangle, `attribvop` | generate VEX snippet |
| Smooth with thumb | blend surface | `smooth` SOP | strength + iterations |
| Stamp texture | impress detail | displacement from texture/noise | `mountain`, `attribnoise` |

---

## Subtractive — carving wood, stone, wax

The core idea: **define a mass, define what to remove, subtract.** In Houdini the cleanest subtractive primitive is the Boolean SOP in `subtract` mode (A minus B), and for organic erosion, signed-distance-field (VDB) operations.

### Boolean chiseling

Build the block, build cutter geometry shaped like your tool (a tapered tube ≈ a gouge, a wedge ≈ a flat chisel), merge all cutters, and subtract once. Subtracting a single merged cutter is far cheaper than chaining many booleans.

```python
boolean = geo.createNode("boolean::2.0")
boolean.parm("booleanop").set("subtract")   # A (block) minus B (cutters)
boolean.setInput(0, block)
boolean.setInput(1, merged_cutters)
```

### Material character

The medium changes *how* you carve, and you encode that in parameters:

- **Wood** — directional grain. Bias cuts and noise along one axis. Add an anisotropic noise (stretch the noise frequency on the grain axis) before displacing, so chips follow the grain.
- **Stone** — brittle, chunky. Use Boolean with slightly irregular cutters and a Voronoi fracture pass for chipping; weather edges with a small VDB smooth so corners read as worn.
- **Wax** — soft, rounded. Heavier `vdbsmoothsdf` (more iterations) and lower-frequency displacement; wax holds smooth, flowing surfaces, never crisp facets.

### Weathering / erosion (VDB)

Convert the carved mesh to a VDB SDF, smooth/erode it, convert back. Smoothing an SDF rounds convex edges first — exactly how real weathering wears corners before flats.

```python
to_vdb = geo.createNode("vdbfrompolygons")
erode  = geo.createNode("vdbsmoothsdf"); erode.parm("iterations").set(3)
back   = geo.createNode("convertvdb"); back.parm("conversion").set("convertToPolygons")
```

---

## Additive — clay sculpting

The core idea: **start with a mass, push/pull/pinch and build up, then smooth.** Procedurally this is displacement along normals plus smoothing. The three clays differ mainly in *softness*, which maps to smoothing strength and how much fine detail survives.

### The three clays as parameters

| Clay | Behaviour | Smooth strength | Iterations | Detail retained |
| --- | --- | --- | --- | --- |
| **Water-based** | very soft, blends fast, dries/cracks | 0.85–0.95 | 12–16 | low (fingers blur it) |
| **Oil-based** | holds form, never dries, re-workable | 0.5–0.7 | 6–10 | medium |
| **Polymer** | firm, crisp, keeps tool marks | 0.3–0.4 | 3–5 | high |

Encode as a dictionary and pick a preset (see `build_clay_sculpt` in COMPLETE.md).

### Build-up along normals (pressing material on)

Additive sculpting pushes points outward along their normals. Do it in bulk for speed — read `P` and `N` as flat lists, add, write back:

```python
P = geo.pointFloatAttribValues("P")
N = geo.pointFloatAttribValues("N")
P = [p + n * amount for p, n in zip(P, N)]   # inflate
geo.setPointFloatAttribValues("P", P)
```

For *localized* push/pinch (a thumb press), drive the amount by distance to a control point, or generate a point Wrangle from Python so the per-point math runs in parallel VEX rather than a Python loop.

### Smoothing (the thumb pass)

The Smooth SOP relaxes the mesh. High strength + iterations = water clay; low = polymer that keeps your stamped detail.

```python
smooth = geo.createNode("smooth")
smooth.parm("strength").set(0.6)     # softer clay = higher
smooth.parm("iterations").set(8)
```

---

## Building geometry from scratch (Python SOP)

When you need geometry no stock SOP produces, generate it in a Python SOP. Rules of thumb:

1. **Bulk over loops.** For more than a few thousand points, never call `createPoint()` in a loop — allocate with `createPoints([...])` and write attributes with `setPointFloatAttribValues`. A Python `for` loop over `geo.points()` is the single most common cause of a slow Python SOP.
2. **Precompute in flat lists.** Build a flat `[x, y, z, x, y, z, ...]` list, then one `setPointFloatAttribValues("P", flat)` call.
3. **Add the attribute before writing it.** `geo.addAttrib(hou.attribType.Point, "Cd", default)` once, then set values.
4. **Push heavy per-point math to VEX.** Python is single-threaded. If the math is the bottleneck, emit a Wrangle snippet from Python and let VEX parallelize it. (See the `hou-vex` skill.)

---

## Driving HDA carving/sculpt tools

If you have a carving HDA (or build one), expose `depth`, `grain_axis`, `weathering`, `clay_softness` as parameters and drive them from Python for variation/wedging. This keeps the artist-facing tool simple while Python sweeps the inputs.

```python
tool = hou.node("/obj/geo1/my_carve_hda")
tool.setParms({"depth": 0.2, "grain_axis": 0, "weathering": 3})
```

---

## Performance notes for modeling

- Convert to VDB *once* and do all SDF ops in VDB space before converting back — round-tripping poly↔VDB repeatedly is expensive.
- Boolean is sensitive to non-manifold and self-intersecting input; clean with `clean`/`fuse` before subtracting.
- Cache the heavy block-in to `.bgeo.sc` with a File SOP so downstream tweaks don't recook the whole carve.
- For huge point counts, prefer packed primitives and instancing over real geometry.
