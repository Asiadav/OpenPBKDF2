#!/bin/python3

import hashlib
import hmac

bytes_36 = bytes((x ^ 0x36) for x in range(256))
bytes_5C = bytes((x ^ 0x5C) for x in range(256))

def make_trace_for(key: str, message: str) -> [str]:

    key_bytes = key.encode()
    message_bytes = message.encode()

    if (len(key) < 64):
        key_bytes += b"\x00" * (64 - len(key_bytes))

    i_key_pad = key_bytes.translate(bytes_36)
    print(f"# i_key_pad: {i_key_pad.hex()}")

    hash_sum = hashlib.sha256(i_key_pad + message_bytes).digest().hex()

    print(f"# hash_sum input: {(message_bytes + i_key_pad).hex()}")
    print(f"# hash_sum: {hash_sum}")

    # create traces
    lines: [str] = []

    send_line: str = "0001__"


    for i in range(0, 128, 2):
        byte = i_key_pad.hex()[i:i+2]
        send_line += format(int(byte, 16), "08b") + "_"
        

    for c in message:
        send_line += format(int(ord(c)), "08b") + "_"
    send_line += "10000000"
    send_line += "_00000000" * (62 - len(message))

    send_line += "_" + format(64+len(message), "08b")

    lines.append(f"# Send pass:  `{key}`")
    lines.append(f"#      salt:  `{message}`")
    lines.append(send_line)

    read_line = "0010_" + ("_00000000" * 96)

    for i in range(0, 64, 2):
        byte = hash_sum[i:i+2]
        read_line += "_" + format(int(byte, 16), "08b")

    lines.append("")
    lines.append(f"# Receive `{hash_sum}`")
    lines.append(read_line)
    lines.append("\n")
    
    return lines


if __name__ == "__main__":
    lines: [str] = []
    lines += make_trace_for("super secret passcode", "extra salty salt")

    print("\n".join(lines))
