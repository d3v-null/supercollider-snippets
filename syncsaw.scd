s.quit;
s.boot;

(
plot { [
    Impulse.ar(1000),
    SyncSaw.ar(1000, 1000),
    SyncSaw.ar(1000, 1200),
    SyncSaw.ar(1000, 1400),
    SyncSaw.ar(1000, 1600),
    SyncSaw.ar(1000, 1800),
    SyncSaw.ar(1000, 2000),
] }
)

(
plot { [
    Impulse.ar(1000),
    SyncSaw.ar( 900, 1000),
    SyncSaw.ar( 800, 1000),
    SyncSaw.ar( 700, 1000),
    SyncSaw.ar( 600, 1000),
    SyncSaw.ar( 500, 1000),
    SyncSaw.ar( 400, 1000),
    SyncSaw.ar( 300, 1000),
    SyncSaw.ar( 200, 1000),
    SyncSaw.ar( 100, 1000),
] }
)

(
plot { [
    SyncSaw.ar(800, Line.kr(800, 1600, 0.01)), // modulate saw freq
    Impulse.ar(Line.kr(1600, 3200, 0.01)) // to show sync rate
] }
)

q = nil;

(
    var on, off, cc, releasefunction, getcontrolvalue;
    var oscs, base;
    ~debug = true;
    oscs = 7;
    base = 2;

    if(q.notNil,{q.value;});

    MIDIClient.init;

    MIDIIn.connectAll;

    // Notes is an array of synths for each possible MIDI note
    ~notes = Array.newClear(128);
    // Controls is a dictionary of busses for each synth parameter
    ~controls = Dictionary.new;
    ~controls.put(\vsync, Bus.control(s, 1));
    // Buffer contains a 1Hz sample
    ~buffer = Buffer.read(s, "samples/trisaw_00001.0_1.000.wav");

    releasefunction = {|index|
        if(~debug, postf("releasing %\n", index));

        if(~notes[index].notNil){
            ~notes[index].release;
            ~notes[index] = nil;
        }
    };

    getcontrolvalue = {|control|
        ~controls.at(control).get({|val| ~lastval = val;});
        ~lastval;
    };

    SynthDef(\CircuitSyncSaw, { |freq, amp=0.1, gate=1, vsync=0, density=0, density_detune=0|
        var signal;
        signal = SyncSaw.ar(freq, freq * (vsync/16 + 1) );
        signal = signal * EnvGen.ar(Env.asr(0.005,1,0.1),gate,doneAction:2);
        Out.ar(0, signal);
    }).add;

    SynthDef(\CircuitSyncBuffer, { |freq, bufnum, amp=0.1, gate=1, vsync=0, density=0, density_detune=0|
        var trigger, signal, rate;
        trigger = Impulse.ar(freq * (vsync/16 + 1));
        rate = BufRateScale.kr(bufnum) * freq;
        signal = PlayBuf.ar( 1, bufnum, rate, trigger, 0, 1 );
        // TODO: create multiple copies of this saw at different detunes
        signal = signal * EnvGen.ar(Env.asr(0.005,1,0.1),gate,doneAction:2);
        Out.ar(0, signal);
    }).add;

    on = MIDIFunc.noteOn({ |veloc, num, chan, src|
        var vsyncval;
        vsyncval = getcontrolvalue.value(\vsync);
        if(~debug, postf("noteOn - veloc: %; num: %; chan: %; src: %; vsync: %\n",
                        veloc, num, chan, src, vsyncval));

        releasefunction.value(num);
        ~notes[num] = Synth(\CircuitSyncSaw, [
                \freq, num.midicps,
                \amp, veloc * 0.00315,
            ]);
        /*~notes[num] = Synth(\CircuitSyncBuffer, [
                \bufnum, ~buffer.bufnum,
                \freq, num.midicps,
                \amp, veloc * 0.00315,
            ]);*/
        ~notes[num].map(\vsync, ~controls.at(\vsync));
    });

    off = MIDIFunc.noteOff({ |veloc, num, chan, src|
        if(~debug, postf("noteOff - num: %s\n", num));

        releasefunction.value(num);
    });

    cc = MIDIFunc.cc({ |value, num, chan, src|
        var vsync_val;
        if(~debug, postf("cc - num: %; val: %\n", num, value));
        ~controls.at(\vsync).set(value);
        vsync_val = getcontrolvalue.value(\vsync);
        if(~debug, postf("vsync_val is now: %\n", vsync_val));
    });

    q = { on.free; off.free; cc.free; };
)

// when done:
q.value;
