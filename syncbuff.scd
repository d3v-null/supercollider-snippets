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

// construct stuff
(
    ~debug = true;
    // Notes is an array of synths for each possible MIDI note
    ~notes = Array.newClear(128);
    // Controls is a dictionary of busses for each synth parameter
    ~controls = Dictionary.new;
    // Buffer contains a 1Hz sample
    /*~buffer = Buffer.read(s, "/Users/Derwent/GitHub/supercollider-snippets/samples/trisaw_f00001.0_p1.000.wav");*/
    /*~buffer = Buffer.read(s, "/Users/Derwent/GitHub/supercollider-snippets/samples/trisaw_f00001.0_p0.500.wav");*/
    ~buffer = Buffer.read(s, "/Users/Derwent/GitHub/supercollider-snippets/samples/square_f00001.0_p0.500.wav");

    // Synth parameters
    ~oscs = 7; // number of oscillators in each synth
    ~base = 2; // base used to calculate spectral deviation

    // midi handling helper functions
    ~releaseNote = {|note|
        if(~debug, postf("releasing %\n", note));

        if(~notes[note].notNil){
            ~notes[note].release;
            ~notes[note] = nil;
        }
    };

    ~getControl = {|control|
        ~controls.at(control).get({|val| ~lastval = val;});
        ~lastval;
    };

    q=nil;

    // converts from oscillator number given oscs, to position on normal distribution
    ~fnOscPosition = {|oscs, num| num.linlin(0, (oscs-1), -1 * (oscs-1)/2, (oscs-1)/2)};
    // calculates value of normal distribution at position x given deviation d
    ~fnNorm = {|x, d| exp(-1*x.squared/(d.squared * 2))/(d * sqrt(2pi))};
    // calculates the deviation given a density
    ~fnDeviation = {|density| ~base ** (density.linlin(0, 127, -2, 3));};
)

// density experiments
(
    var density, normals, densities;

    // equally spaced oscillators about origin
    postf("oscillator spacing test. ~oscs=%. %\n", ~oscs, Array.fill(~oscs, {|num| ~fnOscPosition.value(~oscs, num); }));

    // normal pdf in python: exp(-x**2/2)/sqrt(2*pi)
    // exp(-x**2/(dens**2 * 2)/(dens * sqrt(2*pi))
    // exp(-x.squared/(dens.squared * 2)/(dens * sqrt(2*pi))
    postf("norm test. norm(0,1) = %\n", ~fnNorm.value(0, 1));

    postf("deviation test. deviation(0) = %\n", ~fnDeviation.value(0));

    density = 1;
    normals = Array.fill( ~oscs, {|num|
        ~fnNorm.value(~fnOscPosition.value(~oscs, num), ~fnDeviation.value(density));
    });

    normals = Array.fill( ~oscs, {|num|
        ~fnNorm.value(~fnOscPosition.value(~oscs, num), density);
    });
    postf("normals test. ~oscs=%. %\n", ~oscs, normals);
)
    densities = {|oscs, dens|
        var normals = Array.fill( oscs, {|num|
            ~fnNorm.value(~fnOscPosition.value(~oscs, num), density);
        });
        var total = normals.sum;
        normals / total;
    };
    postf("densities test. ~oscs=%, d=%. %\n", ~oscs, d, densities.value(~oscs, d));
)

//initialize stuff
(
    var on, off, cc;

    ~notes.do({|note, index|
        if(note.notNil,{
            if(~debug,{postf("freeing note %", index); });
            note.free;
        });
    });
    ~controls.do({|control|
        control.free;
    });

    if(q.notNil,{
        if(~debug, {postln("freeing previous instance"); });
        q.value;
    },{
        if(~debug, {postln("not freeing previous instance"); });
    });

    MIDIClient.init;
    MIDIIn.connectAll;

    ~controls.put(\vsync, Bus.control(s, 1));
    ~controls.put(\density, Bus.control(s, 1));
    ~controls.put(\density_detune, Bus.control(s, 1));

    SynthDef(\CircuitSyncBuffer, { |freq, bufnum, amp=0.1, gate=1, vsync=0|
        // the rate to play the buffer
        var rate;
        // the trigger signal, out signal
        var trigger, signal;
        trigger = Impulse.ar(freq);
        rate = BufRateScale.kr(bufnum) * freq * (vsync/8 + 1);
        signal = PlayBuf.ar( 1, bufnum, rate, trigger, 0, 1 );
        signal = signal * EnvGen.ar(Env.asr(0.005,1,0.1),gate,doneAction:2);
        Out.ar(0, [signal, signal]);
    }).add;

    SynthDef(\CircuitSyncBufferDense, { |freq, bufnum, amp=0.1, gate=1, vsync=0, density=0, density_detune=0|
        // the rate to play the buffer
        var rate;
        // the trigger signal, out signal
        var trigger, signal;
        // array of amplitudes distributed with normal function
        var normals;
        var signals_dense;

        trigger = Impulse.ar(freq);
        rate = BufRateScale.kr(bufnum) * freq * (vsync/16 + 1);

        // TODO: create multiple copies of this saw at different detunes
        normals = Array.fill( ~oscs, {|num|
            ~fnNorm.value(~fnOscPosition.value(~oscs, num), ~fnDeviation.value(density));
        });
        /*signals_dense = ;*/
        signal = Mix.new(normals.collect({|normal, num|
            var position, detune;
            position = ~fnOscPosition.value(~oscs, num);
            detune = density_detune * position * (2 ** (1/2)) / 100;
            PlayBuf.ar( 1, bufnum, rate * (1+detune), trigger, 0, 1) * normal / normals.sum;
        }));

        signal = signal * EnvGen.ar(Env.asr(0.005,1,0.1),gate,doneAction:2);
        Out.ar(0, [signal, signal]);
    }).add;

    on = MIDIFunc.noteOn({ |veloc, num, chan, src|
        var vsyncval;

        vsyncval = ~getControl.value(\vsync);
        if(~debug, postf("noteOn - veloc: %; num: %; chan: %; src: %; vsync: %\n",
                        veloc, num, chan, src, vsyncval));

        ~releaseNote.value(num);
        /*~notes[num] = Synth(\CircuitSyncBuffer, [*/
        ~notes[num] = Synth(\CircuitSyncBufferDense, [
                \bufnum, ~buffer.bufnum,
                \freq, num.midicps,
                \amp, veloc * 0.00315,
            ]);
        ~notes[num].map(\vsync, ~controls.at(\vsync));
        ~notes[num].map(\density, ~controls.at(\density));
        ~notes[num].map(\density_detune, ~controls.at(\density_detune));
    });

    off = MIDIFunc.noteOff({ |veloc, num, chan, src|
        if(~debug, postf("noteOff - num: %s\n", num));

        ~releaseNote.value(num);
    });

    cc = MIDIFunc.cc({ |value, num, chan, src|
        var vsync_val;
        if(~debug, postf("cc - num: %; val: %\n", num, value));
        if(num == 10, {
            ~controls.at(\vsync).set(value);
        });
        if(num == 11, {
            ~controls.at(\density).set(value);
        });
        if(num == 91, {
            ~controls.at(\density_detune).set(value);
        });
        vsync_val = ~getControl.value(\vsync);
        /*if(~debug, postf("vsync_val is now: %\n", vsync_val));*/
    });

    q = { on.free; off.free; cc.free; };
)

// when done:
q.value;
