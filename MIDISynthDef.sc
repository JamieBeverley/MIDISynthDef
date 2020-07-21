MIDISynthDef : SynthDef{
	classvar <>loaded;
	var <>ccMap;
	var <>permanent;
	var <>synths;
	var <>midiNoteOns;
	var <>midiNoteOffs;
	var <>midiCCs;
	var <>noteQueue;
	var <>polyphony;
	var <>verbose;
	var <>synthParams;
	var <>midiSrcIds;

	*initClass{
		MIDISynthDef.loaded = Dictionary.new();
	}

	*new {
		|name,ugenGraphFunc,ccMap, polyphony=inf, midiSrcIds, permanent=true, verbose=false,rates,prependArgs,variants,metadata|
		var a = super.new(name,ugenGraphFunc,rates,prependArgs,variants,metadata).init();
		^a.init(ccMap, polyphony, midiSrcIds, permanent, verbose);
	}

	init {
		|ccMap,polyphony, midiSrcIds, permanent, verbose|
		this.synths = Dictionary.new(127);
		if(ccMap.isNil, {ccMap = ()});
		this.ccMap = ccMap;
		this.polyphony = polyphony;
		this.permanent = permanent;
		this.noteQueue = [];
		this.midiSrcIds = if(midiSrcIds.isArray,{midiSrcIds},{[midiSrcIds]});
		this.verbose = verbose;
		this.synthParams = Dictionary.new();
		this.midiNoteOns = Dictionary.new();
		this.midiNoteOffs = Dictionary.new();
		this.midiCCs = Dictionary.new();
	}

	removeMidi{
		var freeFunc = {
			|i|
			i.permanent_(false);
			i.free;
		};
		this.midiNoteOns.do(freeFunc);
		this.midiNoteOffs.do(freeFunc);
		this.midiCCs.do(freeFunc);
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
		if(this.noteQueue.includes(num).not,{
			this.noteQueue = this.noteQueue.addFirst(num);
		});
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
			synth.get(\gate, {synth.set(\gate,0)});
		});
		this.synths[num] = nil;
	}

	noteOn{
		^ {
			|val, num, chan, src|
			if(this.verbose,{[val, num, chan, src].postln;});
			this.playNote(num);
		}
	}

	noteOff{
		^{
			|val, num, chan, src|
			if(this.verbose,{[val, num, chan, src].postln;});
			this.stopNote(num);
		}
	}

	cc {
		^{
			|val,num,chan,src|
			var spec = this.ccMap[num];
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
		this.midiSrcIds.do{
			|id|
			this.midiNoteOns[id] = MIDIFunc.noteOn(this.noteOn, chan:midiChan, srcID: id).permanent_(this.permanent);
			this.midiNoteOffs[id] = MIDIFunc.noteOff(this.noteOff, chan:midiChan, srcID: id).permanent_(this.permanent);
			this.midiCCs[id] = MIDIFunc.cc(this.cc, chan:midiChan, srcID: id).permanent_(this.permanent);
		};
	}
}
