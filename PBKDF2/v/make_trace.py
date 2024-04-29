#!/bin/python3

import hashlib
import hmac

def make_trace_for(password: str, salt: str, iters: int) -> [str]:

    correct = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), iters).hex()
    chunk = 1
    # reimplimentation for debugging
    salt_bytes = salt.encode() + chunk.to_bytes(4, "big")
    pass_bytes = password.encode()
    initial = hmac.new(pass_bytes, salt_bytes, hashlib.sha256).hexdigest()
    print(f"# hmac 1: {initial}")

    prev = initial
    out = initial
    for i in range(iters-1):
        new = hmac.new(pass_bytes, bytes.fromhex(prev), hashlib.sha256).hexdigest()
        out = hex(int(out, 16) ^ int(new, 16))
        prev = new
        print(f"# hmac {i+2}: {new}")
    out = out[2:]

    print(f"# pbkdf2: {out}")

    assert out == correct
    # end reimpl


    
    # create traces
    lines: [str] = []

    send_line: str = "0001_"

    # append salt length
    send_line += "_" + format(len(salt_bytes), "06b")

    # append iterations
    send_line += "_" + format(iters, "032b")

    # append password
    for c in password:
        send_line += "_" + format(int(ord(c)), "08b")
    
    send_line += "_00000000" * (64 - len(password))

    # append salt

    for b in salt_bytes:
        send_line += "_" + format(int(b), "08b")
    send_line += "_00000000" * (64 - len(salt_bytes))


    lines.append(f"# Send pass:  `{password}`")
    lines.append(f"#      salt:  `{salt}`")
    lines.append(f"#      iter:  `{iters}'")
    lines.append(send_line)

    read_line = "0010__000000_" + "0" * 32 + ("_00000000" * 96)

    for i in range(0, 64, 2):
        byte = correct[i:i+2]
        read_line += "_" + format(int(byte, 16), "08b")

    lines.append("")
    lines.append(f"# Receive `{correct}`")
    lines.append(read_line)
    lines.append("\n")
    
    return lines


if __name__ == "__main__":
    lines: [str] = []
    lines += make_trace_for("password", "salt", 2)

    print("\n".join(lines))
