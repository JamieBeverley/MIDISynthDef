Small util for defining SynthDefs that respond to midi (w\out the boilerplate of writing MIDIdefs). MIDISynthDef().add() creates 127 polyphonic synth w/ provided synthdef graph function.

Example Use:
```
// Map for CC values. cc Num mapped to array of SynthDef param, and a fn that maps the midi cc val to a useful synth value
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
		z = DelayN.ar(audio, 0.048);
		// 7 length modulated comb delays in parallel :
		y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
		// two parallel chains of 4 allpass delays (8 total) :
		4.do({ y = AllpassN.ar(y, 0.050, [0.050.rand, 0.050.rand], 1) });
		// add original sound to reverb and play it :
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
