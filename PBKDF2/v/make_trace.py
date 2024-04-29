#!/bin/python3

import hashlib
import hmac

bytes_36 = bytes((x ^ 0x36) for x in range(256))
bytes_5C = bytes((x ^ 0x5C) for x in range(256))

def make_trace_for(key: str, message: str) -> [str]:
    # Known working hmac
    correct = hmac.new(key.encode(), message.encode(), hashlib.sha256).hexdigest()
    
    # hmac reimpl to verify information
    key_bytes = key.encode()
    message_bytes = message.encode()

    if (len(key) < 64):
        key_bytes += b"\x00" * (64 - len(key_bytes))

    i_key_pad = key_bytes.translate(bytes_36)
    # print(f"# i_key_pad: {i_key_pad.hex()}")

    o_key_pad = key_bytes.translate(bytes_5C)
    # print(f"# o_key_pad: {o_key_pad.hex()}")

    hash_sum_1 = hashlib.sha256(i_key_pad + message_bytes)

    # print(f"# hash_sum_1 input: {(i_key_pad+message_bytes).hex()}")
    print(f"# first hash: {hash_sum_1.digest().hex()}")

    hash_sum_2 = hashlib.sha256(o_key_pad + hash_sum_1.digest())
    # print(f"Length of hash_2 input: {len(o_key_pad + hash_sum_1.digest())}")

    print(f"# second hash: {hash_sum_2.hexdigest()}")

    # print(f"# correct: {correct}")
    assert hash_sum_2.hexdigest() == correct
    # end reimpl

    
    # create traces
    lines: [str] = []

    send_line: str = "0001_"

    # append message length
    send_line += "_" + format(len(message), "06b")

    # append key
    if (len(key) > 64):
        print("Key is too long to send!")

    for c in key:
        send_line += "_" + format(int(ord(c)), "08b")
    
    send_line += "_00000000" * (64 - len(key))

    # append message
    if (len(message) > 55):
        print("Message is too long to send!")

    for c in message:
        send_line += "_" + format(int(ord(c)), "08b")
    send_line += "_10000000"
    send_line += "_00000000" * (63 - len(message))

    pad = "80" + (61-len(message)) * "00" + format(8*(64+len(message)), "04x")


    lines.append(f"# Send pass:  `{key}`")
    lines.append(f"#      salt:  `{message}`")
    lines.append(f"# sha256 in:  `{i_key_pad.hex()+message_bytes.hex()+pad}`")
    lines.append(send_line)

    read_line = "0010__000000" + ("_00000000" * 96)

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
    lines += make_trace_for("key", "message")

    print("\n".join(lines))
