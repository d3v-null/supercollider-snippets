from __future__ import division

import os
import wave
import math
import struct
import functools
from scipy import signal
import argparse

WAVE_TYPES = {
    'square': lambda angle, param: signal.square(angle, duty=param),
    'trisaw': lambda angle, param: signal.sawtooth(angle, width=param),
    'sin': lambda angle, _: math.sin(angle),
}
DEFAULT_HOME_DIR = os.path.expanduser('~')
DEFAULT_TONE_DIR = os.path.join(DEFAULT_HOME_DIR, 'music/samples/Tones')

def main():

    parser = argparse.ArgumentParser(description="generate a tone in a wav file")
    parser.add_argument('--dir', help="the tone directory", default=DEFAULT_TONE_DIR)
    parser.add_argument('--freq', help="the frequency of the tone", default=100, type=float)
    parser.add_argument('--type', help="the wave type", default="sin", choices=WAVE_TYPES.keys())
    parser.add_argument('--param', help="(optional) a parameter for the wave function", type=float, default=0.5)
    parser.add_argument('--amp', help="the amplitude of the wave function", type=float, default=0.9)
    parser.add_argument('--len', help="the length of the samele (seconds)", type=float, default=5.0)
    parser.add_argument('--chan', help="the number of channels", type=int, default=2)
    parser.add_argument('--swidth', help="the sample width (bytes)", type=int, default=2)
    parser.add_argument('--srate', help="the sample rate (samples / second)", type=int, default=44100)


    args = parser.parse_args()

    sig_amp = 2 ** (8 * args.swidth - 1) - 1

    wave_name = "%s_f%07.1f_p%0.3f.wav" % (args.type, args.freq, args.param)
    wave_path = os.path.join(args.dir, wave_name)

    assert args.type in WAVE_TYPES, 'invalid wave type'
    wave_func = WAVE_TYPES[args.type]

    print wave_path

    if args.dir and not os.path.exists(args.dir):
        os.makedirs(args.dir)

    if not os.path.exists(wave_path):
        with open(wave_path, 'a+'):
            pass

    wave_obj = wave.open(wave_path, 'w')
    wave_obj.setnchannels(args.chan)
    wave_obj.setsampwidth(args.swidth)
    wave_obj.setframerate(args.srate)

    for i in range(int(args.srate * args.len)):
        seconds = i / args.srate
        angle = 2 * math.pi * seconds * args.freq
        sig = args.amp * sig_amp * wave_func(angle, args.param)
        packed_signal = struct.pack('h', sig)
        for c in range(args.chan):
            wave_obj.writeframes(packed_signal)

if __name__ == '__main__':
    main()
