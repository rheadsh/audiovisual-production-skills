# Redshift Troubleshooting (Houdini)

Common Redshift problems and how to fix them. Diagnose with AOVs first — they tell you *which* effect is failing.

---

## Splotches / blotchy GI

**Cause:** GI engine under-sampled or the wrong engine for the scene.

- Raise **Brute Force GI rays** (64 → 128 → 256).
- If using Irradiance Cache, increase its quality/density or switch primary to Brute Force.
- For interiors, the splotches are often GI struggling through small openings — add **light portals**.

Don't fix GI splotches with Unified samples — wrong knob.

---

## Flicker in animation

**Cause:** view-dependent GI caching recomputed per frame, or unstable sampling.

- Switch secondary GI to **Irradiance Point Cloud** (precomputed, flicker-resistant), or use **Brute Force both**.
- Avoid Irradiance Cache alone with a moving camera.
- Ensure consistent samples/threshold across frames.
- Test temporal denoise on a short range before farming.

---

## Fireflies (bright single-pixel dots)

**Cause:** rare high-energy samples (tiny bright reflections, sharp speculars, emissive geo).

- Lower **Max subsample intensity / clamp** (gently for hyperreal).
- Reduce size of very bright small lights or raise their samples.
- Increase reflection samples for the noisy material.
- For emissive-geo bounce, reduce intensity or use a real area light.

---

## Noise in soft shadows

**Cause:** too few shadow samples on the responsible light.

- Solo each light to find the culprit.
- Raise **that light's Samples** (16 → 32 → 64).
- Or make the light smaller/farther if the softness isn't needed.

---

## Noise in blurry reflections / rough glass

**Cause:** mid-roughness glossy needs more samples.

- Raise **reflection / refraction samples** on the material or ROP.
- Slightly increase roughness or mip bias if the look allows (cheaper).

---

## Out of VRAM / out-of-core warnings (slow)

**Cause:** geometry + textures exceed GPU memory.

- Convert textures to **`.rstexbin`** (mip-mapped, out-of-coreable).
- **Proxy** heavy/instanced geometry (`.rs`).
- Use **instancing** and packed primitives.
- Lower texture resolution or displacement memory.
- Reduce tessellation; bound **max displacement** correctly.
- Add GPUs / pick a higher-VRAM device with `REDSHIFT_GPUDEVICES`.

---

## Render is slow but clean

You're over-sampling.

- Loosen **Adaptive Error Threshold** and let the **denoiser** finish.
- Lower **trace depth** to what the shot needs.
- Lower samples on lights that aren't noisy.
- Switch GI to a cheaper engine combo if accuracy allows.

---

## Black or wrong refraction (glass goes dark)

**Cause:** refraction trace depth too low for stacked transparent surfaces.

- Raise **refraction trace depth** until it clears.
- Check the material's thin/thick transmission setting matches the geometry (solid vs. shell).

---

## Materials look wrong (roughness/normals off)

**Cause:** data maps tagged as sRGB.

- Set roughness/metalness/normal/displacement maps to **raw / linear**.
- Only color/albedo/emission are sRGB.

---

## Displacement exploding or memory-heavy

- Set realistic **max displacement** bounds.
- Reduce displacement **scale**.
- Lower **tessellation/subdivision** level.
- Use **bump** for fine detail instead of displacing it.

---

## ROP renders nothing / wrong output

- Confirm the ROP node path (`/out/Redshift_ROP`) with `hou.node(path)`.
- Check the output path expands and the directory is writable (`hou.expandString`).
- Frame range / `trange` set correctly.
- If exporting `.rs`, confirm the ROP is in export mode and AOVs/output were set **before** export.

---

## redshiftCmdLine can't render / missing data

- The `.rs` archive bakes paths at export — broken texture/proxy paths fail at render. Use consistent, accessible paths (or `.rstexbin` in a shared location).
- Confirm `redshiftCmdLine -h` options match your version's flags.
- Check `REDSHIFT_GPUDEVICES` / licensing env on the render node.

---

## Diagnostic workflow

1. Render the relevant **AOVs** (GI, reflection, shadows, SSS) — isolate the failing effect.
2. Solo lights to find shadow-noise sources.
3. Change **one** knob at a time and compare.
4. Confirm parm names in your version (`node.parms()`); labels drift across releases.
