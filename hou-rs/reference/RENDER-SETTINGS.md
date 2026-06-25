# Redshift Render Settings (Redshift ROP)

The settings that decide quality and time, and concrete presets for hyperrealistic and stylistic looks. All live on the **Redshift ROP** (`/out/Redshift_ROP`) unless noted. Confirm exact parm labels in your version's UI.

---

## Unified Sampling — the master quality control

Redshift uses a single **Unified Sampler** that adaptively decides how many samples each pixel needs.

| Setting | What it does | Push for cleaner | Push for faster |
| --- | --- | --- | --- |
| **Min Samples** | floor of samples per pixel | raise if flat areas are noisy | lower (e.g. 4–8) |
| **Max Samples** | ceiling adaptivity can reach | raise for hard cases (16→64+) | lower |
| **Adaptive Error Threshold** | noise target; lower = cleaner | 0.01 → 0.005 → 0.002 | 0.01 → 0.05 |
| **Random Noise Pattern** | animates the seed per frame | — | — (leave default; see flicker notes) |

**Workflow:** set Min low (e.g. 8), Max generous (e.g. 64–256), then drive quality with the **Adaptive Error Threshold**. The threshold is the dial you actually tune. Max Samples is just the budget adaptivity is allowed to spend on the worst pixels.

---

## Per-effect samples (localize the noise)

Redshift lets you override samples for specific effects rather than raising global Max. Find the noisy effect (use AOVs), raise only its samples:

- **Reflection / glossy samples** — for blurry reflections and rough metal.
- **Refraction samples** — for frosted glass / rough transmission.
- **Shadow / area-light samples** — set on the *light* (see LIGHTING.md), not the ROP.
- **AO samples**, **SSS samples**, **Volume samples** — per-effect.
- **Brute Force GI rays** — GI noise (see below).

Rule: doubling one effect's samples is far cheaper than doubling Unified Max.

---

## Global Illumination

Choose a **Primary** and a **Secondary** GI engine. Engines:

| Engine | Character | Use |
| --- | --- | --- |
| **Brute Force** | unbiased, accurate, noisy/slow | primary for hero stills; secondary if budget allows |
| **Irradiance Cache** | smooth, view-dependent, can flicker | primary for interiors (stills) |
| **Irradiance Point Cloud (IPC)** | precomputed, flicker-resistant | secondary for animation |
| **Photon Map (Caustics)** | caustics, light through glass | when you need real caustics |

**Recommended combos:**
- **Hyperreal still:** Brute Force (primary) + Brute Force (secondary). Most accurate; raise BF rays until splotches clear.
- **Hyperreal / clean animation:** Brute Force (primary) + Irradiance Point Cloud (secondary). IPC is precomputed → no GI flicker.
- **Interior arch-viz (still):** Irradiance Cache (primary) + IPC (secondary) for speed; validate no light leaks.
- **Stylized:** often Brute Force at low rays, or GI off with faked bounce via fill lights.

**Brute Force GI rays** is the GI noise knob — raise it (e.g. 64 → 128 → 256) to clear GI splotches without touching Unified samples.

---

## Trace depth (bounces)

- **Reflection trace depth** — number of reflection bounces. Hyperreal interiors/glass: 4–8. Stylized: 1–2.
- **Refraction trace depth** — for stacked transparent surfaces (glass, liquid). Raise only if you see black where light should pass.
- **Combined / max trace depth** — overall cap; keep as low as the shot allows. Each extra bounce costs time.

Lowering trace depth is one of the cheapest speedups for stylized work.

---

## Buckets vs. Progressive

- **Bucket (tiled)** — final-quality renders; uses Adaptive Error Threshold; best for farm/output.
- **Progressive** — refines the whole frame over passes; best for look-dev / IPR in the RenderView. Set a pass count or time limit.

Render output is almost always **bucket**. Bucket size rarely needs changing (default is tuned per GPU).

---

## Denoising

Denoise converges faster than brute samples for the final cleanup:

- **OptiX denoiser** — fast, GPU, great for previews and many finals; can soften fine detail.
- **Altus denoiser** — higher quality, dual-render based; for hero work.
- **Innobright/Redshift built-in** — per-AOV denoise.

For **stylistic** renders, lean on denoise heavily and drop samples — micro-noise rarely matters. For **hyperreal**, denoise *after* getting close with samples so you don't smear detail.

---

## Clamping & highlights

- **Max subsample intensity / clamp** — kills fireflies from tiny bright samples. Lower to remove fireflies (e.g. from small bright reflections), but too low dulls highlights. Hyperreal: clamp gently. Stylized: clamp harder for flat, clean highlights.

---

<a id="hyperrealistic"></a>
## Preset: Hyperrealistic

Goal: physically faithful light transport, fine detail, no visible noise.

```
Unified Sampling:
  Min Samples:               16
  Max Samples:               512
  Adaptive Error Threshold:  0.003   (low = clean; raise if too slow)

Global Illumination:
  Enabled:                   yes
  Primary:                   Brute Force
  Secondary:                 Brute Force        (or IPC for animation)
  Brute Force GI rays:       128–256

Trace depth:
  Reflection:                4–8
  Refraction:                6–12 (glass/liquid)
  Combined max:              as needed, keep tight

Per-effect:
  Reflection/Refraction samples: raise only where noisy
  SSS samples:               raise for skin/wax/marble

Clamp:                       gentle (preserve highlights)
Denoise:                     Altus/OptiX AFTER near-converged
Textures:                    .rstexbin, sRGB on color / raw on data maps
```

Spend time on: GI rays (splotches), per-light samples (shadows), SSS (skin), trace depth (glass).

---

<a id="stylistic"></a>
## Preset: Stylistic / Non-photoreal

Goal: art-directed, clean, fast; light is a design tool, not a simulation.

```
Unified Sampling:
  Min Samples:               4–8
  Max Samples:               64–128
  Adaptive Error Threshold:  0.01–0.02   (looser; denoise finishes it)

Global Illumination:
  Often OFF (fake bounce with fill lights), or
  Brute Force at low rays (32–64) for a hint of bounce

Trace depth:
  Reflection:                1–2
  Refraction:                1–2
  Combined max:              low

Clamp:                       harder (flat, clean highlights, no fireflies)
Denoise:                     OptiX, aggressive
Shading:                     toon/flat ramps, controlled roughness
Textures:                    .rstexbin
```

Spend time on: lighting design (key/fill/rim), ramps and shader control, clamp for clean highlights. Don't pay for GI accuracy you'll stylize away.

---

## Quick comparison

| Setting | Hyperreal | Stylistic |
| --- | --- | --- |
| Adaptive Error Threshold | 0.002–0.005 | 0.01–0.02 |
| Max Samples | 256–512+ | 64–128 |
| GI | Brute Force (+BF/IPC) | off or low BF |
| Trace depth (refl/refr) | 4–8 / 6–12 | 1–2 / 1–2 |
| Clamp | gentle | hard |
| Denoise | finishing only | aggressive |
