# Redshift Shaders & Textures

How to build efficient materials and feed textures to Redshift in Houdini. Materials are built in a **Redshift material network** (`redshift_vopnet`) using the **RS Standard Material** (the modern PBR material) plus texture and utility nodes.

---

## RS Standard Material (the workhorse)

A metalness/roughness PBR material. Key parameter groups:

- **Base** — base color, metalness (0 = dielectric, 1 = metal), diffuse roughness.
- **Reflection** — roughness (the most important look control), IOR, GGX model, anisotropy.
- **Coat** — clear coat layer (car paint, lacquer).
- **Sheen** — fabric/dust micro-fiber.
- **Transmission** — glass/liquid; transmission color, roughness, dispersion (Abbe).
- **Subsurface (SSS)** — skin, wax, marble, milk; radius (per-channel), scale.
- **Emission** — self-illumination.
- **Geometry** — bump, normal, opacity, displacement input.

### Cost-aware material tips

- **Roughness drives noise.** Mid-roughness glossy reflections are the noisiest. Either raise reflection samples or accept slight blur; perfectly sharp (0) and very rough (1) are cheaper than the middle.
- **Transmission + high trace depth is expensive.** Use the lowest refraction trace depth that doesn't go black. For solid glass, enable the appropriate thin/thick setting.
- **SSS is expensive but fakeable.** For background characters, a diffuse + slight translucency can stand in for full SSS.
- **Disable unused layers.** Coat/sheen/SSS add cost even at low weight — turn them off if not visible.

---

## Texturing pipeline (the big speed/memory win)

### Convert to `.rstexbin`

Run source textures through the **Redshift Texture Processor** (`redshiftTextureProcessor`, see CLI.md). It produces tiled, mip-mapped `.rstexbin` files that Redshift can:
- mip-map (use lower res at distance → less aliasing, less memory),
- out-of-core (stream from disk when VRAM is tight),
- load far faster than raw PNG/EXR.

This is the highest-leverage texture optimization. Do it for every production texture.

### Color space — sRGB vs. raw

- **Color/albedo/emission maps:** sRGB (gamma).
- **Data maps (roughness, metalness, normal, displacement, AO, masks):** **raw / linear.** Tagging a data map as sRGB is the most common texturing bug — it shifts roughness and breaks normals.

### Texture sampling

- The texture node exposes filtering and **mip bias** — a small positive bias trades a touch of sharpness for less texture noise and memory.
- Reuse a single texture node across materials where possible; Redshift caches loaded textures.

---

## Displacement & bump

- **Bump / normal** — cheap, no geometry change; use for fine detail.
- **Displacement** — real geometry; needs **tessellation**. Control with:
  - displacement **scale** (keep modest; huge displacement = huge memory),
  - **tessellation / subdivision** settings (more = smoother + heavier),
  - **max displacement** bounds so Redshift can allocate correctly.
- Prefer bump for micro-detail and displacement only for silhouette-changing relief. Combining bump (fine) + displacement (large) is the efficient pattern.

---

## Stylized / toon shading

For non-photoreal looks:

- Drive base color through **ramp** nodes keyed to lighting or incidence for flat, banded shading.
- Use the **incandescent/emission** channel and constant shaders for flat fills.
- **Clamp** roughness to a few discrete values for a graphic look.
- Combine with a **toon/contour** AOV or post outline pass.
- Light contribution AOVs + ramps = full art-direction in comp.

---

## Utility nodes worth knowing

- **Texture sampler** — load `.rstexbin`/images, set color space.
- **Color correct / ramp** — remap maps without re-authoring.
- **Curvature / AO** — procedural wear and dirt masks.
- **Triplanar** — projection without UVs (great for procedural/sim geo).
- **Sprite** — cutout opacity from texture alpha (leaves, cards).
- **Round corners** — fake fillets for cheap realism on hard edges.
- **State/ray switch** — different shading for camera vs. reflection rays (optimization & cheats).

---

## Material optimization checklist

1. Convert all textures to `.rstexbin`.
2. Tag data maps **raw**, color maps **sRGB**.
3. Turn off unused material layers (coat/sheen/SSS).
4. Use bump for fine detail; displacement only for silhouette.
5. Keep transmission trace depth as low as the look allows.
6. Use triplanar on UV-less / simulated geometry.
7. For stylized work, replace physical shading with ramps and clamp roughness.
