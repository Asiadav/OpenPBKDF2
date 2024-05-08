#!/bin/python3

import hashlib
import hmac

def make_trace_for(password: str, salt: str, iters: int, chunks: int) -> [str]:

    correct = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), iters).hex()
    chunk = 1
    # reimplimentation for debugging
    salt_bytes = salt.encode() + chunk.to_bytes(4, "big")
    pass_bytes = password.encode()
    initial = hmac.new(pass_bytes, salt_bytes, hashlib.sha256).hexdigest()
    # print(f"# hmac 1: {initial}")

    prev = initial
    out = initial
    for i in range(iters-1):
        new = hmac.new(pass_bytes, bytes.fromhex(prev), hashlib.sha256).hexdigest()
        out = hex(int(out, 16) ^ int(new, 16))
        prev = new
        # print(f"# hmac {i+2}: {new}")
    out = out[2:]

    print(f"# pbkdf2: {out}")

    assert out == correct
    # end reimpl


    
    # create traces
    lines: [str] = []

    send_line: str = "0" * 24 

    # append num chunks 
    send_line += format(chunks, "02b")

    # append salt length
    send_line += format(len(salt), "06b")

    # append iterations
    send_line += format(iters, "032b")

    # append password
    for c in password:
        send_line += format(int(ord(c)), "08b")
    
    send_line += "00000000" * (64 - len(password))

    # append salt

    for c in salt:
        send_line += format(int(ord(c)), "08b")
    send_line += "00000000" * (64 - len(salt))


    lines.append(f"# Send pass:  `{password}`")
    lines.append(f"#      salt:  `{salt}`")
    lines.append(f"#      iter:  `{iters}'")
    lines.append(f"#    chunks:  `{chunks}`")

    for i in range(len(send_line), 0, -64):
        lines.append("0001_0_00000000000_" + send_line[i-64:i])



    read_line = "" 

    for i in range(0, 64, 2):
        byte = correct[i:i+2]
        read_line += format(int(byte, 16), "08b")

    read_line += "00000000" * 96

    

    lines.append("")
    lines.append(f"# Receive `{correct}`")

    for i in range(len(read_line), 0, -64):
        lines.append("0010_0_00000000000_" + read_line[i-64:i])
    
    return lines


if __name__ == "__main__":
    lines: [str] = []
    lines += make_trace_for("password", "salt", 1024, 1)

    print("\n".join(lines))
