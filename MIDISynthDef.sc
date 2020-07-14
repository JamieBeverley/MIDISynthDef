MIDISynthDef : SynthDef{
	classvar <>loaded;
	var <>midiMap;
	var <>permanent;
	var <>synths;
	var <>midiNoteOn;
	var <>midiNoteOff;
	var <>midiCC;
	var <>noteQueue;
	var <>polyphony;
	var <>verbose;
	var <>synthParams;

	*initClass{
		MIDISynthDef.loaded = Dictionary.new();
	}

	*new {
		|name,ugenGraphFunc,midiMap,polyphony=inf,permanent=true, verbose=false,rates,prependArgs,variants,metadata|
		var a = super.new(name,ugenGraphFunc,rates,prependArgs,variants,metadata).init();
		^a.init(midiMap, polyphony, permanent, verbose);
	}

	init {
		|midiMap,polyphony, permanent, verbose|
		this.synths = Dictionary.new(127);
		if(midiMap.isNil, {midiMap = ()});
		this.midiMap = midiMap;
		this.polyphony = polyphony;
		this.permanent = permanent;
		this.noteQueue = [];
		this.verbose = verbose;
		this.synthParams = Dictionary.new();
	}

	removeMidi{
		this.midiNoteOn.permanent_(false);
		this.midiNoteOn.free;
		this.midiNoteOff.permanent_(false);
		this.midiNoteOff.free;
		this.midiCC.permanent_(false);
		this.midiCC.free;
	}

	add {
		|midiChan, libname, completionMsg, keepDef|
		var existing = MIDISynthDef.loaded[this.name];
		if(existing.notNil, {
			existing.removeMidi();
		});
		MIDISynthDef.loaded[this.name] = this;
		super.add();
		this.midi(midiChan);
	}

	playNote {
		|num|
		var synth = this.synths[num];
		var params = this.synthParams.copy();
		this.stopNote(num);
		this.noteQueue = this.noteQueue.addFirst(num);
		while({this.noteQueue.size > this.polyphony}, {
			this.stopNote(this.noteQueue.pop());
		});
		params['freq'] = num.midicps;
		params['gate'] = 1;
		this.synths[num] = Synth(this.name, params.asKeyValuePairs);
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
			if(this.verbose,{[val, num, chan, src].postln;});
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
			if(this.verbose,{[val, num, chan, src].postln;});
			this.stopNote(num);
			// var synth = this.synths[num];
			// if(synth.notNil || synth.isPlaying, {
			// 	synth.set(\gate,0);
			// });
		}
	}

	cc {
		^{
			|val,num,chan,src|
			var spec = this.midiMap[num];
			if(this.verbose,{[val, num, chan, src].postln;});
			if(spec.notNil,{
				var param, mappedValue;
				spec.isArray.postln;
				if(spec.isArray,{
					param = spec[0];
					mappedValue = spec[1].value(val);
				}, {
					param = spec;
					mappedValue = val;
				});
				this.noteQueue.do({
					|i|
					var synth = this.synths[i];
					if(synth.notNil, {
						[\set, param, mappedValue].postln;
						synth.set(param, mappedValue);
					});
				});
				this.synthParams[param] = mappedValue;
			});
		}
	}

	midi {
		|midiChan|
		this.midiNoteOn = MIDIFunc.noteOn(this.noteOn, chan:midiChan).permanent_(this.permanent);
		this.midiNoteOff = MIDIFunc.noteOff(this.noteOff, chan:midiChan).permanent_(this.permanent);
		this.midiCC = MIDIFunc.cc(this.cc, chan:midiChan).permanent_(this.permanent);
	}
}
