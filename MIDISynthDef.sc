MIDISynthDef : SynthDef{
	classvar <>loaded;
	var <>midiMap;
	var <>permanent;
	var <>synths;
	var <>midiNoteOn;
	var <>midiNoteOff;
	var <>noteQueue;
	var <>polyphony;

	*initClass{
		MIDISynthDef.loaded = Dictionary.new();
	}

	*new {
		|name,ugenGraphFunc,midiMap,polyphony=inf,permanent=true,rates,prependArgs,variants,metadata|
		var a = super.new(name,ugenGraphFunc,rates,prependArgs,variants,metadata).init();
		^a.init(midiMap, polyphony, permanent);
	}

	init {
		|midiMap,polyphony, permanent|
		this.synths = Dictionary.new(127);
		this.midiMap = midiMap;
		this.polyphony = polyphony;
		this.permanent = permanent;
		this.noteQueue = [];
		MIDISynthDef.loaded[this.name] = this;
	}

	removeMidi{
		this.midiNoteOn.free;
		this.midiNoteOff.free;
	}

	add {
		|midiChan, libname, completionMsg, keepDef|
		var existing = MIDISynthDef.loaded[this.name];
		if(existing.notNil, {
			existing.removeMidi();
		});
		super.add();
		this.midi(midiChan);

	}

	playNote {
		|num|
		var synth = this.synths[num];
		num.postln;
		this.stopNote(num);
		this.noteQueue = this.noteQueue.addFirst(num);
		while({this.noteQueue.size > this.polyphony}, {
			this.stopNote(this.noteQueue.pop());
		});
		this.synths[num] = Synth(this.name,[freq: num.midicps, gate:1]);
	}

	stopNote {
		|num|
		var synth = this.synths[num];
		if(synth.notNil, {
			synth.set(\gate,0);
		});
		this.synths[num] = nil;
	}

	noteOn{
		^ {
			|val, num, chan, src|
			this.playNote(num);
			// var synth = this.synths[num];
			// num.postln;
			// if(synth.notNil && synth.isPlaying, {
			// 	synth.set(\gate,0);
			// });
			// this.synths[num] = Synth(this.name,[freq: num.midicps, gate:1]);
		}
	}

	noteOff{
		^{
			|val, num, chan, src|
			this.stopNote(num);
			// var synth = this.synths[num];
			// if(synth.notNil || synth.isPlaying, {
			// 	synth.set(\gate,0);
			// });
		}
	}

	midi {
		|midiChan|
		this.midiNoteOn = MIDIFunc.noteOn(this.noteOn, chan:midiChan).permanent_(this.permanent);
		this.midiNoteOff = MIDIFunc.noteOff(this.noteOff, chan:midiChan).permanent_(this.permanent);
	}
}
