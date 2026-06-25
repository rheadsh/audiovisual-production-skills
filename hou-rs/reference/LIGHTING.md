# Redshift Lighting Optimization

Light is where most render noise comes from and where most render time is spent. Optimizing lighting in Redshift is about three things: **per-light samples**, **light placement/shape**, and **GI control**.

Redshift lights in Houdini are OBJ-level nodes: area light, dome (IBL/HDRI) light, sun/physical sky, IES, and point/spot. Each has its own **Samples** parameter — this is per-light, independent of Unified Sampling.

---

## Per-light samples — the shadow-noise knob

Each light has a **Samples** value (often default 16–32). It controls how many shadow rays that light casts per shading point. Noisy/soft shadows from one light → raise *that light's* samples, not global Max Samples.

| Symptom | Fix |
| --- | --- |
| Grainy soft shadow under a large area light | raise that area light's Samples (e.g. 16 → 32 → 64) |
| Noisy HDRI/dome lighting | raise dome Samples + enable importance sampling |
| One small bright light flickering | raise its Samples or reduce its size |
| Clean shadows everywhere but slow | *lower* samples on lights that aren't noisy |

**Budget samples per light by contribution.** A bright key with soft shadows needs more; a dim rim needs few. Tuning this per-light is the single biggest lighting speedup.

---

## Light shape & placement (cheaper noise)

Noise scales with how much the light varies across the hemisphere a point sees. You can reduce required samples by *placement*, for free:

- **Bigger, closer area lights** = softer shadows but more noise per sample → need more samples. **Smaller/farther** = sharper, cheaper. Choose the softness you need, no more.
- **Avoid grazing angles** into deep cavities — light squeezing through tiny gaps is the noisiest case; add a fill or widen the gap.
- **Spread / cone** — narrow the spread so the light only illuminates what matters; less wasted sampling.
- **Light linking / exclusion** — exclude objects a light doesn't need to touch; fewer rays.
- **Portals** for interiors lit through windows by a dome — portals concentrate samples on the openings, drastically cutting interior noise.

---

## Dome / IBL (HDRI) lights

- **Enable importance sampling** so samples go to the bright parts of the HDRI (sun, windows) instead of uniformly — major noise reduction.
- **Pre-blur or use a lower-res HDRI** for diffuse-only contribution; keep a sharp copy for reflections if needed.
- **Background vs. lighting** — you can show a different (sharper) environment in reflections than the one lighting the scene.
- For interiors lit only through windows, pair the dome with **light portals**.

---

## Physical Sun & Sky

- Use for exteriors; it's a single efficient directional source.
- Sun **size/angle** controls shadow softness — small angle = sharp, cheap shadows; large = soft, needs more samples.
- Combine with a dome for sky fill.

---

## GI control from lighting

GI cost depends on how much indirect light bounces. Control it:

- **Fake the bounce.** For stylized or speed-critical work, turn GI off and add low-intensity **fill lights** where bounce would land. Total control, near-zero GI cost.
- **Diffuse bounce contribution per light** — some setups let you scale how much each light feeds GI.
- **Cut bounces with trace depth** (see RENDER-SETTINGS.md). Most scenes read fine at 2–3 diffuse bounces; interiors may need more.
- **Emissive geometry as light is expensive** — prefer real area lights. If you must use emissive meshes for bounce, keep their contribution modest and lean on GI rays.

---

## Light groups & AOVs

Put lights in **light groups** to output per-light AOVs. This lets you rebalance key/fill/rim in comp *without re-rendering* — the cheapest possible lighting iteration. Essential for both hyperreal (relight in comp) and stylistic (push ramps per light) workflows.

---

## Lighting recipes

**Hyperreal product/hero:**
- Key: area light, moderate size, Samples 48–64, soft shadow.
- Fill: large dim area or dome, importance-sampled.
- Rim: small area, low samples.
- GI: Brute Force; raise GI rays for clean bounce.
- Light groups on all three for comp.

**Stylized:**
- Key: shaped area, hard-ish shadow, modest samples.
- Fill: flat fill light(s) replacing GI.
- Rim: bright, for silhouette.
- GI: off or minimal.
- Clamp highlights for clean look.

**Interior (daylight through windows):**
- Dome (HDRI sky) + **portals** on every window.
- Physical Sun for direct beams.
- GI: Brute Force + IPC (animation) or Irradiance Cache + IPC (still).
- Raise dome samples; portals do the heavy lifting.

---

## Lighting noise checklist

1. Isolate each light (solo) to see which one is noisy.
2. Raise samples only on the noisy light(s).
3. Lower samples on clean/dim lights to claw back time.
4. Enable dome importance sampling; add portals for interiors.
5. Consider faking bounce with fills before paying for GI.
6. Use light groups so you can rebalance in comp.
