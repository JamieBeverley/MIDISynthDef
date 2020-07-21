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
	ccMap:(
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
	ccMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\modMul, {|x| (x*16/127).round }],
		27: [\lfo, {|x| (x/127)*5}],
		28: [\lfoDepth, {|x| ((x/127)*8)}]
)).add(1);


MIDISynthDef(\reveb_stab,
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
	}, permanent:true,polyphony:1, verbose:true,
	ccMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
		27: [\reverb, {|x| (x/127).pow(2)*0.3}],
		28: [\lfoDepth, {|x| ((x/127).pow(3))*22000*0.5 }]
)).add(2);

MIDISynthDef(\delay_stab,
	{
		|amp=0.1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, gate=1, lpf=22000, delayTime=0.25, out=0|
		var audio = Mix.ar(SinOsc.ar(freq*([0,0.01,4,4.01,7,11,11.01].midiratio),mul:amp*(-18.dbamp)));
		var lpfEnv = EnvGen.kr(Env.adsr(attack,decay,sustain.pow(4),release), gate);
		var env = EnvGen.ar(Env.asr(0.001,sustainLevel:1,releaseTime:release),gate:gate,doneAction:2);
		audio = RLPF.ar(audio, (lpf*lpfEnv)+5,0.5);

		audio = audio + CombC.ar(
			audio,
			1,
			delayTime,
			8
		);

		Out.ar(0,Pan2.ar(audio*env));
	}, permanent:true,polyphony:1, verbose:true,
	ccMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
		27: [\delayTime, {|x| (x/127)}],
		28: [\lfoDepth, {|x| ((x/127).pow(3))*22000*0.5 }]
)).add(3);

MIDISynthDef(\reverb_pad,
	{
		|amp=0.1, attack=2, decay=0.7, sustain=1, release=4, freq=440, gate=1, lpf=800, lpfq=0.5, out=0, reverb= 0.04|
		var audio = Mix.ar(Saw.ar(freq*([1,1.01,1.02,1.03]),mul:amp*(-10.dbamp)));
		var lpfEnv = EnvGen.kr(Env.adsr(attack,decay,sustain.pow(4),release), gate);
		var env = EnvGen.ar(Env.asr(0.001,sustainLevel:1,releaseTime:release),gate:gate,doneAction:2);
		var z,y;
		audio = RLPF.ar(audio, (lpf*lpfEnv)+5,lpfq   );

		z = DelayN.ar(audio, 0.048);
		// 7 length modulated comb delays in parallel :
		y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
		// two parallel chains of 4 allpass delays (8 total) :
		3.do({ y = AllpassN.ar(y, 0.05, [0.05.rand, 0.05.rand], 0.5) });
		// add original sound to reverb and play it :
		audio = audio+(reverb*y);
		Out.ar(0,Pan2.ar(audio*env));
	}, permanent:true,polyphony:16, verbose:true,
	ccMap:(
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*4/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*8/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
		27: [\lpfq, {|x| (1-(x/127)).clip(0.05,1)}],
		28: [\reverb, {|x| (x/127).pow(2)*0.3}]
)).add(4);
