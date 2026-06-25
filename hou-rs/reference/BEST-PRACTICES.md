# Redshift Best Practices (Houdini)

Cross-cutting habits for fast, clean, flicker-free Redshift renders.

---

## Optimize in the right order

1. **Look first, quality later.** Lock composition, lighting, and materials at low samples / progressive IPR. Don't tune noise on a look that will change.
2. **Localize noise** before raising anything global. Use AOVs (diffuse, reflection, GI, shadows) to see *where* noise lives.
3. **Raise the specific knob:** per-light samples for shadows, reflection samples for glossy, GI rays for splotches.
4. **Adaptive Error Threshold** sets final quality vs. time.
5. **Denoise** to finish, not to hide a broken setup.

The mistake to avoid: cranking Unified Max Samples to fix one noisy effect. It slows the *whole* frame for one problem.

---

## VRAM is the budget (it's a GPU renderer)

- Keep geometry + textures within VRAM; out-of-core works but is slower.
- **`.rstexbin` textures** mip-map and out-of-core gracefully — convert everything.
- **Redshift proxies (`.rs`)** for heavy/instanced geo — load at render time, low memory, great for scatter (forests, crowds, debris).
- **Instancing** over real copies; packed primitives stay light.
- Watch the render log for out-of-core warnings; if you see them, reduce texture res, proxy heavy geo, or add VRAM/GPUs.

---

## Animation: kill the flicker

GI and caching artifacts flicker frame-to-frame. Defenses:

- **Use flicker-resistant GI:** Brute Force (primary) + **Irradiance Point Cloud** (secondary). Avoid Irradiance Cache alone for moving cameras.
- **Brute Force both** if you can afford it — no caching, no flicker (just noise, which denoise handles).
- **Enough samples + consistent threshold** so adaptive sampling doesn't swing per frame.
- **Denoise temporally** where available; per-frame denoise can itself flicker if undertrained.
- **Lock seeds / animated noise pattern** appropriately — test a short range before committing the farm.

---

## Sampling discipline

- Min Samples low, Max Samples generous, **threshold** does the work.
- Per-light samples proportional to each light's brightness/softness.
- Clamp to remove fireflies, but gently for hyperreal.
- More samples never fixes a *bias/leak* problem — that's a GI engine or geometry issue.

---

## Materials & textures

- Data maps **raw**, color maps **sRGB**.
- Disable unused shader layers (coat/sheen/SSS) — they cost even at low weight.
- Bump for micro-detail; displacement only for silhouette; bound max displacement.
- Lowest transmission trace depth that doesn't go black.

---

## Scripting & pipeline (with hou-python)

- Drive the Redshift ROP from HOM for wedges and farm submission; confirm parm names with `node.parms()` since they vary by version.
- Export `.rs` archives for license-light farm rendering.
- Pre-process textures and point caches at local SSD.
- Keep a **base render-settings template** (HDA or saved ROP) per look (hyperreal / stylized) so shots start consistent.

---

## Look-dev hygiene

- Light groups / per-light AOVs → rebalance in comp without re-rendering.
- Keep an **AOV set** (diffuse, reflection, refraction, GI, SSS, depth, motion, cryptomatte) so comp can fix things cheaply.
- Validate on the **final output resolution and codec** before farming — noise reads differently at full res.

---

## Speed checklist (when a render is too slow)

1. Is the noise global or from one effect? (AOVs)
2. Trace depth higher than the shot needs? Lower it.
3. GI engine appropriate? (BF+IPC for anim; not BF+BF if you can't afford it.)
4. Threshold tighter than necessary? Loosen + denoise.
5. Textures `.rstexbin`? Geo proxied/instanced? VRAM ok?
6. Per-light samples balanced, or all maxed?
7. Could denoise finish it 30% sooner?
