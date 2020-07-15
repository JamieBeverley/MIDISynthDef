MIDISynthDef(\stabc,
	{
		|amp=0.1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, gate=1, lpf=22000, lfo=3, lfoDepth=100|
		var audio = Mix.ar(Saw.ar(freq*([0,4,7,11].midiratio  ),mul:amp));
		var env = EnvGen.ar(Env.adsr(attack,decay,sustain,release), gate,doneAction:2);
		var lpfEnv = EnvGen.kr(Env.adsr(attack/2,decay/2,sustain,release/2), gate,doneAction:0);
		var out;
		var lpfFreq = SinOsc.kr(lfo,add:lpf+(lfoDepth/2), mul:lfoDepth).clip(5,22000);
		audio = RLPF.ar(audio, lpfFreq, 0.5);
		audio = FreeVerb.ar(audio,mix:0.6);
		out = Pan2.ar(audio*env);
		Out.ar(0,out);
	}, permanent:true,polyphony:1, verbose:true,
	midiMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
		27: [\lfo, {|x| (x/127).pow(3)*20}],
		28: [\lfoDepth, {|x| ((x/127).pow(3))*22000*0.5 }]
)).add(0);

MIDISynthDef(\fm_pad,
	{
		|amp=0.1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, gate=1, lpf=22000, modMul=4, lfo=1, lfoDepth=0.5|
		var modEnv = EnvGen.kr(Env.asr(attack,1,0.5))*SinOsc.kr(lfo,mul:lfoDepth);
		var mod = SinOsc.ar(freq*modMul,mul:(freq/4)*modMul)*DelayL.kr(modEnv,maxdelaytime:attack,delaytime:attack/2);
		var audio= SinOsc.ar(freq+mod,mul:amp);
		var env = EnvGen.ar(Env.adsr(attack,decay,sustain,release), gate,doneAction:2);
		var lpfEnv = EnvGen.kr(Env.adsr(attack/2,decay/2,sustain,release/2), gate,doneAction:0);
		var out;
		out = Pan2.ar(audio*env);
		Out.ar(0,out);
	}, permanent:true,polyphony:8, verbose:true,
	midiMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\modMul, {|x| (x*16/127).round }],
		27: [\lfo, {|x| (x/127)*5}],
		28: [\lfoDepth, {|x| ((x/127)*8)}]
)).add(1);
