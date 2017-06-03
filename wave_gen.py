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

    args = parser.parse_args()

    sample_rate = 44100
    channels = 2
    sig_amp = 32767
    sample_len = int(sample_rate * args.len)

    wave_name = "%s_%07.1f_%0.3f.wav" % (args.type, args.freq, args.param)
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
    wave_params = (2, channels, sample_rate, 0, 'NONE', 'not compressed')
    wave_obj.setparams(wave_params)
    for i in range(sample_len):
        seconds = i / sample_rate
        angle = 2 * math.pi * seconds * args.freq
        sig = args.amp * sig_amp * wave_func(angle, args.param)
        packed_signal = struct.pack('h', sig)
        for c in range(channels):
            wave_obj.writeframes(packed_signal)

if __name__ == '__main__':
    main()
