# Synthesis Reference — SuperCollider Sound Design Skill

This file covers the core synthesis territories: FM/additive/subtractive, granular/microsound,
and physical modeling. Use these techniques as building blocks — and mix them fearlessly.

---

## Table of Contents
1. [Subtractive Synthesis](#1-subtractive-synthesis)
2. [Additive Synthesis](#2-additive-synthesis)
3. [FM Synthesis](#3-fm-synthesis)
4. [Granular / Microsound](#4-granular--microsound)
5. [Physical Modeling & Waveguide](#5-physical-modeling--waveguide)
6. [Envelope Design](#6-envelope-design)
7. [Modulation Sources](#7-modulation-sources)
8. [Mixing Synthesis Approaches](#8-mixing-synthesis-approaches)

---

## 1. Subtractive Synthesis

The model: a spectrally rich source, shaped by filters and envelopes.

### Oscillator Sources

```supercollider
// Sawtooth — harmonically dense, bright, classic analog feel
Saw.ar(freq)

// Pulse with variable width — width controls timbre, 0.5 = square wave
Pulse.ar(freq, width: LFTri.kr(0.3).range(0.1, 0.9))

// Variable shape with crossfading: triangle→sawtooth
VarSaw.ar(freq, iphase: 0, width: 0.5)

// Band-limited impulse train — all harmonics equal amplitude up to a cutoff
Blip.ar(freq, numharm: 8)

// Stacked detuned saws — the classic "supersaw" / orchestral pad
(
SynthDef(\superSaw, { |freq = 220, detune = 0.08, amp = 0.2, out = 0|
    var sig = Mix.fill(7, { |i|
        var detuneFactor = (i - 3) * detune * (1 + (i * 0.03));
        Saw.ar(freq * (1 + detuneFactor))
    });
    sig = sig / 7; // normalize
    Out.ar(out, sig ! 2 * amp);
}).add;
)
```

### Filter Topology

```supercollider
// Classic low-pass with resonance — the core of subtractive sound shaping
RLPF.ar(sig, cutoff, rq: 0.3)  // rq = 1/Q, lower = more resonant

// Moog-style ladder filter — warmer saturation characteristic
MoogFF.ar(sig, cutoff, gain: 1.5)

// Band-pass for formant-like tones
BPF.ar(sig, centerFreq, bw: 0.3)  // bw = bandwidth/centerFreq

// Resonant comb for metallic "ringing"
Resonz.ar(sig, freq, bw: 0.01)  // very narrow bandwidth = long ring

// Formant filter stack — vowel-like resonances
(
var sig = WhiteNoise.ar;
var formants = [800, 1150, 2900];  // approximate "a" vowel
var bws = [80, 90, 120];
sig = Mix(formants.collect({ |f, i|
    BPF.ar(sig, f, bws[i]/f) * 0.3
}));
)

// State-variable filter — one input, simultaneous LP/HP/BP outputs
// (SC doesn't have SVF built-in, but you can fake it with cascaded filters)
```

### Envelope-Controlled Filter (the classic sweep)
```supercollider
SynthDef(\subLead, { |freq = 440, cutBase = 200, cutMul = 4000,
                      atk = 0.01, dec = 0.3, sus = 0.5, rel = 0.5,
                      amp = 0.3, out = 0|
    var env    = EnvGen.kr(Env.adsr(atk, dec, sus, rel), doneAction: Done.freeSelf);
    var fltEnv = EnvGen.kr(Env.adsr(0.005, dec * 0.7, sus * 0.6, rel), doneAction: 0);
    var sig    = Saw.ar([freq, freq * 1.007]);  // slight stereo detune
    sig = MoogFF.ar(sig, cutBase + (fltEnv * cutMul), gain: 1.8);
    sig = sig * env * amp;
    Out.ar(out, sig);
}).add;
```

---

## 2. Additive Synthesis

Building sound from sine partials. Gives you fine-grained control over timbre.
More computationally demanding but sonically precise.

### Klang — Resonant Partials from Arrays

```supercollider
// Klang takes [freqs, amplitudes, phases] as arrays
// Perfect for bell-like or metallic tones
SynthDef(\bellKlang, { |freq = 440, amp = 0.5, dur = 3, out = 0|
    var partialRatios  = [1, 2.756, 5.404, 8.933, 11.45, 14.83];
    var partialAmps    = [1, 0.67, 0.35, 0.12, 0.07, 0.03];
    var partialTimes   = [dur, dur*0.8, dur*0.6, dur*0.4, dur*0.3, dur*0.2];
    var sig = Klang.ar(`[
        partialRatios * freq,
        partialAmps,
        partialTimes.collect({ |t| 0.0 })  // initial phases
    ]);
    // Envelope for the overall body
    var env = EnvGen.kr(
        Env([0, 1, 0], [0.002, dur], [1, -4]),
        doneAction: Done.freeSelf
    );
    Out.ar(out, Pan2.ar(sig * env * amp, 0));
}).add;
```

### Manual Additive — for fine timbral control
```supercollider
SynthDef(\organoid, { |freq = 440, amp = 0.3, drawbar1 = 1, drawbar2 = 0.5,
                       drawbar4 = 0.25, vibDepth = 0.005, vibRate = 6, out = 0|
    var vib  = SinOsc.kr(vibRate, mul: vibDepth);  // vibrato
    var f    = freq * (1 + vib);
    var sig  = (SinOsc.ar(f * 1,     mul: drawbar1) +
                SinOsc.ar(f * 2,     mul: drawbar2) +
                SinOsc.ar(f * 4,     mul: drawbar4) +
                SinOsc.ar(f * 8,     mul: drawbar4 * 0.5) +
                SinOsc.ar(f * 1.498, mul: drawbar2 * 0.3));  // slightly inharmonic 5th
    sig = sig / 4;
    Out.ar(out, (sig ! 2) * amp);
}).add;
```

### Spectral morphing via partial amplitude LFOs
```supercollider
// Animate individual partials — the timbre "breathes"
SynthDef(\breathingPartials, { |freq = 110, amp = 0.3, out = 0|
    var n      = 12;  // number of partials
    var rates  = Array.fill(n, { ExpRand(0.05, 0.4) });
    var phases = Array.fill(n, { Rand(0, 2pi) });
    var sig = Mix.fill(n, { |i|
        var amp_i = LFNoise1.kr(rates[i], 0.5, 0.5);  // 0–1 amplitude flutter
        SinOsc.ar(freq * (i + 1), 0, amp_i / n)
    });
    Out.ar(out, (sig ! 2) * amp);
}).add;
```

---

## 3. FM Synthesis

Frequency Modulation: a modulator oscillator's output is added to a carrier's frequency.
Even simple 2-operator FM generates a rich, complex spectrum. The key parameters:
- **Carrier frequency (C)** — the perceived pitch
- **Modulator frequency (M)** — determines which sideband series appear
- **Modulation index (I)** — controls spectral complexity/brightness (I = deviation/M)
- **C:M ratio** — determines harmonic vs. inharmonic character
  - Integer ratios (1:1, 1:2, 2:3) → harmonic, musical
  - Non-integer ratios (1:1.414, 1:π) → inharmonic, metallic, bell-like

```supercollider
// Manual 2-op FM — fundamental building block
SynthDef(\fm2op, {
    |freq = 220, cmRatio = 1.0, modIndex = 3, amp = 0.3, atk = 0.01, rel = 1.5, out = 0|
    var mFreq    = freq * cmRatio;
    var devHz    = mFreq * modIndex;           // modulation depth in Hz
    var modSig   = SinOsc.ar(mFreq, 0, devHz); // the modulator
    var car      = SinOsc.ar(freq + modSig);   // carrier with FM input
    var env      = EnvGen.kr(Env.perc(atk, rel, curve: -4), doneAction: Done.freeSelf);
    // Envelope the mod index for evolving timbre — brighter attack, purer decay
    var indexEnv = EnvGen.kr(Env.perc(0.005, rel * 0.8, level: 1, curve: -3));
    var car2     = SinOsc.ar(freq + (modSig * indexEnv));
    Out.ar(out, Pan2.ar(car2 * env * amp, 0));
}).add;

// PMOsc — phase modulation (functionally similar to FM, different math)
// PMOsc.ar(carfreq, modfreq, pmindex, modphase)
SynthDef(\pmBell, { |freq = 880, modRatio = 2.756, pmIndex = 3.5, amp = 0.4,
                     dur = 2, out = 0|
    var sig = PMOsc.ar(freq, freq * modRatio, pmIndex * EnvGen.kr(Env.perc(0.01, dur)));
    var env = EnvGen.kr(Env.perc(0.01, dur, curve: -5), doneAction: Done.freeSelf);
    Out.ar(out, Pan2.ar(sig * env * amp, 0));
}).add;
```

### DX7-style 4-operator stack (operators in series)
```supercollider
SynthDef(\fm4op, { |freq = 220, amp = 0.3, index1 = 5, index2 = 3, index3 = 1,
                    cmRatio1 = 1, cmRatio2 = 2, cmRatio3 = 0.5,
                    atk = 0.02, dec = 0.5, sus = 0.3, rel = 1.0, out = 0|
    var env   = EnvGen.kr(Env.adsr(atk, dec, sus, rel), doneAction: Done.freeSelf);
    var iEnv  = EnvGen.kr(Env.adsr(0.005, dec * 0.6, sus * 0.4, rel * 0.7));
    // Op 4 → Op 3 → Op 2 → Carrier (Op 1)
    var op4   = SinOsc.ar(freq * cmRatio3, 0, freq * cmRatio3 * index3 * iEnv);
    var op3   = SinOsc.ar(freq * cmRatio2 + op4, 0, freq * cmRatio2 * index2 * iEnv);
    var op2   = SinOsc.ar(freq * cmRatio1 + op3, 0, freq * cmRatio1 * index1 * iEnv);
    var car   = SinOsc.ar(freq + op2);
    Out.ar(out, Pan2.ar(car * env * amp, 0));
}).add;

// Feedback FM — SinOscFB for metallic, raspy tones
SynthDef(\fmFeedback, { |freq = 110, feedback = 0.8, amp = 0.3, rel = 2, out = 0|
    var sig = SinOscFB.ar(freq, feedback);
    var env = EnvGen.kr(Env.perc(0.01, rel, curve: -3), doneAction: Done.freeSelf);
    sig = LeakDC.ar(sig);  // always LeakDC with feedback
    Out.ar(out, Pan2.ar(sig * env * amp, 0));
}).add;
```

### FM Recipes (C:M ratios and their characters)
```
C:M = 1:1    → hollow, wood-like, clarinet family
C:M = 1:2    → bright, brassy
C:M = 1:3    → nasal, oboe-like
C:M = 2:1    → octave above with sidebands — bell quality
C:M = 1:1.41 → inharmonic — metallic, gong-like
C:M = 1:π    → very inharmonic — noisy, industrial
modIndex 0-1 → near-pure sine, subtle color
modIndex 1-4 → moderate harmonic complexity, timbral interest
modIndex 5+  → dense, harsh, clangorous spectrum
```

---

## 4. Granular / Microsound

Granular synthesis decomposes sound into thousands of tiny grains (typically 10–200ms).
These clouds of micro-events create textures impossible with conventional synthesis.
Following Curtis Roads and Alberto de Campo's framework from the SC Book:

- **Synchronous granular** — grains at regular intervals → pitched, buzzy
- **Asynchronous / quasi-synchronous** — scattered grain density → cloud, texture
- **Grain parameters**: duration, envelope shape, pitch, start position, pan scatter

```supercollider
// GrainSin — sine grain clouds (no buffer needed)
SynthDef(\sinCloud, {
    |density = 40, grainDur = 0.1, freq = 300, freqSpread = 0.02,
     amp = 0.4, panSpread = 0.7, out = 0|
    var trigger  = Dust.ar(density);      // async random triggers
    var freqJit  = freq * (1 + LFNoise2.kr(3, freqSpread));  // pitch scatter
    var sig      = GrainSin.ar(
        numChannels: 2,
        trigger:     trigger,
        dur:         grainDur + LFNoise2.kr(2, grainDur * 0.3), // dur jitter
        freq:        freqJit,
        pan:         LFNoise2.kr(density, panSpread)
    );
    Out.ar(out, sig * amp);
}).add;

// TGrains — granular from a buffer (for live granular on recordings)
SynthDef(\bufGranular, {
    |buf = 0, density = 30, pos = 0, posSpread = 0.1,
     rate = 1, rateSpread = 0.05, grainDur = 0.12,
     amp = 0.5, pan = 0, out = 0|
    var posJitter  = LFNoise1.kr(density * 0.1, posSpread);
    var rateJitter = rate * (1 + LFNoise2.kr(5, rateSpread));
    var trig       = Impulse.ar(density) + Dust.ar(density * 0.2); // hybrid trigger
    var sig = TGrains.ar(
        numChannels: 2,
        trigger:    trig,
        bufnum:     buf,
        rate:       rateJitter,
        centerPos:  (pos + posJitter) * BufDur.kr(buf),
        dur:        grainDur,
        pan:        LFNoise2.ar(density * 0.5, 0.8),
        amp:        1,
        interp:     2
    );
    Out.ar(out, sig * amp);
}).add;

// GrainFM — granular FM (each grain is an FM tone — maximum textural richness)
SynthDef(\fmCloud, {
    |density = 25, grainDur = 0.08, carFreq = 200, carSpread = 0.15,
     modRatio = 1.5, modIndex = 4, indexSpread = 2,
     amp = 0.4, out = 0|
    var trig    = Dust.ar(density);
    var carJit  = carFreq  * (1 + LFNoise2.kr(4, carSpread));
    var idxJit  = modIndex + LFNoise2.kr(3, indexSpread);
    var sig = GrainFM.ar(
        numChannels: 2,
        trigger:     trig,
        dur:         grainDur + LFNoise2.kr(2, 0.04),
        carfreq:     carJit,
        modfreq:     carJit * modRatio,
        index:       idxJit,
        pan:         LFNoise2.ar(density, 0.9)
    );
    Out.ar(out, sig * amp);
}).add;
```

### Microsound Compositional Approaches (from de Campo's chapter)

```supercollider
// Grain density envelope — from silence to dense cloud and back
// Use a Routine to modulate density over time:
(
var d = Synth(\sinCloud, [density: 1, freq: 200]);
Routine({
    [1, 5, 20, 60, 100, 60, 20, 5, 1].do { |dens|
        d.set(\density, dens);
        0.5.wait;
    };
    d.free;
}).play;
)

// Pitch clouds — frequency drift creates beating textures
SynthDef(\pitchCloud, {
    |centerFreq = 440, spread = 0.08, density = 20, grainDur = 0.15,
     drift = 0.3, amp = 0.4, out = 0|
    var freqWander = centerFreq * (1 + LFNoise2.kr(drift, spread));
    var trig  = Dust.ar(density);
    var sig = GrainSin.ar(2, trig, grainDur,
        freq: freqWander,
        pan: LFNoise1.kr(density * 0.2, 1.0)
    );
    Out.ar(out, sig * amp);
}).add;

// Warp1 — granular time-stretching of buffers (time ≠ pitch)
SynthDef(\timeStretch, {
    |buf = 0, rate = 1, pos = 0, grainDur = 0.15,
     overlaps = 4, amp = 0.5, out = 0|
    var sig = Warp1.ar(
        numChannels: 2,
        bufnum:      buf,
        pointer:     Line.kr(pos, pos + 1, BufDur.kr(buf) / rate),
        freqScale:   rate,
        windowSize:  grainDur,
        envbufnum:   -1,  // default window
        overlaps:    overlaps,
        windowRand:  0.1,
        interp:      2
    );
    Out.ar(out, sig * amp);
}).add;
```

---

## 5. Physical Modeling & Waveguide

Physical modeling captures the essential mechanic of real instruments:
excitation + resonating body. The excitation can be an impulse, noise burst, or continuous
drive; the body is typically a delay-line (waveguide) or resonator filter bank.

Chion's concept of **materializing sound indices** — the friction, impact, grain of a surface —
is directly served by physical modeling. Pluck a virtual string; the *attack texture* tells you
everything about what you imagine struck it.

### Karplus-Strong — plucked string
```supercollider
SynthDef(\karplusStrong, {
    |freq = 220, decay = 5, amp = 0.5, brightness = 0.5, out = 0|
    // The delay length = 1/freq; filter coefficient controls brightness
    var excite  = WhiteNoise.ar(0.5);   // initial excitation burst
    var delTime = freq.reciprocal;
    // CombL for the waveguide — feedback = tone-filtering approximation
    var string  = CombL.ar(excite * EnvGen.kr(Env.perc(0, 0.003)), // very short excite
                           delTime, delTime,
                           decay);
    // Low-pass in the loop — higher coeff = brighter, longer sustain
    var filtered = LPF.ar(string, freq * (1 + (brightness * 8)));
    var env = EnvGen.kr(Env.perc(0.001, decay * 1.5), doneAction: Done.freeSelf);
    Out.ar(out, Pan2.ar(filtered * env * amp, 0));
}).add;

// More accurate implementation using Pluck UGen
SynthDef(\pluckedString, {
    |freq = 440, decay = 3, coef = 0.5, amp = 0.5, out = 0|
    var excite = PinkNoise.ar;
    var trig   = Impulse.kr(0);  // one-shot trigger
    var sig    = Pluck.ar(
        in:         excite,
        trig:       trig,
        maxdelaytime: 0.02,
        delaytime:  freq.reciprocal,
        decaytime:  decay,
        coef:       coef  // all-pass coeff — tunes brightness/decay
    );
    var env = EnvGen.kr(Env.perc(0.001, decay + 1), doneAction: Done.freeSelf);
    Out.ar(out, Pan2.ar(sig * env * amp, 0));
}).add;
```

### Klank — resonator bank (modal synthesis)
```supercollider
// Klank is ideal for struck/bowed/blown resonant objects
// Each resonance spec: [freqs, amps, ring times]
SynthDef(\metalPlate, {
    |freq = 440, impAmp = 0.8, amp = 0.4, out = 0|
    var ratios = [1, 2.04, 3.11, 4.27, 5.83, 7.12, 9.44, 11.3, 14.5];
    var amps   = [1, 0.8, 0.6, 0.4, 0.3, 0.2, 0.1, 0.07, 0.04];
    var times  = ratios.collect({ |r| 4.0 / r });  // higher partials decay faster
    var excite = Impulse.ar(0) * impAmp;            // single impulse strike
    var sig    = Klank.ar(`[ratios * freq, amps, times], excite);
    var env    = EnvGen.kr(Env.perc(0.001, times[0] + 1), doneAction: Done.freeSelf);
    Out.ar(out, Pan2.ar(sig * env * amp, 0));
}).add;

// Resonator with continuous excitation — bowed effect
SynthDef(\bowedResonator, {
    |freq = 220, bowPressure = 0.3, amp = 0.3, out = 0|
    var bow = BrownNoise.ar(bowPressure);
    // High-pass to remove sub-bass rumble from bow noise
    bow     = HPF.ar(bow, 80);
    var ratios = [1, 2.97, 5.02, 7.13];
    var amps   = [1, 0.3, 0.15, 0.07];
    var times  = [8, 4, 2, 1];
    var sig    = Klank.ar(`[ratios * freq, amps, times], bow);
    Out.ar(out, (sig ! 2) * amp);
}).add;
```

### Delay-based resonators — tubes, rooms, membranes
```supercollider
// Tuned comb filter as tube resonance
SynthDef(\tubeTone, {
    |freq = 220, fbCoef = 0.9, exciteAmp = 0.3, amp = 0.4, out = 0|
    var excite   = Dust.ar(freq * 0.5) * exciteAmp;  // breath-like excitation
    var delTime  = freq.reciprocal;
    var tube     = CombC.ar(excite, 0.05, delTime, 10 * fbCoef);
    tube         = RLPF.ar(tube, freq * 3, 0.5);  // reed/lip filter
    Out.ar(out, (tube ! 2) * amp);
}).add;
```

---

## 6. Envelope Design

Envelopes in SC are first-class objects. Use them as creative tools, not just on/off switches.

```supercollider
// Percussive — attack time, decay/release time
Env.perc(attackTime: 0.01, releaseTime: 1.5, level: 1, curve: -4)
//  curve: -4 (exponential decay), 0 (linear), 4 (exponential rise-then-fall)

// ADSR — sustaining sounds triggered by gate
Env.adsr(attackTime: 0.1, decayTime: 0.3, sustainLevel: 0.6, releaseTime: 1.0)

// Custom shapes — array of [levels], [times], [curves]
Env([0, 1, 0.7, 0.3, 0], [0.01, 0.1, 0.4, 0.8], [-1, -2, -3, -4])
// reads as: 0→1 in 0.01s, 1→0.7 in 0.1s, 0.7→0.3 in 0.4s, 0.3→0 in 0.8s

// Sustained with two-stage decay (like a piano)
Env([0, 1, 0.4, 0.4, 0], [0.005, 0.08, 0, 2], [-1, -3, 0, -4], 3)
// Level 3 is the sustain node (index)

// Smooth exponential bow — for slow attacks that feel like breath
Env([0.001, 1, 0.001], [2, 4], \exp)  // use \exp for natural fade-in/out

// Using an envelope to control filter cutoff (different shape than amplitude)
var fEnv = EnvGen.kr(Env.perc(0.003, rel, curve: -6), doneAction: 0);
var sig  = RLPF.ar(source, baseFreq + (fEnv * (cutTop - baseFreq)), 0.3);
```

---

## 7. Modulation Sources

The difference between a static and a living sound is often just well-chosen modulation.

```supercollider
// LFO types and their characters
LFSaw.kr(rate)          // sawtooth — ramp up
LFTri.kr(rate)          // triangle — smooth oscillation
LFPulse.kr(rate, 0, 0.5) // square wave — binary modulation, clicks
SinOsc.kr(rate)         // smooth sine — natural vibrato/tremolo
LFNoise0.kr(rate)       // random stepped — unpredictable jumps
LFNoise1.kr(rate)       // random interpolated — smooth random drift
LFNoise2.kr(rate)       // smooth random (quadratic) — most natural-sounding
Dust.kr(rate)           // random impulses — stochastic triggers

// Frequency modulation of an LFO (LFO that speeds up/slows down)
LFSaw.kr(SinOsc.kr(0.1).range(0.5, 4))

// Using SinOsc.range() for convenience
var lfo = SinOsc.kr(0.3).range(200, 4000);  // oscillate between values
var lfo2 = SinOsc.kr(0.5, mul: 0.5, add: 0.5);  // 0 to 1 range

// Envelope follower — use amplitude of signal as modulation
var envF = Amplitude.kr(inSig, 0.01, 0.1).range(200, 4000);

// TDuty / Demand-rate patterns as modulators (advanced)
var cutMod = Demand.kr(Impulse.kr(4), 0, Dseq([200, 800, 400, 1600], inf));
```

---

## 8. Mixing Synthesis Approaches

Real sounds rarely use a single technique. Some powerful combinations:

```supercollider
// FM + granular: granular FM cloud (see GrainFM above)

// Subtractive + physical: filtered Klank → noisy, timbral
SynthDef(\roughMetal, { |freq = 300, amp = 0.3, out = 0|
    var excite = WhiteNoise.ar(0.3);
    var body   = Klank.ar(`[[1, 2.3, 4.7, 7.1], [1, 0.5, 0.3, 0.1], [2, 1, 0.5, 0.3]], excite);
    var shaped = BPF.ar(body, freq, 0.5);  // subtractive shaping over the resonances
    var env    = EnvGen.kr(Env.perc(0.01, 3), doneAction: Done.freeSelf);
    Out.ar(out, (shaped ! 2) * env * amp);
}).add;

// Additive + FM: FM carrier through additive partials (sideband sculpting)
// Start with FM output, then selectively emphasize partials with BPF banks

// Granular + reverb: grains + long reverb = crystalline ambient spaces
// (see dsp_effects.md for reverb/FX techniques)
```
