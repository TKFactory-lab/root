#!/usr/bin/env python3
"""Decode a whitespace-separated decimal byte dump into a binary/text file.
Usage: decode_decimal_dump.py <input_dump.txt> <output_file>

Example: python tools/decode_decimal_dump.py scripts/crewai_webhook_receiver.py scripts/crewai_webhook_receiver.decoded.py
"""
import sys, re

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    inp, out = sys.argv[1], sys.argv[2]
    s = open(inp, 'rb').read()
    try:
        text = s.decode('utf-8')
    except Exception:
        text = s.decode('latin1')
    nums = re.findall(r"\d+", text)
    if not nums:
        print('No decimal numbers found in', inp)
        sys.exit(1)
    b = bytes(int(n) for n in nums)
    open(out, 'wb').write(b)
    print('Wrote', out, 'len', len(b))

if __name__ == '__main__':
    main()
