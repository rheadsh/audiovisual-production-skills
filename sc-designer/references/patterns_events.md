# Patterns, Events & Time Reference — SuperCollider Sound Design Skill

SuperCollider's Pattern library is one of its great treasures — a declarative language for
expressing musical time as data structures. A Pbind is not just a scheduler; it is a score
written in the language of objects. Think of patterns as streams of potential events, each
one a snapshot of a musical moment, waiting to be realized.

---

## Table of Contents
1. [The Event System](#1-the-event-system)
2. [Essential Pbind Keys](#2-essential-pbind-keys)
3. [Pattern Classes — The Vocabulary of Time](#3-pattern-classes)
4. [Nested Patterns & Musical Structure](#4-nested-patterns--musical-structure)
5. [Pdef — Live Replaceable Patterns](#5-pdef--live-replaceable-patterns)
6. [Routines, Tasks, and Imperative Time](#6-routines-tasks-and-imperative-time)
7. [TempoClock — Pulse and Sync](#7-tempoclock--pulse-and-sync)
8. [JITLib — ProxySpace and Live Coding](#8-jitlib--proxyspace-and-live-coding)
9. [Advanced Pattern Techniques](#9-advanced-pattern-techniques)
10. [Pattern Recipes for Musical Situations](#10-pattern-recipes)

---

## 1. The Event System

In SuperCollider, a musical event is a dictionary of key-value pairs that describes a
moment in time. When a pattern plays, it generates a stream of these Event dictionaries.
The default event type `\note` will look up an instrument (SynthDef), collect the
parameters, and schedule a Synth on the server.

```supercollider
// An event, manually:
(instrument: \default, freq: 440, dur: 0.5, amp: 0.4, pan: 0).play

// Event types: \note, \rest, \midi, \grain, \set, \bus, \on, \off
// \rest — silence for the specified duration
(type: \rest, dur: 0.5).play

// Viewing a default event (type in post window):
Event.default
```

The **most important relationship** in SC music-making: the keys in Pbind correspond
directly to the *argument names* in your SynthDef. Always name SynthDef args to match
what patterns will control.

```supercollider
SynthDef(\myInstrument, { |freq = 440, amp = 0.3, pan = 0, out = 0, sustain = 1|
    // 'sustain' is the gate duration — patterns control this automatically
    var env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: Done.freeSelf);
    Out.ar(out, Pan2.ar(SinOsc.ar(freq) * env * amp, pan));
}).add;

Pbind(\instrument, \myInstrument, \freq, 440, \dur, 0.5).play
```

---

## 2. Essential Pbind Keys

These keys have **special meaning** in the event system — they control timing, pitch,
amplitude, and routing. Know these by heart.

```supercollider
\instrument  // SynthDef name (default: \default)
\freq        // frequency in Hz  (can also use \midinote, \degree, \note)
\midinote    // MIDI note number — auto-converts to freq
\degree      // scale degree — use with \scale and \octave
\scale       // Scale.at(\major), Scale.at(\minor), Scale.at(\dorian), etc.
\octave      // default 5 (middle C area)
\detune      // detune in Hz added to freq

\dur         // duration between note onsets (the rhythm!)
\sustain     // how long the synth sounds (default: dur * legato)
\legato      // ratio of sustain to dur (default 0.8) — controls articulation
\delta       // alternative to dur — explicit time between events

\amp         // amplitude (0–1)
\db          // amplitude in dB — alternative to amp
\pan         // stereo position (-1 to 1)

\out         // output bus
\group       // group to place synths in
\addAction   // \addToHead, \addToTail, \addAfter, \addBefore

\type        // event type: \note, \rest, \set, \midi, etc.
\lag         // schedule ahead of time (negative) or behind (positive)
```

### Pitch systems in Pbind

```supercollider
// Using degree + scale (most musical, most flexible)
Pbind(
    \instrument, \myInstrument,
    \scale, Scale.dorian,
    \degree, Pseq([0, 2, 4, 6, 5, 3, 1, 0], inf),
    \octave, Prand([4, 5, 5, 5, 6], inf),
    \dur, 0.25
).play;

// Modal transposition
Pbind(\degree, Pseq([0, 1, 2, 4], inf), \root, 3, \scale, Scale.minor).play

// Using midinote for chromatic writing
Pbind(\midinote, Pseq([60, 62, 64, 65, 67], inf), \dur, 0.3).play

// Raw frequency — for microtonal, FM-ratio, or spectral approaches
Pbind(\freq, Pseq([220, 275, 330, 440, 550], inf), \dur, 0.5).play

// Frequency as ratio (just intonation over a root)
var root = 110;
Pbind(\freq, Pseq([1, 5/4, 3/2, 7/4, 2].collect(_ * root), inf), \dur, 0.5).play
```

---

## 3. Pattern Classes

The Pbind keys take *any* Pattern as a value — this is the power of the system.

### Core Time/Value Patterns

```supercollider
// Pseq — sequence through a list, repeats times (inf = forever)
Pseq([1, 2, 3, 4], inf)             // 1 2 3 4 1 2 3 4...
Pseq([1, 2, 3, 4], 2)               // 1 2 3 4 1 2 3 4 (then stops)

// Prand — pick random element each step
Prand([1, 2, 3, 4], inf)

// Pxrand — pick random without immediate repetition
Pxrand([1, 2, 3, 4], inf)

// Pshuf — shuffle once, then repeat shuffled order
Pshuf([1, 2, 3, 4], inf)

// Pwrand — weighted random (weights sum to 1)
Pwrand([1, 2, 3], [0.6, 0.3, 0.1], inf)  // mostly 1s

// Pwhite — random float or integer in range
Pwhite(0.0, 1.0, inf)               // continuous random 0–1
Pwhite(1, 8, inf)                   // random integer 1–8

// Pseries — arithmetic series: start, step, length
Pseries(0, 1, 8)                    // 0 1 2 3 4 5 6 7

// Pgeom — geometric series (exponential): start, ratio, length
Pgeom(1, 2, 8)                      // 1 2 4 8 16 32 64 128

// Pn — repeat a pattern N times
Pn(Pseq([1, 2, 3], 1), 4)           // [1,2,3] four times

// Pfin — take first N values from a pattern
Pfin(8, Pwhite(0, 7, inf))

// Pstutter — repeat each value N times
Pstutter(3, Pseq([1, 2, 3], inf))   // 1 1 1 2 2 2 3 3 3...
```

### Rhythm Patterns

```supercollider
// Rest with Pseq — mix notes and rests
Pbind(
    \degree, Pseq([0, 1, \rest, 3, \rest, 5], inf),
    \dur, 0.25
).play;

// Polyrhythm via two Pbinds with different \dur:
(
Pbind(\instrument, \kick, \dur, 1.0, \degree, 0).play;   // quarter notes
Pbind(\instrument, \hat,  \dur, Prand([0.25, 0.5], inf)).play;  // irregular hi-hats
)

// Rhythmic patterns as Pseq of durations
Pbind(
    \degree, Prand([0, 2, 4, 7], inf),
    \dur, Pseq([0.5, 0.25, 0.25, 0.75, 0.25], inf),  // a rhythmic cell
    \amp, 0.4
).play;

// Euclidean rhythms (Bjorklund algorithm approximation)
// Install Bjorklund quark, or manually:
var euclidean = Pseq([1, 0, 1, 0, 1, 0, 0, 1].collect({ |x| x == 1 ifTrue: 0.25 ifFalse: { Rest(0.25) } }), inf);
```

### Probability and Flow

```supercollider
// Pif — conditional branch
Pif(Pfunc({ 0.7.coin }), Pseq([0, 2, 4], inf), Pseq([0, 1, 3], inf))

// Pfunc — arbitrary function as a pattern
Pfunc({ |ev| (ev[\degree] + 7).wrap(0, 14) })  // derived from previous event

// Prout — Routine-as-pattern (most flexible)
Prout({
    var scale = [0, 2, 3, 5, 7, 9, 10];  // dorian
    inf.do {
        scale.scramble.do { |deg|
            deg.yield;
        };
    };
})

// Plazy — create pattern lazily (deferred instantiation)
Plazy({ Pseq(Array.fill(8, { Prand([0, 2, 4, 7], 1) }), inf) })

// Pkey — reference another key in the current event
Pbind(
    \degree, Pseq([0, 2, 4, 7], inf),
    \root,   Pkey(\degree) * 2  // root derived from current degree
)
```

---

## 4. Nested Patterns & Musical Structure

The real power of Pbind emerges when you nest patterns inside patterns to create
**hierarchical musical structures** — phrase, motif, variation.

```supercollider
// Nested Pseq: phrase → section → piece
(
Pbind(
    \instrument, \myInstrument,
    \degree, Pn(                          // outer loop: 4 times
        Pseq([                            // each time: one of these phrases
            Pseq([0, 2, 4, 7], 1),        // phrase A
            Pseq([7, 5, 3, 0], 1),        // phrase B (retrograde)
            Pseq([0, 3, 7, 3], 1),        // phrase C
            Prand([0, 2, 4, 5, 7], 4),    // phrase D (random)
        ], 1),
        inf
    ),
    \dur, 0.25,
    \amp, Pseries(0.2, 0.02, 16).fold(0.1, 0.8)  // gradual crescendo, then fold
).play;
)

// Multiple voices from a single Pbind (polyphony via parallel patterns)
(
var bass = Pbind(\instrument, \bass, \degree, Pseq([0, 0, 5, 5], inf), \dur, 1);
var melody = Pbind(\instrument, \bell, \degree, Pseq([4, 5, 7, 9, 7, 5], inf),
                   \octave, 6, \dur, Prand([0.25, 0.5], inf));
var harmony = Pbind(\instrument, \pad, \degree, Pwrand([0, 2, 4], [0.5, 0.3, 0.2], inf),
                    \dur, Prand([1, 2], inf), \amp, 0.2);
Ppar([bass, melody, harmony]).play;
)
```

---

## 5. Pdef — Live Replaceable Patterns

Pdef wraps a pattern in a named slot. You can replace the pattern while it's playing
without stopping — the new pattern takes over at the next quantized boundary.
This is the foundation of **live coding** with patterns in SuperCollider.

```supercollider
// Define and play
Pdef(\melody, Pbind(\instrument, \default, \degree, Pseq([0, 2, 4, 7], inf), \dur, 0.25)).play;

// Replace while running — takes effect quantized to the beat
Pdef(\melody, Pbind(\instrument, \default, \degree, Prand([0, 3, 5, 7, 9], inf), \dur, 0.5));

// Add source later, or pause/resume
Pdef(\melody).pause;
Pdef(\melody).resume;
Pdef(\melody).stop;

// Quantize replacement to measure boundary
Pdef(\melody).quant = 4;  // snap to every 4 beats

// Layer multiple Pdefs for a live performance setup:
Pdef(\bass,    Pbind(\instrument, \bass,   \degree, Pseq([0, 0, -3, -5], inf), \dur, 1));
Pdef(\melody,  Pbind(\instrument, \lead,   \degree, Pseq([4, 5, 7, 5, 4, 2], inf), \dur, 0.5));
Pdef(\rhythm,  Pbind(\instrument, \hat,    \amp, Pseq([0.7, 0.3, 0.5, 0.3], inf), \dur, 0.25));

// Play all
[Pdef(\bass), Pdef(\melody), Pdef(\rhythm)].do(_.play);

// Stop all
Pdef.all.do(_.stop);
```

---

## 6. Routines, Tasks, and Imperative Time

For **procedural** time control — imperative "do this, then wait, then do that":

```supercollider
// Routine — imperative time sequence
Routine({
    var synth = Synth(\myInstrument, [freq: 220]);
    2.wait;
    synth.set(\freq, 330);
    1.wait;
    synth.set(\freq, 440);
    2.wait;
    synth.free;
}).play;

// Task — like Routine but can be paused/resumed
t = Task({
    inf.do { |i|
        var freq = [220, 277, 330, 440].wrapAt(i);
        Synth(\myInstrument, [freq: freq]);
        0.5.wait;
    }
});
t.play;
t.pause;
t.resume;
t.stop;

// Combining patterns and routines — use .asStream
(
var pStream = Pseq([220, 330, 440, 550], inf).asStream;
Routine({
    inf.do {
        Synth(\myInstrument, [freq: pStream.next]);
        0.5.wait;
    }
}).play;
)

// Synth.new → set → free lifecycle
(
Routine({
    var s1 = Synth(\pad, [freq: 220, amp: 0]);
    s1.set(\amp, 0.3);         // fade in
    1.wait;
    s1.set(\freq, 330);        // glide to new pitch
    2.wait;
    s1.set(\amp, 0);           // fade out
    0.5.wait;
    s1.free;
}).play;
)
```

---

## 7. TempoClock — Pulse and Sync

```supercollider
// Set global tempo
TempoClock.default.tempo = 1.5;  // 90 BPM (1.5 beats/sec)
TempoClock.default.tempo = 120/60;  // 120 BPM

// Create a dedicated clock
var clock = TempoClock(140/60);

// Play a pattern on a specific clock
Pbind(\degree, Pseq([0, 2, 4, 7], inf), \dur, 0.5).play(clock);

// Quantize events to beat grid
Pbind(\degree, Prand([0, 3, 7], inf), \dur, 0.25).play(TempoClock.default, quant: 1);

// Schedule an action on a beat:
TempoClock.default.schedAbs(TempoClock.default.nextBar, { Synth(\crash) });

// Swing — delay every other note
Pbind(
    \degree, Pseq([0, 2, 4, 5, 7, 5, 4, 2], inf),
    \dur, 0.25,
    \lag, Pseq([0, 0.04, 0, 0.04], inf)  // 40ms swing on upbeats
).play;
```

---

## 8. JITLib — ProxySpace and Live Coding

JITLib (Just-in-Time Library) lets you define and redefine audio processes without
stopping, perfect for live performance. ProxySpace is its central environment.

```supercollider
// Start a ProxySpace (replaces current environment variables)
p = ProxySpace.push(s);
// or: ProxySpace.push(s.boot);

// Define a NodeProxy (live-replaceable audio source)
~bass = { SinOsc.ar(80) * 0.5 };
~bass.play;

// Replace while playing (crossfades by default)
~bass = { Saw.ar(80, 0.4) };

// Ndef — named proxy (global, doesn't need ProxySpace)
Ndef(\bass, { SinOsc.ar(80) * 0.4 }).play;
Ndef(\bass, { Pulse.ar(80, 0.3, 0.4) });  // replace

// Tdef — named Task/Routine proxy
Tdef(\seq, {
    inf.do { |i|
        Ndef(\bass).set(\freq, [60, 63, 67, 70].wrapAt(i).midicps);
        0.5.wait;
    }
}).play;
Tdef(\seq, {
    // Replace the sequence while it's running
    inf.do { |i|
        Ndef(\bass).set(\freq, Prand([60, 63, 65, 70], 1).asStream.next.midicps);
        Prand([0.25, 0.5, 0.75], 1).asStream.next.wait;
    }
});

// ProxySpace fx chain
~fx = { |in| FreeVerb.ar(in, mix: 0.6, room: 0.9) };
~bass <>> ~fx;  // route bass through fx proxy

// Fade times for smooth transitions
Ndef(\bass).fadeTime = 2;  // 2-second crossfade when replacing
```

---

## 9. Advanced Pattern Techniques

```supercollider
// Pcollect — transform every value
Pcollect({ |v| v * 2 + 1 }, Pseq([0, 1, 2, 3], inf))

// Pselect — filter values, skipping those that fail
Pselect({ |v| v > 2 }, Pseq([0, 1, 2, 3, 4, 5], inf))

// Preject — opposite of Pselect
Preject({ |v| v == 3 }, Pseq([1, 2, 3, 4, 5], inf))

// Pattern as envelope — use patterns for parameter evolution
Pbind(
    \degree, Pseq([0, 2, 4, 5, 7], inf),
    \amp, Pseries(0.05, 0.03, 20).clip(0.05, 0.8),  // build up over 20 notes
    \dur, Pgeom(0.5, 0.95, 20)  // gradually accelerate
).play;

// Self-modifying pattern via Pfunc + mutable state
(
var state = 0;
Pbind(
    \degree, Pfunc({
        state = (state + Prand([1, 2, -1], 1).asStream.next).wrap(0, 14);
        state
    }),
    \dur, 0.25
).play;
)

// Parallel patterns with different tempos (polytempo)
(
var fast = TempoClock(2.0);
var slow = TempoClock(0.5);
Pdef(\hi, Pbind(\instrument, \hat, \dur, 0.25)).play(fast);
Pdef(\lo, Pbind(\instrument, \bass, \dur, 1.0)).play(slow);
)

// Markov chain via Pfsm (Finite State Machine Pattern)
// Roll your own with Pfunc + arrays:
(
var matrix = [
    [0, 3, 5, 7],     // from degree 0, go to: 0,3,5,7
    [0, 2, 4],        // from degree 2
    [0, 7],           // from degree 4
    [0, 5, 7]         // from degree 7
];
var state = 0;
Pbind(
    \degree, Pfunc({
        var next = matrix[matrix.indexOfEqual(state) ? 0].choose;
        state = next;
        next
    }),
    \dur, 0.3
).play;
)
```

---

## 10. Pattern Recipes

### Minimal Repetitive Music (Glass/Reich style)
```supercollider
(
var phrase = [0, 2, 4, 7, 9, 7, 4, 2];
Pdef(\phase1, Pbind(
    \instrument, \default,
    \degree, Pseq(phrase, inf),
    \dur, 0.2
)).play(TempoClock(2.0));

Pdef(\phase2, Pbind(
    \instrument, \default,
    \degree, Pseq(phrase, inf),
    \dur, 0.21,   // very slightly slower = phasing effect
    \pan, 0.7
)).play(TempoClock(2.0));
)
```

### Generative Ambient Texture
```supercollider
(
Pdef(\ambient, Pbind(
    \instrument, \pad,
    \scale, Scale.dorian,
    \degree, Prand([0, 2, 4, 5, 7, 9], inf),
    \octave, Prand([4, 5, 5, 6], inf),
    \dur, Prand([2, 3, 4, 5], inf),
    \sustain, Pkey(\dur) * Pwhite(0.8, 1.2),
    \amp, Pwhite(0.1, 0.35),
    \pan, Pwhite(-0.7, 0.7)
)).play;
)
```

### Rhythmic Variation Cell
```supercollider
(
var cell = Pseq([
    Pbind(\degree, Pseq([0, 4, 7, 0], 1), \dur, 0.25),   // up-arpeggio
    Pbind(\degree, Pseq([7, 4, 0, 7], 1), \dur, 0.25),   // down
    Pbind(\degree, Prand([0, 4, 7], 4),   \dur, 0.125),  // fast random
    Pbind(\type, \rest, \dur, 1),                         // silence
], inf);
cell.play;
)
```

### Spectral-ish Modal Voicing
```supercollider
(
// Build chords from harmonic series above a fundamental
var fund = 55;  // A1
Pbind(
    \instrument, \pad,
    \freq, Plazy({
        var ratios = [1, 3, 5, 7, 9, 11].choose(4).sort;  // random subset of partials
        ratios.collect(_ * fund)  // returns an array = chord
    }),
    \dur, Prand([3, 4, 5, 6], inf),
    \amp, 0.15,
    \sustain, Pkey(\dur) * 1.1
).play;
)
```
