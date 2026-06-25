---
name: hou-rs
description: Optimize Redshift rendering in SideFX Houdini — render settings, sampling, GI, lighting, shaders/textures, and CLI rendering. Use when tuning the Redshift ROP, choosing GI engines, reducing noise, dialing hyperrealistic vs. stylized looks, building RS Standard Material networks, processing textures, or rendering Redshift from the command line / farm. Triggers on Redshift, redshift, .rs, Redshift_ROP, redshiftCmdLine, rsMaterial, or GPU render optimization in Houdini.
---

# Houdini Redshift Render Optimization

Tune Redshift for SideFX Houdini for quality and speed: sampling, global illumination, lighting, shaders/textures, and command-line/farm rendering. Redshift is a GPU, biased, production renderer — the optimization game is *getting clean images with the fewest samples and the cheapest GI that still looks right.*

> Parameter names below use the common Redshift ROP / light spare-parameter labels. Exact internal parm names vary slightly by Redshift and Houdini version — confirm in the node UI or with `node.parms()` before scripting. Official docs: https://help.maxon.net/r3d/houdini/en-us/

## Quick Start

The core Redshift nodes in Houdini:

```
/out/Redshift_ROP            # the render output driver (settings live here)
/obj/.../rs_light            # Redshift area / dome / sun / IES lights
redshift_vopnet -> RS Standard Material   # material network (rsMaterial)
redshiftCmdLine scene.rs     # standalone CLI renderer for exported .rs files
```

The three levers that decide render time:

1. **Unified Sampling** — Min/Max samples + Adaptive Error Threshold. The threshold is your master noise-vs-time dial.
2. **GI engine choice** — Brute Force (accurate, slow) vs. Irradiance Cache / Irradiance Point Cloud (fast, biased).
3. **Per-light & per-effect samples** — push samples where the noise actually is, not globally.

## Critical Rules

1. **Tune the Adaptive Error Threshold first, samples second.** Lower threshold (e.g. 0.01 → 0.005) = cleaner + slower. Set Max Samples high enough that adaptivity can do its job; let the threshold control quality.
2. **Noise has a source — find it before raising global samples.** Reflection noise → raise reflection samples; shadow noise → raise that light's samples; GI splotches → change GI engine or raise GI rays. Raising Unified Max Samples to fix one noisy effect wastes time everywhere else.
3. **Pick GI by motion, not by taste.** Stills/hero frames tolerate Brute Force. Animation needs flicker-free GI: Brute Force (primary) + Irradiance Point Cloud (secondary), or Brute Force + Brute Force if you can afford it.
4. **Convert textures to `.rstexbin`.** Run textures through the Redshift Texture Processor so the renderer mip-maps and out-of-cores them efficiently — huge memory/speed win.
5. **Denoise instead of brute-forcing the last 20% of noise.** Use the Redshift/OptiX/Altus denoiser to converge faster, especially for stylized looks where micro-noise doesn't matter.
6. **Watch VRAM.** Redshift is GPU; geometry + textures must fit (or out-of-core, which is slower). Proxies, texture caching, and instancing keep you on the GPU.

## Two Looks, Two Setups

This skill is organized around the two render targets you asked for. Each has a full recipe in the reference:

**Hyperrealistic** — physically accurate light transport, full GI, high trace depth, fine sampling. Slower, used for hero shots and product/arch-viz. See [reference/RENDER-SETTINGS.md](reference/RENDER-SETTINGS.md#hyperrealistic).

**Stylistic / non-photoreal** — controlled, art-directed light; reduced/Faked GI, clamped highlights, flat or toon shading, heavier denoise, cheaper trace depth. Faster, used for motion graphics and stylized films. See [reference/RENDER-SETTINGS.md](reference/RENDER-SETTINGS.md#stylistic).

## Domains This Skill Covers

- **Render settings** — sampling, GI, trace depth, buckets vs. progressive, AOVs, denoise. → [reference/RENDER-SETTINGS.md](reference/RENDER-SETTINGS.md)
- **Lighting optimization** — per-light samples, light placement for low noise, dome/IBL importance sampling, GI control. → [reference/LIGHTING.md](reference/LIGHTING.md)
- **Shaders & textures** — RS Standard Material, roughness/metalness PBR, SSS, displacement, texture processing & caching. → [reference/SHADERS-TEXTURES.md](reference/SHADERS-TEXTURES.md)
- **CLI / farm** — exporting `.rs` archives, `redshiftCmdLine`, `hython`/`husk` rendering, env vars, chunked farming. → [reference/CLI.md](reference/CLI.md)

## Response Format

When advising on Redshift in Houdini, always include:

1. **What to change and where** — the node (Redshift ROP, a light, a material) and the parameter.
2. **Why** — which noise source or cost it targets.
3. **A starting value** — concrete numbers, with the direction to push (cleaner/faster).
4. **The trade-off** — what gets slower or what look you give up.

## Optimization Workflow

1. **Get the look first** at low samples — composition, lighting, materials.
2. **Choose the GI engine** for stills vs. animation.
3. **Localize noise** — render AOVs / isolate effects to see where it comes from.
4. **Raise the right samples** (light, reflection, GI) — not global Max.
5. **Set Adaptive Error Threshold** to trade final quality vs. time.
6. **Denoise** to finish.
7. **Process textures, check VRAM,** then farm via CLI.

## Additional Resources

- [examples/PATTERNS.md](examples/PATTERNS.md) — Copy-paste setting recipes & `hou` scripts
- [examples/COMPLETE.md](examples/COMPLETE.md) — Full setups (hyperreal product shot, stylized look, animation GI, farm pipeline)
- [reference/RENDER-SETTINGS.md](reference/RENDER-SETTINGS.md) — Sampling, GI, trace depth, denoise (hyperreal + stylistic)
- [reference/LIGHTING.md](reference/LIGHTING.md) — Light samples, placement, GI control
- [reference/SHADERS-TEXTURES.md](reference/SHADERS-TEXTURES.md) — Materials, PBR, displacement, texture pipeline
- [reference/CLI.md](reference/CLI.md) — `redshiftCmdLine`, `.rs` export, hython/husk, env vars
- [reference/BEST-PRACTICES.md](reference/BEST-PRACTICES.md) — VRAM, proxies, animation flicker, speed checklist
- [reference/TROUBLESHOOTING.md](reference/TROUBLESHOOTING.md) — Splotches, flicker, fireflies, OOM, slow renders
- [templates/](templates/) — Starter scripts (configure ROP, batch render, texture processing)

## Relation to Other Skills

- **`hou-python`** — use HOM Python to script the Redshift ROP, batch renders, and wedges. This skill assumes that scripting and focuses on *what to set*.
- **`hou-vex`** — VEX drives geometry/attributes the renderer consumes (e.g. `Cd`, `pscale`, custom AOV attributes).
