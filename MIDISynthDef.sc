MIDISynthDef : SynthDef{
	var <>midiMap;
	var <>permanent;
	var <>synths;
	var <>midiNoteOn;
	var <>midiNoteOff;

	*new {
		|name,ugenGraphFunc,midiMap,permanent=true,rates,prependArgs,variants,metadata|
		var a = super.new(name,ugenGraphFunc,rates,prependArgs,variants,metadata).init();
		^a.init(midiMap, permanent);
	}
	init {
		|midiMap,permanent|
		this.synths = Dictionary.new(127);
		this.midiMap = midiMap;
		this.permanent = permanent;
	}

	add {
		|midiChan, libname, completionMsg, keepDef|
		super.add();
		this.midi(midiChan);
	}

	noteOn{
		^ {
			|val, num, chan, src|
			var synth = this.synths[num];
			num.postln;
			if(synth.notNil && synth.isPlaying, {
				synth.set(\gate,0);
			});
			this.synths[num] = Synth(this.name,[freq: num.midicps, gate:1]);
		}
	}

	noteOff{
		^{
			|val, num, chan, src|
			var synth = this.synths[num];
			if(synth.notNil || synth.isPlaying, {
				synth.set(\gate,0);
			});
		}
	}

	midi {
		|midiChan|
		this.midiNoteOn = MIDIFunc.noteOn(this.noteOn, chan:midiChan).permanent_(this.permanent);
		this.midiNoteOff = MIDIFunc.noteOff(this.noteOff, chan:midiChan).permanent_(this.permanent);
	}
}
