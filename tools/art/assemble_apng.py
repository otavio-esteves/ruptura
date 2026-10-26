#!/usr/bin/env python3
"""Package captured PNG frames as APNG without repainting or resampling them."""
from pathlib import Path
import argparse
import struct
import zlib

SIGNATURE = b'\x89PNG\r\n\x1a\n'

def chunks(data):
    if not data.startswith(SIGNATURE):
        raise ValueError('Not a PNG frame')
    offset = len(SIGNATURE)
    while offset < len(data):
        length = struct.unpack_from('>I', data, offset)[0]
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + length]
        if zlib.crc32(kind + payload) != struct.unpack_from('>I', data, offset + 8 + length)[0]:
            raise ValueError('PNG checksum failed')
        yield kind, payload
        offset += length + 12

def chunk(kind, payload):
    return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('frames', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--fps', type=int, default=12)
    args = parser.parse_args()
    if not 1 <= args.fps <= 60:
        parser.error('fps must be in 1..60')
    paths = sorted(args.frames.glob('frame_*.png'))
    if not paths:
        parser.error('No captured frames')
    sequence = 0
    result = bytearray(SIGNATURE)
    header = None
    for index, path in enumerate(paths):
        source = list(chunks(path.read_bytes()))
        current = next(payload for kind, payload in source if kind == b'IHDR')
        if index == 0:
            header = current
            result += chunk(b'IHDR', header)
            result += chunk(b'acTL', struct.pack('>II', len(paths), 0))
        elif current != header:
            raise ValueError('All frames must have the same format and dimensions')
        width, height = struct.unpack_from('>II', header)
        result += chunk(b'fcTL', struct.pack('>IIIIIHHBB', sequence, width, height, 0, 0, 1, args.fps, 0, 0))
        sequence += 1
        compressed = b''.join(payload for kind, payload in source if kind == b'IDAT')
        if index == 0:
            result += chunk(b'IDAT', compressed)
        else:
            result += chunk(b'fdAT', struct.pack('>I', sequence) + compressed)
            sequence += 1
    result += chunk(b'IEND', b'')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(result)
    print(f'APNG={args.output} FRAMES={len(paths)} FPS={args.fps} BYTES={len(result)}')

if __name__ == '__main__':
    main()
