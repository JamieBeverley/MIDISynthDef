Small util for defining SynthDefs that respond to midi (w\out the boilerplate of writing MIDIdefs). MIDISynthDef().add() creates 127 polyphonic synth w/ provided synthdef graph function.

Example Use:
```
// Map for CC values. cc Num mapped to array of SynthDef param, and a fn that maps the midi cc val to a useful synth value
var midiMap = (
	21: [\amp, {|x| x/127}],
	22: [\attack, {|x| x*2/127 }],
	23: [\decay, {|x| x/127 }],
	24: [\sustain, {|x| x/127 }],
	25: [\release, {|x| x*4/127 }],
	26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
	27: [\lfo, {|x| (x/127).pow(3)*20}],
	28: [\lfoDepth, {|x| ((x/127).pow(3))*22000*0.5 }]
);

// Create MIDISynthDef. Add Synthdef to server and init MIDIFuncs
MIDISynthDef(\test,
	{
		|amp=0.1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, gate=1, lpf=22000, lfo=3, lfoDepth=100|
		var audio = Mix.ar(Saw.ar(freq*[1,1.01,1.02,1.03],mul:amp));
		var env = EnvGen.ar(Env.adsr(attack,decay,sustain,release), gate,doneAction:2);
		var lpfEnv = EnvGen.kr(Env.adsr(attack/2,decay/2,sustain,release/2), gate,doneAction:0);
		var out;
		var lpfFreq = SinOsc.kr(lfo,add:lpf+(lfoDepth/2), mul:lfoDepth).clip(5,22000);
		audio = LPF.ar(audio, lpfFreq);
		out = Pan2.ar(audio*env);
		Out.ar(0,out);
},
permanent:true,  // permanent MIDIFuncs or kill w/ ctrl .?
polyphony:8,     // inf or an int
verbose:true,    // log midi messages (helpful for debugging)
midiMap:midiMap  // cc map (see above)
).add();
```
