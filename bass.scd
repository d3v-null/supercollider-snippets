s.quit;
s.boot;

var q = nil;

(
    var notes, on, off, releasefunction, debug;
    debug = false;
    if(q.notNil,{q.value;});

    MIDIClient.init;

    MIDIIn.connectAll;

    notes = Array.newClear(128);    // array has one slot per possible MIDI note

    releasefunction = {|index|
        if(debug, {"releasing: ".post; index.postln;});

        if(notes[index].notNil){
            notes[index].release;
            notes[index] = nil;
        }
    };

    SynthDef(\DerBass, { |freq, amp=0.1, gate=1|
        var signal, osc1, osc2, lfo1, lfo2;
        /*osc1 = LFTri.ar(freq / 2);*/
        /*osc2 = LFSaw.ar(freq);*/
        /*lfo1 = SinOsc.ar();*/
        /*lfo2 = LFSaw.ar();*/
        /*signal = osc1 + osc2;*/
        signal = SinOsc.ar(freq);
        signal = Resonz.ar(signal, 1000, 0.1) * 1;
        /*signal = Resonz.ar(signal, 1000, 0.1) * amp;*/
        signal = signal * EnvGen.ar(Env.asr(0.005,1,0.1),gate,doneAction:2);
        Out.ar(0, signal);
    }).add;

    on = MIDIFunc.noteOn({ |veloc, num, chan, src|
        if(debug, {
            "noteOn - veloc: ".post; veloc.post; ", num: ".post; num.post;
            ", chan: ".post; chan.post; ", src: ".post; src.postln;
        });

        releasefunction.value(num);

        notes[num] = Synth(\DerBass,
            [\freq, num.midicps,
            \amp, veloc * 0.00315]);
    });

    off = MIDIFunc.noteOff({ |veloc, num, chan, src|
        if(debug, {"noteOff".postln;});

        releasefunction.value(num);
    });

    q = { on.free; off.free; };
)

// when done:
q.value;
