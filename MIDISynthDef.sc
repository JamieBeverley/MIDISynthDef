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
	var <>portamento;
	var <>velocityToAmp;

	*initClass{
		MIDISynthDef.loaded = Dictionary.new();
	}

	*new {
		|name,ugenGraphFunc,ccMap, polyphony=inf, portamento=false, velocityToAmp=nil, midiSrcIds=nil, permanent=true, verbose=false,rates,prependArgs,variants,metadata|
		var a = super.new(name,ugenGraphFunc,rates,prependArgs,variants,metadata);
		^a.initMIDISynthDef(ccMap, polyphony, portamento, velocityToAmp, midiSrcIds, permanent, verbose);
	}

	initMIDISynthDef {
		|ccMap, polyphony, portamento, velocityToAmp, midiSrcIds, permanent, verbose|
		if(ccMap.isNil, {ccMap = ()});
		this.ccMap = ccMap;
		this.polyphony = polyphony;
		this.portamento = portamento;
		this.velocityToAmp = velocityToAmp;

		this.midiSrcIds = if(midiSrcIds.isArray,{midiSrcIds},{[midiSrcIds]});
		this.permanent = permanent;
		this.verbose = verbose;

		this.noteQueue = [];
		this.synths = Dictionary.new(127);
		this.synthParams = Dictionary.new();
		this.midiNoteOns = Dictionary.new();
		this.midiNoteOffs = Dictionary.new();
		this.midiCCs = Dictionary.new();
	}

	remove{
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
			existing.remove();
		});
		MIDISynthDef.loaded[this.name] = this;
		super.add();
		this.midi(midiChan);
	}

	playNotePortamento {
		|num, vel|
		var synth = this.synths[num];
		var params = this.synthParams.copy();
		var noteFrom = this.noteQueue[0];
		// If most recent note exists and is playing, glide it to num.
		// Otherwise just play note as normal.
		if(noteFrom.notNil && this.synths[noteFrom].notNil && (this.noteQueue.size >= this.polyphony),{
			this.stopNote(num);
			this.synths[num] = this.synths[noteFrom];
			this.synths[num].set(\freq, num.midicps);
			this.synths[noteFrom] = nil;
			this.noteQueue[0] = num;
		}, {
			this.playNote(num, vel);
		});
	}

	playNote {
		|num, vel|
		var synth = this.synths[num];
		var params = this.synthParams.copy();
		this.stopNote(num);
		if(this.noteQueue.includes(num).not,{
			this.noteQueue = this.noteQueue.addFirst(num);
		});
		while({this.noteQueue.size > this.polyphony}, {
			this.stopNote(this.noteQueue.pop());
		});
		if(this.velocityToAmp.notNil,{params['amp'] = this.velocityToAmp.value(vel)});
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
		this.noteQueue.remove(num);
		this.synths[num] = nil;
	}

	noteOn{
		^ {
			|val, num, chan, src|
			if(this.verbose,{[\noteOn, val, num, chan, src].postln;});
			if(this.portamento,{this.playNotePortamento(num, val)},{this.playNote(num, val)});
		}
	}

	noteOff{
		^{
			|val, num, chan, src|
			if(this.verbose,{[\noteOff, val, num, chan, src].postln;});
			this.stopNote(num);
		}
	}

	cc {
		^{
			|val,num,chan,src|
			var spec = this.ccMap[num];
			if(spec.notNil,{
				var param, mappedValue;
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
						synth.set(param, mappedValue);
					});
				});
				this.synthParams[param] = mappedValue;
				if(this.verbose,{["CC", param, mappedValue].postln;});
			});
		}
	}

	midi {
		|midiChan|
		this.midiSrcIds.do{
			|id|
			this.midiNoteOns[id.asSymbol] = MIDIFunc.noteOn(this.noteOn, chan:midiChan, srcID: id).permanent_(this.permanent);
			this.midiNoteOffs[id.asSymbol] = MIDIFunc.noteOff(this.noteOff, chan:midiChan, srcID: id).permanent_(this.permanent);
			this.midiCCs[id.asSymbol] = MIDIFunc.cc(this.cc, chan:midiChan, srcID: id).permanent_(this.permanent);
		};
	}
}


MIDISynthDefFX : MIDISynthDef {
	classvar <>loaded;
	var <>fxBus;
	var <>fxCCMap;
	var <>fxNdef;
	var <>numChannels;
	var <>server;
	var <>midiFxCCs;
	var <>cmdPFunc;

	*initClass{
		MIDISynthDefFX.loaded = Dictionary.new();
	}

	*new {
		|name, ugenGraphFunc, ccMap, fxGraphFunc, fxCCMap=2, server, numChannels=2, polyphony=inf, portamento=false, velocityToAmp=nil, midiSrcIds=nil, permanent=true, verbose=false,rates,prependArgs,variants,metadata|
		var a = super.new(name, ugenGraphFunc,ccMap, polyphony, portamento, velocityToAmp, midiSrcIds, permanent, verbose, rates, prependArgs, variants, metadata);
		^a.initMIDISynthDefFX(fxGraphFunc, fxCCMap, server, numChannels);
	}

	initMIDISynthDefFX {
		|fxGraphFunc, fxCCMap, server, numChannels|
		this.fxCCMap = fxCCMap;
		this.numChannels = numChannels;
		this.server = server;
		this.fxBus = Bus.audio(this.server, this.numChannels);
		this.fxNdef = Ndef(this.name++\_fx, fxGraphFunc);
		this.fxNdef.set(\in, this.fxBus);
		this.cmdPFunc = if(this.permanent, {{this.fxNdef.play}}, {{}});
		this.synthParams[\out] = this.fxBus;
		this.midiFxCCs = Dictionary.new();
	}

	add {
		|midiChan, libname, completionMsg, keepDef|
		var existing;
		super.add(midiChan, libname, completionMsg, keepDef);

		existing = MIDISynthDefFX.loaded[this.name];
		if(existing.notNil, {
			existing.remove();
		});
		MIDISynthDefFX.loaded[this.name] = this;
		// this.midi(midiChan);
		// existing = MIDISynthDefFX.loaded[this.name];
		this.fxNdef.play;
		if(this.permanent, {CmdPeriod.add(this.cmdPFunc)});
	}

	remove {
		super.remove();
		this.midiFxCCs.do({
			|i|
			i.permanent_(false);
			i.free;
		});
		this.fxNdef.free;
		CmdPeriod.remove(this.cmdPFunc);
	}

	fxCC{
		^{
			|val,num,chan,src|
			var spec;
			spec = this.fxCCMap[num];
			if(spec.notNil, {
				var param, mappedValue;
				if(spec.isArray,{
					param = spec[0];
					mappedValue = spec[1].value(val);
				}, {
					param = spec;
					mappedValue = val;
				});
				if(this.verbose,{["fxCC", param, mappedValue].postln;});
				this.fxNdef.set(param, mappedValue);
			});
		}
	}

	midi{
		|midiChan|
		super.midi(midiChan);
		this.midiSrcIds.do{
			|id|
			this.midiFxCCs[id.asSymbol] = MIDIFunc.cc(this.fxCC, chan:midiChan, srcID: id).permanent_(this.permanent);
		};
	}
}
