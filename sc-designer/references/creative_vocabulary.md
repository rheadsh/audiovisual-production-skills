# Creative Vocabulary Reference — SuperCollider Sound Design Skill

This file bridges the perceptual and the technical. It translates between the language
of listening — how sounds feel, move, breathe, fail, and transform — and the language
of SuperCollider. Draw on this whenever a user describes a sonic idea in experiential
rather than technical terms, or when you want to elevate a technically correct patch
into a musically meaningful one.

---

## Michel Chion's Framework Applied to SC

Michel Chion, the French composer and theorist, developed a rich vocabulary for
listening to and thinking about sound beyond its literal source. His key ideas directly
inform sound design decisions:

### Three Modes of Listening

**1. Causal listening** — hearing a sound and identifying what made it.
In SC terms: when designing a "plucked string," the attack noise, decay shape, and
resonance pattern all signal "plucked string" to causal perception.
- Attend to the **attack texture** — it carries the most causal information
- Materializing sound indices live here: the scrape, the breath, the bounce

**2. Semantic listening** — listening for a code or symbolic meaning (language, music).
In SC terms: the pitch, rhythm, and harmonic context of events. How Pbind's
`\degree`, `\dur`, and `\amp` constructions create syntax and grammar.
- Melody = semantic structure
- Rhythm = metric syntax
- Harmonic progression = grammatical argument

**3. Reduced listening (écoute réduite)** — attending to sound as an object in itself,
bracketing source and meaning. The sound's own mass, grain, texture, movement.
In SC terms: this is where synthesis design lives. Not "is this a cello?" but
"what is the density of this texture, the spectral center of mass, the movement
quality?" This is Pierre Schaeffer's heritage brought into SC.

**→ As a designer, move between all three modes:**
- Build causal logic into attacks and decays (materializing indices)
- Build semantic structure through patterns and harmonic organization
- Pursue reduced qualities — the intrinsic texture — as primary design goals

---

### Materializing Sound Indices

Chion describes these as the micro-qualities that make a sound feel physically
grounded: the graininess of a bow on strings, the breath before a note, the
impact of a hammer, the friction of a surface.

**In SC, materializing indices manifest as:**

```supercollider
// Attack transient noise — makes a physical strike feel real
var strike = WhiteNoise.ar * EnvGen.kr(Env.perc(0, 0.004, curve: -8));
var body   = Klank.ar(`[[440, 880, 1320], [1, 0.5, 0.2], [2, 1, 0.5]], strike);

// Breath — random amplitude and pitch fluctuation before onset
var breath = BrownNoise.ar(0.1) * SinOsc.kr(0.3);  // barely perceptible tremor
var onset  = Pulse.ar(220 + (breath * 5));  // frequency "unstable" before settling

// Bow noise — sustained scraping texture + resonance
var friction = BandpassedNoise = BPF.ar(PinkNoise.ar, 800, 0.2) * 0.2;
var string   = CombL.ar(friction, 0.01, 220.reciprocal, 4);

// Granular texture of surface — TGrains on a buffer gives material grain
// Even using GrainSin with high frequency spread implies a granular surface
```

**Designing a sound with materializing indices:**
1. What physical material is being activated? (wood, metal, air, water, membrane)
2. What is the excitation mechanism? (strike, rub, blow, pluck, vibrate)
3. How does the material respond over time? (short decay = rigid; long = resonant)
4. What micro-textures should be present? (grain, roughness, vibrato, formant)

---

## Sonic Texture Vocabulary

Use this vocabulary to describe sounds in your commentary and to decode user requests:

### Mass and Density
- **Sparse** → low event density; Dust-triggered grains; silence as material
- **Dense** → overlapping grains; high harmonics; close voicings; noise components
- **Massive** → sub-bass; long reverb; slow attack; spectral weight
- **Weightless** → pure sines; high register; short attack; little reverb

### Surface and Texture
- **Smooth** → sine waves; slow LFO modulation; linear envelopes; gentle filtering
- **Granular** → TGrains; GrainSin; Warp1; any sound composed of micro-events
- **Rough** → white/pink noise; FM at high index; distortion; BrownNoise excitation
- **Crystalline** → clear attack; glassy decay; high partials; bell-like FM ratios
- **Fuzzy** → FM feedback; bitcrusher; wavefolder; parallel saturation
- **Powdery** → extremely fine-grained granular; soft Dust triggers; gentle

### Movement Quality
- **Flowing** → slow Lissajous LFO patterns; Pgeom for gradual tempo; legato
- **Jerky** → LFNoise0 (stepped random); staccato patterns; irregular Prand durations
- **Pulsing** → Impulse-triggered; regular rhythm; amplitude tremolo
- **Drifting** → LFNoise2 on multiple parameters; long pattern loop cycles; slow automation
- **Erupting** → fast attack; amplitude burst; Dust at high density for short bursts
- **Dissolving** → decaying amplitude; filter closing; granular dispersion

### Spatial Character
- **Close** → little reverb; dry signal; mid-high presence; clear transients
- **Distant** → HPF on dry + heavy reverb; pre-delay; frequency blur
- **Wide** → stereo spread; chorus; PitchShift detune; pan scatter in patterns
- **Enclosed** → short reverb; comb filter resonance; boxiness
- **Vast** → GVerb with long revtime; Warp1 clouds; spectral smear

### Time Character
- **Suspended** → PV_MagFreeze; very long sustain; no rhythm; no pattern
- **Urgent** → short dur in patterns; high density; fast attack; little sustain
- **Meditative** → long dur; low density; consonant harmonics; slow LFO
- **Stuttering** → Latch at rhythmic rate; bitcrush; granular with very short dur

---

## Translating User Requests to SC Approaches

| User says... | SC reads as... |
|---|---|
| "warm pad" | Stacked detuned saws + RLPF with gentle sweep + FreeVerb |
| "glitchy" | Granular + Dust triggers + Latch + Prand irregular dur |
| "ethereal" | GrainSin cloud + PitchShift harmonizer + long GVerb |
| "aggressive" | FM at high index + distortion + short reverb + fast Pbind dur |
| "breathing texture" | BrownNoise filtered through moving BPF + slow LFO depth |
| "metallic hit" | Klank resonator + impulse excitation + amplitude env |
| "underwater" | Heavy LPF + FreeVerb + slow chorus + spectral smear |
| "glass" | High-ratio FM (C:M=1:3.756) + short Klank ring + delicate amp |
| "industrial" | CombC feedback + distortion + irregular Prand patterns |
| "lush" | Supersaw + chorus + GVerb + layered Pdefs at low amplitudes |
| "drone" | Sustained SynthDef + very slow Tdef automation + long Pdef dur |
| "crystalline" | GrainSin low-density + bell FM (C:M=2:1) + PV_MagFreeze moments |
| "nervous" | Fast irregular Prand + LFNoise0 modulation + staccato legato |

---

## Compositional Gestures

These are arc-shapes — patterns of change over time that have musical/narrative meaning.

### Buildup
Start sparse and dense upward: increase grain density, open filter, add voices.
```supercollider
// In a Routine:
var d = Synth(\grainCloud, [density: 2, cutoff: 300]);
Routine({
    20.do { |i|
        d.set(\density, (2 * (1.15 ** i)).clip(2, 80));
        d.set(\cutoff,  300 + (i * 180));
        0.5.wait;
    };
}).play;
```

### Dissolution
Start dense, let it fall apart: increase pitch dispersion, slow decay, reduce density.
```supercollider
var d = Synth(\grainCloud, [density: 60, freqSpread: 0.01]);
Routine({
    15.do { |i|
        d.set(\density,    60 - (i * 3.5));
        d.set(\freqSpread, 0.01 + (i * 0.03));
        d.set(\grainDur,   0.1 + (i * 0.05));
        0.7.wait;
    };
}).play;
```

### Eruption
A sudden burst of energy followed by decay:
```supercollider
Synth(\impact, [amp: 0.9]);  // loud impulse-excited resonator
Synth(\aftermath, [amp: 0.1, reverb: 0.9]);  // long quiet tail
```

### Phase Drift
Two nearly-identical streams gradually fall out and back into sync (Reich-style):
See `patterns_events.md` → Pattern Recipes → Minimal Repetitive Music.

### Accumulation
Add voices one at a time, building density without increasing tempo:
```supercollider
Routine({
    var pdefs = [\v1, \v2, \v3, \v4];
    pdefs.do { |name|
        Pdef(name).play;
        4.wait;  // add a new voice every 4 seconds
    };
}).play;
```

---

## The Concept of Silence in SC

In SuperCollider, silence is not the absence of code — it's a positive compositional
choice. John Cage said sound needs silence to be heard. In SC terms:

- `Rest()` in Pbind — a structural rest with exact duration
- Low `\density` in granular synthesis — space between events is itself texture
- `\amp, 0` with long `\sustain` — notes that barely exist
- `PV_MagFreeze` holding a decaying spectrum — a sound held in aspic
- `\dur, Prand([0.5, 1, 2, 4], inf)` — variable silence; unpredictable breath

Good generative music knows when to leave space. Always ask: does this event need
to exist, or would its absence be more powerful?

---

## Thinking About Time as Material

SuperCollider's pattern system makes time as malleable as pitch or amplitude.
Some ways to work with time as primary material:

**Slowing time:** `\dur, Pgeom(0.25, 1.1, 16)` — each event 10% longer than the last.
Creates a feeling of deceleration, weight gaining, arrival.

**Compressing time:** `\dur, Pgeom(2.0, 0.9, 16)` — exponential acceleration.
Urgency, inevitability, countdown.

**Layered tempos:** Multiple Pdefs on different TempoClock instances create polytempo.
The interaction of 3:2, 4:3 rhythmic layers creates complex but intelligible texture.

**Rhythmic blurring:** `\dur, Pwhite(0.1, 0.4)` — all events roughly similar but none exact.
Neither steady pulse nor free time — a kind of temporal granularity.

**The long form:** Don't be afraid of `\dur, Prand([30, 45, 60], inf)` — events spaced
minutes apart. This is the tempo of a landscape, not a song.

---

## A Note on Code as Score

In the tradition of extended notation (Cardew, Feldman, Cage), your SuperCollider
code *is* a score — not just the result of running the score. Approach each SynthDef
as a definition of a sonic type; each Pbind as a description of how that type moves
through time; each effects chain as the acoustic space in which it exists.

When the code is read later (by you or collaborators), it should communicate *intent*,
not just mechanism. Naming a SynthDef `\dustCloud` instead of `\granular1` is a
compositional act. Naming a Pbind's comment `// dissolution phrase` shapes how the
code is understood, modified, and performed in the future.

Write code that wants to be re-run, modified, and extended. The best SC patches are
living documents.
