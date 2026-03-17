#!/usr/bin/env python3
"""
read_fibo.py — Reads raw Fibonacci bytes from TRIX-V over UART and displays them
as annotated decimal integers.

TRIX-V sends one byte per Fibonacci number (LSB of the 32-bit CPU write).
Values <= 255 are exact; larger values wrap mod 256 (only LSB is visible).

Usage:
    python3 read_fibo.py [port] [baud]

Defaults:
    port  = /dev/ttyUSB0
    baud  = 115200

Install dependency once:
    pip install pyserial
"""

import serial
import sys

PORT = sys.argv[1] if len(sys.argv) > 1 else '/dev/ttyUSB0'
BAUD = int(sys.argv[2]) if len(sys.argv) > 2 else 115200
N    = 40   # number of Fibonacci values the firmware sends

def expected_fibs(n):
    a, b = 0, 1
    result = []
    for _ in range(n):
        a, b = b, a + b
        result.append(a)
    return result

def main():
    fibs = expected_fibs(N)
    print(f"Opening {PORT} at {BAUD} baud …")
    print()
    print(f"{'i':>3}  {'raw byte':>9}  {'actual Fib(i)':>14}  {'status'}")
    print(f"{'-'*3}  {'-'*9}  {'-'*14}  {'-'*20}")

    try:
        with serial.Serial(PORT, BAUD, timeout=5) as ser:
            for i, expected in enumerate(fibs):
                raw_bytes = ser.read(1)
                if not raw_bytes:
                    print(f"{i+1:>3}  <timeout>   {expected:>14}")
                    continue
                raw = raw_bytes[0]
                expected_lsb = expected & 0xFF
                if expected_lsb == raw:
                    note = "OK" if expected <= 255 else f"OK (truncated — full value = {expected})"
                else:
                    note = f"MISMATCH — expected 0x{expected_lsb:02X}"
                print(f"{i+1:>3}  0x{raw:02X} ({raw:>3})  {expected:>14}  {note}")
    except serial.SerialException as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
