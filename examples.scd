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
).add(midiChan: 5);

(
var buffers = [
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/1.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/2.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/3.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/4.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/5.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/6.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/7.wav", channels:[0]),
	Buffer.readChannel(Server.default, Platform.userAppSupportDir++"/path/to/my/samples/8.wav", channels:[0])
];

MIDISynthDefFX(
	name:\granulizer,
	ugenGraphFunc:{
		|out=0, gate=1, amp=0.1, attack=0.01, release=1, pos=0, posJitter=0.13,rate=1,dur=0.5, pan=0.5, panJitter=0, reverb=0, bufnum=0, freq=261|
		var audio = TGrains.ar(
			2,
			trigger:Impulse.kr(rate*rate*32),
			bufnum:bufnum,
			rate:(freq.cpsmidi-60).midiratio,
			centerPos:((pos)+WhiteNoise.kr(mul:posJitter*posJitter*posJitter).range(-1,1))*BufDur.kr(bufnum),
			dur: dur*dur*2,
			pan: ((2*pan)-1) + ((WhiteNoise.kr(mul:panJitter).range(0,1)*2)-1)
		)*amp;
		var env = EnvGen.ar(Env.asr(attack,1,release), gate:gate, doneAction:2);
		audio = audio*env;
		Out.ar(out, audio);
	},
	fxGraphFunc:{
		|in, reverb=0.2|
		var z,y, dry, audio;
		dry = In.ar(in, 2);
		audio = dry;

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
		23: [\release, {|x| x*4/127 }],
		24: [\pos, {|x| (x/127) }],
		25: [\posJitter, {|x| (x/127)}],
		26: [\dur, {|x| x/127/2}],
		27: [\bufnum, {|x| buffers[(x*7/127).floor].bufnum}],
	),
	fxCCMap:(
		28: [\reverb, {|x| (x/127).pow(2)*0.3}],
	),
	permanent:true,
	polyphony:8,
	verbose:true
).add(midiChan: 6);
);

MIDISynthDefFX(\portamento_chord,
	{
		|out=0, amp=0.1,  gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, glide=1, lpf=10000,lpfRq=0.5|
		// Use Lag to adjust duration between notes.
		var freqGlide = Lag.kr(freq, glide);
		var audio = Mix.ar(Saw.ar(freqGlide*([0,0.01,4,4.01,7,11,11.01].midiratio),mul:amp*(-18.dbamp)));
		var lpfEnv = EnvGen.kr(Env.adsr(attack,decay,sustain.pow(4),release), gate);
		var env = EnvGen.ar(Env.asr(0.001,sustainLevel:1,releaseTime:release),gate:gate,doneAction:2);
		audio = RLPF.ar(audio, (lpf*lpfEnv)+5,lpfRq);

		Out.ar(out,Pan2.ar(audio*env));
	},
	fxGraphFunc:{
		|in, reverb=0.005|
		var z,y, dry, audio;
		dry = In.ar(in, 2);
		audio = dry;

		// Reverb
		z = DelayN.ar(audio, 0.048);
		y = Mix.ar(Array.fill(7,{ CombL.ar(z, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), 15) }));
		4.do({ y = AllpassN.ar(y, 0.050, [0.050.rand, 0.050.rand], 1) });
		audio = audio+(reverb*y);
		audio;
	},
	permanent:true,
	polyphony:1,
	verbose:true,
	midiSrcIds: nil,
	portamento:true,
	ccMap: (
		21: [\amp, {|x| x/127}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
		27: [\glide, {|x| ((x*2/127)) }]
	),
	fxCCMap: (
		28: [\reverb, {|x| (x/127).pow(2)*0.2 }]
	)
).add(7);

MIDISynthDef(\velocity_sensitive,
	{
		|out=0, amp=0.1, gain=1,  gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1, freq=440, glide=1, lpf=10000,lpfRq=0.5|
		var freqGlide = Lag.kr(freq, glide);
		var audio = Mix.ar(Saw.ar(freqGlide*([0,0.01,4,4.01,7,11,11.01].midiratio),mul:amp*(-18.dbamp)*gain));
		var lpfEnv = EnvGen.kr(Env.adsr(attack,decay,sustain.pow(4),release), gate);
		var env = EnvGen.ar(Env.asr(0.001,sustainLevel:1,releaseTime:release),gate:gate,doneAction:2);
		audio = RLPF.ar(audio, (lpf*lpfEnv)+5,lpfRq);

		Out.ar(out,Pan2.ar(audio*env));
	},
	polyphony:1,
	portamento:true,
	// Velocity of MIDI noteOn is mapped w/ function provided here, and then passed to the synth's 'amp' param
	// Eg: map to 0-1 range, pow(1/2) to squash range a bit, and multiply by -20dbs.
	velocityToAmp: {|vel| (vel/127).pow(1/2)*(-20.dbamp)},
	verbose:true,
	ccMap: (
		21: [\gain, {|x| (x*2/127)}],
		22: [\attack, {|x| x*2/127 }],
		23: [\decay, {|x| x/127 }],
		24: [\sustain, {|x| x/127 }],
		25: [\release, {|x| x*4/127 }],
		26: [\lpf, {|x| ((x/127).pow(3)*22000) }],
		27: [\glide, {|x| ((x*2/127)) }]
	)
).add(8);
