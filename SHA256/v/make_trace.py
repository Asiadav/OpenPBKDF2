#!/bin/python3

import hashlib

def make_trace_for(input: str) -> [str]:
    if (len(input) > 55):
        print("Too complex to pad")
        return []

    lines: [str] = []

    sha256 = hashlib.new("sha256")

    send_line: str = "0001__"
    chunk_bytes: bytes = input.encode()

    for i in range(0, len(input)):
        send_line += format(chunk_bytes[i], "08b") + "_"
    
    send_line += "10000000_"
    
    for _ in range(len(input) + 1, 56):
        send_line += "00000000_"

    for _ in range(6):
        send_line += "00000000_"

    length: str = format(len(input) * 8, "09b")

    send_line += f"0000000{length[0]}_{length[1:]}"

    lines.append(f"# Send `{input}`")
    lines.append(send_line)

    
    sha256.update(input.encode())
    digest = sha256.hexdigest()

    read_line = "0010_"
    for i in range(0, 32):
        read_line += "_00000000"

    for i in range(0, 64, 2):
        byte = digest[i:i+2]
        read_line += "_" + format(int(byte, 16), "08b")

    lines.append("")
    lines.append(f"# Receive `{digest}`")
    lines.append(read_line)

    return lines


if __name__ == "__main__":
    lines: [str] = make_trace_for("123456789012345678901234567890123456780123456789012345")

    print("\n".join(lines))
