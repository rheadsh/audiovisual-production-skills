# DSP & Effects Reference — SuperCollider Sound Design Skill

Effects are not decorations — they are part of the instrument. A reverb tail shapes
a sound's sense of physical space; a delay creates rhythm; distortion adds harmonic
density and aggression. Think of every effect as an extension of the synthesis architecture.

---

## Table of Contents
1. [Signal Flow Architecture](#1-signal-flow-architecture)
2. [Filter Cookbook](#2-filter-cookbook)
3. [Dynamics — Compression, Limiting, Gating](#3-dynamics)
4. [Reverb & Spatial Effects](#4-reverb--spatial-effects)
5. [Delay & Echo Effects](#5-delay--echo-effects)
6. [Distortion & Waveshaping](#6-distortion--waveshaping)
7. [Pitch & Frequency Effects](#7-pitch--frequency-effects)
8. [FFT / Spectral Processing](#8-fft--spectral-processing)
9. [Feedback Synthesis](#9-feedback-synthesis)
10. [Effects Bus Routing in SC](#10-effects-bus-routing)
11. [Complete Effects Chain Examples](#11-complete-effects-chains)

---

## 1. Signal Flow Architecture

Every signal needs to pass through well-defined stages. Think of signal flow as a
directed graph: source → shaping → spatialization → effects → master.

```
[Source(s)] → [Gain/Clip staging] → [Filtering] → [Modulation effects]
           → [Time-based effects] → [Spatial] → [Master limiting] → Out
```

**Bus routing in SuperCollider:**

```supercollider
// Effects buses (audio buses for routing)
s.waitForBoot {
    ~fxBus  = Bus.audio(s, 2);  // stereo effects send
    ~dryBus = Bus.audio(s, 2);  // dry path (optional)

    // Effects processor (reads from bus, writes to hardware out)
    ~fxSynth = SynthDef(\reverb, {
        var in  = In.ar(~fxBus, 2);
        var wet = GVerb.ar(in.sum, 40, 6);
        Out.ar(0, wet * 0.4 + in * 0.6);
    }).play(addAction: \addToTail);

    // Instruments route to bus via \out key in Pbind
    Pbind(\instrument, \lead, \out, ~fxBus, ...).play;
}

// SynthDef that supports both dry and wet outputs:
SynthDef(\withSend, { |out = 0, fxOut = 0, fxAmt = 0.3, ...|
    var sig = // ... synthesis ...
    Out.ar(out, sig);
    Out.ar(fxOut, sig * fxAmt);  // send to effects bus
}).add;
```

**Node ordering** — critical for effects to work:
```supercollider
// Group setup: instruments before effects
~sourceGroup = Group.new;
~fxGroup     = Group.after(~sourceGroup);

SynthDef(\myFx, { |in = 0, out = 0|
    Out.ar(out, FreeVerb.ar(In.ar(in, 2)));
}).play(~fxGroup);
```

---

## 2. Filter Cookbook

Filters shape the timbral spectrum. Beyond simple cutoff/Q, think of filters as
**resonant bodies** — a peaked BPF mimics the formant of a voice or instrument body.

```supercollider
// Low-pass: roll off highs — warmth, distance, underwater
LPF.ar(sig, cutoff)                          // 12dB/oct Butterworth
RLPF.ar(sig, cutoff, rq: 0.3)               // resonant — rq: 1/Q (lower = more ring)
MoogFF.ar(sig, cutoff, gain: 2.0)            // ladder filter — analog warmth, self-oscillates!

// High-pass: roll off lows — clarity, thinness, air
HPF.ar(sig, cutoff)
RHPF.ar(sig, cutoff, rq: 0.5)

// Band-pass: isolate a region — nasal, telephone, formant
BPF.ar(sig, centerFreq, bw: 0.2)            // bw = bandwidth/centerFreq
Resonz.ar(sig, freq, bw: 0.005)             // very narrow resonance = long ring

// Band-reject / notch: remove a region
BRF.ar(sig, notchFreq, bw: 0.2)

// Formant filter — vowel-like resonances
// Stack BPFs to model vowel spaces:
SynthDef(\vowelFilter, { |in = 0, vowel = 0, out = 0|
    // Approximate vowel formants: a, e, i, o, u
    var formants = [
        [800, 1150, 2900],   // 'a' (ah)
        [400, 2300, 3000],   // 'e' (eh)
        [250, 1750, 2600],   // 'i' (ee)
        [500, 850, 2500],    // 'o' (oh)
        [350, 600, 2700]     // 'u' (oo)
    ];
    var bws   = [80, 90, 120];
    var fmts  = Select.kr(vowel.clip(0, 4), formants.collect(_.collect(_.kr)));
    var input = In.ar(in, 1);
    var sig   = Mix(3.collect({ |i|
        BPF.ar(input, fmts[i], bws[i] / fmts[i]) * 0.5
    }));
    Out.ar(out, sig ! 2);
}).add;

// Comb filter for flanging/phasing
CombN.ar(sig, 0.01, LFSaw.kr(0.5).range(0.001, 0.01), 0.5)

// Swept filter envelope — the iconic subtractive "filter sweep"
SynthDef(\filterSweep, { |in = 0, cutBase = 100, cutMul = 8000, res = 0.3,
                          sweepTime = 2, out = 0|
    var fEnv = EnvGen.kr(Env.perc(0.005, sweepTime, curve: -5));
    var cutoff = cutBase + (fEnv * cutMul);
    Out.ar(out, RLPF.ar(In.ar(in, 2), cutoff, res));
}).add;
```

---

## 3. Dynamics

```supercollider
// Compressor — tame peaks, increase perceived loudness
Compander.ar(sig,
    control:    sig,       // sidechain input (can be different signal)
    thresh:     0.5,       // compression starts above this level
    slopeBelow: 1.0,       // gain below threshold (1 = no expansion)
    slopeAbove: 0.25,      // gain above threshold (1/4 = 4:1 compression)
    clampTime:  0.01,      // attack
    relaxTime:  0.1        // release
)

// Limiter — hard ceiling (prevent clipping)
Limiter.ar(sig, level: 0.95, dur: 0.01)

// Gate — silence below threshold (noise gate)
Compander.ar(sig, sig,
    thresh:     0.1,
    slopeBelow: 10,   // sharp gate: sounds below threshold are strongly attenuated
    slopeAbove: 1.0,
    clampTime:  0.005,
    relaxTime:  0.2
)

// Amplitude normalization
Normalizer.ar(sig, level: 0.9, dur: 0.01)
```

---

## 4. Reverb & Spatial Effects

Reverb is the sound of space. Choose the reverb algorithm based on what kind of
space you're constructing — close and dry, vast cathedral, abstract shimmer.

```supercollider
// FreeVerb — simple, efficient Schroeder reverb
FreeVerb.ar(sig,
    mix:  0.5,    // 0 = dry, 1 = wet
    room: 0.8,    // room size (0–1)
    damp: 0.5     // high-frequency damping
)

// FreeVerb2 — stereo version
FreeVerb2.ar(sigL, sigR, mix: 0.4, room: 0.9, damp: 0.3)

// GVerb — more control, better for large spaces
GVerb.ar(sig.sum,  // mono input
    roomsize:    100,    // room size in meters
    revtime:     8,      // reverb time in seconds
    damping:     0.5,
    inputbw:     0.5,    // input bandwidth
    spread:      15,
    drylevel:    0.7,
    earlyreflevel: 0.4,
    taillevel:   0.5
)

// Reverb as synthesis — feedback delay network (manual)
SynthDef(\fdn4, { |in = 0, fb = 0.85, damp = 0.7, out = 0|
    var sig   = In.ar(in, 1);
    var d     = [0.0297, 0.0371, 0.0411, 0.0437];  // Schroeder prime delay times
    var lines = LocalIn.ar(4) * fb;
    var fed   = lines.collect({ |l, i|
        AllpassN.ar(l + sig, 0.1, d[i], d[i] * 10)
    });
    LocalOut.ar(fed);
    var wetL = Mix(fed[0::2]);
    var wetR = Mix(fed[1::2]);
    var damp_filter = [LPF.ar(wetL, 5000 * damp), LPF.ar(wetR, 5000 * damp)];
    Out.ar(out, damp_filter * 0.3 + (sig ! 2 * 0.7));
}).add;

// Convolution reverb — most realistic, uses an impulse response buffer
SynthDef(\convoReverb, { |in = 0, irBuf = 0, mix = 0.3, out = 0|
    var dry = In.ar(in, 2);
    var wet = Convolution2.ar(dry.sum, irBuf, 0, 2048) ! 2;
    Out.ar(out, XFade2.ar(dry, wet, mix * 2 - 1));
}).add;
```

---

## 5. Delay & Echo Effects

```supercollider
// Simple delay (N = no interpolation, L = linear, C = cubic)
DelayN.ar(sig, maxDelay: 1.0, delayTime: 0.25)
DelayL.ar(sig, 1.0, 0.25)   // smoother when modulating delay time
DelayC.ar(sig, 1.0, 0.25)   // cubic interpolation — best quality

// Tap delay line — multiple delays at once
var maxDel = 2.0;
var delTimes = [0.25, 0.375, 0.5, 1.0];
var delAmps  = [0.6, 0.4, 0.5, 0.3];
Mix(delTimes.collect({ |t, i|
    DelayL.ar(sig, maxDel, t) * delAmps[i]
}))

// Comb filter / echo — delay with feedback (creates pitched echoes)
CombL.ar(sig, 0.5, 0.25, decayTime: 2)

// Ping-pong delay (true stereo)
SynthDef(\pingPong, { |in = 0, delTime = 0.333, fb = 0.7, out = 0|
    var input = In.ar(in, 2);
    var d     = LocalIn.ar(2);
    var ping  = DelayL.ar(input[0] + d[1], 1, delTime);     // left → right
    var pong  = DelayL.ar(input[1] + d[0], 1, delTime * 2); // right → left (longer)
    LocalOut.ar([ping * fb, pong * fb]);
    Out.ar(out, [ping, pong] * 0.5 + input);
}).add;

// Slapback echo (very short delay: 50–120ms) — rockabilly/depth
DelayL.ar(sig, 0.2, 0.08) * 0.5 + sig

// Tape echo simulation — modulate delay time for "wow/flutter"
var wow = SinOsc.kr(0.5, mul: 0.003, add: 0.25);  // LFO on delay time
DelayL.ar(sig, 0.5, wow) * 0.6
```

---

## 6. Distortion & Waveshaping

Distortion adds harmonic richness. From warm saturation to aggressive fuzz to digital
destruction — it's all about how you clip or reshape the waveform.

```supercollider
// Soft clip — smooth saturation (warm, musical)
sig.tanh              // hyperbolic tangent — very smooth
sig.softclip          // SC built-in: f(x) = x / (1 + x.abs)

// Hard clip — aggressive limiting
sig.clip(-0.8, 0.8)

// Wavefolder — folds waveform back on itself (Buchla-style complexity)
sig.fold(-0.7, 0.7)   // creates harmonic richness without hard clipping
sig.wrap(-0.7, 0.7)   // wraps (alias-like distortion)

// Drive amplification + soft clip
(sig * drive).tanh    // increase drive for progressively richer harmonics

// Shaper UGen — uses a lookup table for arbitrary waveshaping
// First define a shaper buffer:
b = Buffer.alloc(s, 256, 1);
b.loadCollection(Array.interpolation(256, 0, 1).collect({ |x|
    (x * 2 - 1).tanh * 0.8  // map 0–1 → -1→1, apply tanh
}));
Shaper.ar(b, sig * 0.9)   // apply the custom wave shape

// Distortion with tone control (high-pass before, low-pass after)
SynthDef(\overdrive, { |in = 0, drive = 3, tone = 3000, mix = 0.5, out = 0|
    var dry    = In.ar(in, 2);
    var driven = (HPF.ar(dry, 100) * drive).tanh;  // remove DC, then drive
    var toned  = LPF.ar(driven, tone);             // tone control
    Out.ar(out, XFade2.ar(dry, toned, mix * 2 - 1));
}).add;

// Bit crushing (lo-fi, digital destruction)
SynthDef(\bitCrush, { |in = 0, bits = 8, sampleRate = 11025, out = 0|
    var step = 2.pow(bits).reciprocal;
    var sig  = Latch.ar(In.ar(in, 2), Impulse.ar(sampleRate));  // sample rate reduce
    sig = (sig / step).round * step;                            // bit reduce
    Out.ar(out, sig);
}).add;
```

---

## 7. Pitch & Frequency Effects

```supercollider
// Pitch shift — shift pitch without changing duration
PitchShift.ar(sig,
    windowSize: 0.2,
    pitchRatio: 1.5,       // ratio: 2.0 = octave up, 0.5 = octave down
    pitchDispersion: 0.0,  // random detune
    timeDispersion: 0.0    // random timing scatter
)

// Harmonizer — add pitch-shifted copies
sig + PitchShift.ar(sig, 0.2, 7/6) * 0.5  // add a minor third above

// FreqShift — shift all frequencies by fixed Hz (not ratio — creates inharmonicity)
FreqShift.ar(sig, shiftHz: 50)  // shifts everything up by 50 Hz

// Ring modulation — multiply signals (sum + difference frequencies)
sig * SinOsc.ar(modFreq)  // creates sum/difference sidebands

// Amplitude modulation (same as ring mod but with DC offset)
sig * SinOsc.ar(modFreq, mul: 0.5, add: 0.5)  // 0–1 range = tremolo range

// Chorus — multiple slightly detuned + delayed copies
SynthDef(\chorus, { |in = 0, rate = 0.5, depth = 0.002, mix = 0.5, out = 0|
    var input = In.ar(in, 2);
    var voices = 4.collect({ |i|
        var phase = i / 4 * 2pi;
        var lfo   = SinOsc.kr(rate + (i * 0.07), phase, depth);
        DelayL.ar(input, 0.05, 0.025 + lfo)
    });
    var wet = Mix(voices) / 4;
    Out.ar(out, XFade2.ar(input, wet, mix * 2 - 1));
}).add;
```

---

## 8. FFT / Spectral Processing

The PV (Phase Vocoder) UGens operate in the frequency domain. They offer transformations
impossible in the time domain — freeze a spectrum, smear frequencies, shift bins.
Think of these as **post-synthesis timbral surgery**.

```supercollider
// FFT/IFFT framework — all PV UGens live between these
(
SynthDef(\spectralProcess, { |in = 0, out = 0|
    var sig   = In.ar(in, 1);
    var chain = FFT(LocalBuf(2048), sig);  // 2048 = FFT size (power of 2)

    chain = PV_MagSmear(chain, bins: 3);  // smear adjacent bins → spectral blurring

    sig = IFFT(chain);
    Out.ar(out, sig ! 2);
}).add;
)

// Common PV processors:

// PV_MagFreeze — freeze the current spectrum
PV_MagFreeze(chain, freeze: 1)  // freeze=1 holds current frame, freeze=0 = live

// PV_BinShift — shift all bins up or down
PV_BinShift(chain, stretch: 1.5, shift: 0)  // stretch=1.5 = pitch up + inharmonize

// PV_PhaseShift — rotate all phases (creates flanging/phasing)
PV_PhaseShift(chain, phase: SinOsc.kr(0.1, mul: pi))

// PV_MagAbove / PV_MagBelow — gate bins by magnitude (spectral noise gate)
PV_MagAbove(chain, threshold: 0.5)  // only pass bins above threshold amplitude

// PV_RandComb — randomly mute bins (spectral holes)
PV_RandComb(chain, wipe: 0.5, trig: Impulse.kr(0.25))

// PV_Diffuser — randomize phases (destroys transients, creates shimmer)
PV_Diffuser(chain, trig: Impulse.kr(0.5))

// PV_LocalMax — only pass local maxima bins (spectral peaking)
PV_LocalMax(chain, threshold: 0.2)

// Cross-synthesis — multiply spectra of two sources
SynthDef(\crossSynth, { |in1 = 0, in2 = 1, out = 0|
    var sig1   = In.ar(in1);
    var sig2   = In.ar(in2);
    var chain1 = FFT(LocalBuf(2048), sig1);
    var chain2 = FFT(LocalBuf(2048), sig2);
    var mixed  = PV_Multiply(chain1, chain2);  // spectral multiplication
    Out.ar(out, IFFT(mixed).dup * 0.3);
}).add;

// Spectral freeze/smear texture — frozen time effect
SynthDef(\spectralFreeze, { |in = 0, freeze = 0, smear = 5, out = 0|
    var sig   = In.ar(in);
    var chain = FFT(LocalBuf(4096), sig);
    chain = PV_MagSmear(chain, smear);
    chain = PV_MagFreeze(chain, freeze);
    Out.ar(out, IFFT(chain).dup * 0.5);
}).add;
```

---

## 9. Feedback Synthesis

Feedback takes a signal's output and routes it back to its input — creating resonance,
oscillation, or controlled self-excitation. Handle with care; feedback can blow speakers.
Always use `LeakDC` and amplitude envelopes when working with feedback.

```supercollider
// LocalIn/LocalOut feedback loop
SynthDef(\feedbackOsc, { |freq = 440, fb = 0.95, damp = 0.3, amp = 0.2, out = 0|
    var fbSig = LocalIn.ar(1) * fb;
    fbSig     = LPF.ar(fbSig, freq * (8 - (damp * 6)));  // damp high freqs
    var sig   = SinOsc.ar(freq, fbSig);  // feedback into phase
    LocalOut.ar(sig);
    sig = LeakDC.ar(sig);
    Out.ar(out, (sig ! 2) * amp);
}).add;

// Feedback delay — self-oscillating comb
SynthDef(\feedbackDelay, { |delTime = 0.01, fb = 0.98, drive = 2, amp = 0.2, out = 0|
    var sig = LocalIn.ar(2);
    sig = (sig * drive).tanh;                        // saturate before feedback
    sig = LeakDC.ar(sig);
    sig = CombC.ar(sig + Dust.ar(1, 0.1), 0.1, delTime, delTime * 20);
    LocalOut.ar(sig * fb);
    Out.ar(out, sig * amp);
}).add;

// Karplus-Strong feedback structure (manual implementation)
SynthDef(\ksFeedback, { |freq = 220, noise = 0.01, fb = 0.995, out = 0|
    var excite = WhiteNoise.ar(noise);
    var sig    = excite + (LocalIn.ar(1) * fb);
    var loop   = DelayN.ar(LPF.ar(sig, freq * 2), 0.05, freq.reciprocal);
    LocalOut.ar(loop);
    Out.ar(out, loop.dup * 0.4);
}).add;
```

---

## 10. Effects Bus Routing

```supercollider
// Full setup: groups, buses, send/return architecture
(
s.waitForBoot {
    // Create buses
    ~reverbBus = Bus.audio(s, 2);
    ~delayBus  = Bus.audio(s, 2);

    // Create groups (ordering matters!)
    ~sourceGroup = Group.new(s);
    ~fxGroup     = Group.after(~sourceGroup);

    // Reverb return synth
    SynthDef(\fxReverb, { |in = 0, wet = 0.4, room = 0.8, out = 0|
        Out.ar(out, FreeVerb2.ar(In.ar(in)[0], In.ar(in)[1], wet, room) * 0.5);
    }).add;

    // Delay return synth
    SynthDef(\fxDelay, { |in = 0, delTime = 0.375, fb = 0.6, wet = 0.4, out = 0|
        var input = In.ar(in, 2);
        var del   = CombC.ar(input, 1, delTime, delTime * 10);
        Out.ar(out, del * wet);
    }).add;

    s.sync;

    // Launch effects processors
    ~revSynth = Synth(\fxReverb, [in: ~reverbBus, out: 0], ~fxGroup);
    ~delSynth = Synth(\fxDelay,  [in: ~delayBus,  out: 0], ~fxGroup);

    // Instrument that sends to effects buses
    SynthDef(\withFx, { |freq = 440, amp = 0.3, revSend = 0.3, delSend = 0.2,
                         out = 0, revOut = 0, delOut = 0|
        var sig = // ... your sound ...
        Out.ar(out,    sig * amp);          // dry to main out
        Out.ar(revOut, sig * revSend);      // send to reverb
        Out.ar(delOut, sig * delSend);      // send to delay
    }).add;

    s.sync;

    // Play with effects sends
    Pbind(
        \instrument, \withFx,
        \revOut, ~reverbBus,
        \delOut, ~delayBus,
        \degree, Pseq([0, 2, 4, 7], inf),
        \dur, 0.5
    ).play(target: ~sourceGroup);
};
)
```

---

## 11. Complete Effects Chain Examples

### Ambient Chain — lush, spatial
```supercollider
SynthDef(\ambientChain, { |in = 0, size = 0.95, damp = 0.3, chorus = 0.003,
                           shimmer = 0.2, out = 0|
    var sig = In.ar(in, 2);
    // 1. Chorus widening
    var chor = 4.collect({ |i|
        DelayL.ar(sig, 0.05, SinOsc.kr(0.3 + (i * 0.07), i/4 * 2pi, chorus, 0.02))
    });
    sig = Mix(chor) / 4;
    // 2. Long reverb
    sig = FreeVerb2.ar(sig[0], sig[1], 0.5, size, damp);
    // 3. Shimmer (octave-up reverb regeneration) — simplified
    var shimSig = PitchShift.ar(sig.sum, 0.1, 2.0) * shimmer;
    sig = sig + shimSig.dup;
    Out.ar(out, sig * 0.5);
}).add;
```

### Gritty Industrial Chain — raw, harsh
```supercollider
SynthDef(\grittChain, { |in = 0, drive = 4, crush = 6, srate = 8000,
                         cut = 4000, out = 0|
    var sig  = In.ar(in, 2);
    // 1. Drive + saturation
    sig = (sig * drive).tanh;
    // 2. Bit crush
    var step = 2.pow(crush).reciprocal;
    var latched = Latch.ar(sig, Impulse.ar(srate));
    sig = (latched / step).round * step;
    // 3. Low-pass roll-off (retains body but kills harsh aliases partially)
    sig = LPF.ar(sig, cut);
    // 4. Short slapback
    sig = sig + (DelayN.ar(sig, 0.1, 0.06) * 0.3);
    Out.ar(out, sig * 0.5);
}).add;
```
