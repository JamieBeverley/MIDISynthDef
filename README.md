# MIDISynthDef

Utility for defining SynthDefs that respond to midi (w\ out the boilerplate of writing and managing MIDIdefs).

## Usage:

### MIDISynthDef

Creates a SynthDef w/ the provided ugen graph function and name, and MIDIFuncs to handle playing that synth through MIDI noteOn and noteOff functions.

If the supplied ugen graph func takes a `gate` parameter to trigger its envelope, and cleanup, `gate` will be set to `0` for noteOff messages.

Also takes a ccMap for mapping MIDI CC messages to manipulate synth params. ccMap is a map of MIDI cc numbers to an array with 2 components; the first component is the synth param, and the 2nd is a function that maps the MIDI cc value (which is between 0 and 127) to a more useful value for your synth (such as a frequency range or 0-1).

#### Example:
```
// Map for CC values. cc Num mapped to array of SynthDef param, and a fn that maps the midi cc val to a useful synth value (eg. to scale a midi value to something like a frequency range)

var ccMap = (
	21: [\amp, {|x| x/127}],
	22: [\attack, {|x| x*2/127 }],
	23: [\decay, {|x| x/127 }],
	24: [\sustain, {|x| x/127 }],
	25: [\release, {|x| x*4/127 }],
	26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
	27: [\reverb, {|x| (x/127).pow(2)*0.3}],
	28: [\lfoDepth, {|x| ((x/127).pow(3))*22000*0.5 }]
);

MIDISynthDef(\reverb_stab,
	// Ugen graph func (just like Synthdefs)
	{
		|amp=0.1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, gate=1, lpf=22000, reverb=0.05, out=0|
		var audio = Mix.ar(Saw.ar(freq*([0,0.01,7,7.01,10,14,14.01].midiratio),mul:amp*(-18.dbamp)));
		var lpfEnv = EnvGen.kr(Env.adsr(attack,decay,sustain.pow(4),release), gate);
		var env = EnvGen.ar(Env.asr(0.001,sustainLevel:1,releaseTime:release),gate:gate,doneAction:2);
		audio = RLPF.ar(audio, (lpf*lpfEnv)+5,0.5);

		// Reverb from SC help docs
		z = DelayN.ar(audio, 0.048);
		y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
		4.do({ y = AllpassN.ar(y, 0.050, [0.050.rand, 0.050.rand], 1) });
		audio = audio+(reverb*y);

		Out.ar(0,Pan2.ar(audio*env));
	},
	permanent:true,  // false if want MIDIFuncs to be killed w/ cmd .
	polyphony:1,		 // how many voices? This can be infinite if you like.
	verbose:true,		 // useful for debugging midi messages
	midiSrcIds: [123456790, 078123417], // Int or list of Ints corresponding to MIDIClient source uids for which this synth should respond to. These map to a MIDIFunc's srcId. If nil responds to all srcIds.
	ccMap:ccMap			 // (see above)
).add(midiChan: 0); // Which midi channel should this synth be responsive to
```

### MIDISynthDefFX

Similar concept to MIDISynthDef except you can provide an additional Ugen graph function for applying effects. Output from the ugenGraphFunc is passed via an audio buffer into the `fxGraphFunc`.

This Ugen graph func is played as an `Ndef(\name_fx)` and is left always 'playing'. This is intended for applying things like reverbs and delays which if applied just in the regular ugenGraphFunc would get truncated by the synths envelope/gate.

*** 2 requirements: ***
1. The provided ugenGraphFunc should take an `out` param and the func should contain `Out.ar(out, ...` somewhere (so it can be routed to the effects graph func).
2. The provided fxGraphFunc must take an `in` param, and should probably use `In.ar(in,...)` somewhere to read the dry signal from the ugenGraphFunc.

#### Example:
```
MIDISynthDefFX.new(
	name:\reverb_stab,
	ugenGraphFunc:{
		|amp=0.1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, gate=1, lpf=22000, reverb=0.05, out=0|
		var audio = Mix.ar(Saw.ar(freq*([0,0.01,7,7.01,10,14,14.01].midiratio),mul:amp*(-18.dbamp)));
		var lpfEnv = EnvGen.kr(Env.adsr(attack,decay,sustain.pow(4),release), gate);
		var env = EnvGen.ar(Env.asr(0.001,sustainLevel:1,releaseTime:release),gate:gate,doneAction:2);
		audio = RLPF.ar(audio, (lpf*lpfEnv)+5,0.5);
		Out.ar(out, Pan2.ar(audio*env));
	},
	fxGraphFunc:{
		|in, reverb=0.2, delayTime=0.33|

		var z,y, dry, audio, delay;
		dry = In.ar(in, 2);

		// Delay
		audio = dry + CombC.ar(in:dry,maxdelaytime:1,delaytime:delayTime,decaytime:2);

		// Reverb
		z = DelayN.ar(audio, 0.048);
		y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
		4.do({ y = AllpassN.ar(y, 0.050, [0.050.rand, 0.050.rand], 1) });
		audio = audio+(reverb*y);
		audio;
	},
	ccMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
	),
	fxCCMap:(
		27: [\reverb, {|x| (x/127).pow(2)*0.3}],
		28: [\delayTime, {|x| (x/127).clip(1/32,1)}]
	),
	permanent:true,
	polyphony:1,
	verbose:true
).add(midiChan: 2);
```

### Portamento
MIDISynthDef takes a `portamento` boolean. With `portamento=true`, when all voices are full (which depends on`polyphony`) and a new note is played, the `\freq` paraeter for the most recently played note is set to the new note. You can implement a glide duration using `Lag.kr` or something similar in the ugenGraphFunc.
eg:
```
MIDISynthDef(\portamento_chord,
	{
		|out=0, amp=0.1,  gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, glide=1, lpf=10000,lpfRq=0.5|
		var freqGlide = Lag.kr(freq, glide);  // interpolate between old and new freq over 'glide' seconds
		var audio = Saw.ar(freq: freqGlide, mul:amp);

		...		
	},
	polyphony:1,
	portamento:true,
	...
);
```

### Velocity Sensitive
By default MIDISynthDefs are not velocity-sensitive. If the `velocityToAmp` parameter is provided a function, each noteOn message will use this function to map the midi velocity to the synth's `amp` parameter.
Eg:
```
MIDISynthDef(
	...
	velocityToAmp: {|vel| (vel/127) * (-20.dbamp) }
	...
	)
```
*** see `examples.scd` for more help, or get in touch! ***
