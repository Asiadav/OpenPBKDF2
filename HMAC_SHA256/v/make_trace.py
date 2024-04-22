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
    print(f"# i_key_pad: {i_key_pad.hex()}")

    o_key_pad = key_bytes.translate(bytes_5C)
    print(f"# o_key_pad: {o_key_pad.hex()}")

    hash_sum_1 = hashlib.sha256(i_key_pad + message_bytes)

    print(f"# hash_sum_1: {hash_sum_1.digest().hex()}")

    hash_sum_2 = hashlib.sha256(o_key_pad + hash_sum_1.digest())

    print(f"# reimpl: {hash_sum_2.hexdigest()}")

    print(f"# correct: {correct}")
    assert hash_sum_2.hexdigest() == correct
    # end reimpl

    
    # create traces
    lines: [str] = []

    send_line: str = "0001__0_"

    if (len(message) < 64):
        message_bytes = b"\x00" * (64 - len(message_bytes)) + message_bytes
        
    chunk_bytes = message_bytes + key_bytes
    print(len(chunk_bytes))
    print(chunk_bytes)

    for i in range(0, len(chunk_bytes)):
        send_line += format(chunk_bytes[i], "08b") + "_"
    
    send_line += "10000000_"
    
    for _ in range(len(chunk_bytes) + 1, 56):
        send_line += "00000000_"

    for _ in range(6):
        send_line += "00000000_"

    length: str = format(len(chunk_bytes) * 8, "09b")

    send_line += f"0000000{length[0]}_{length[1:]}"

    lines.append(f"# Send pass:  `{message}` salt: `{key}`")
    lines.append(f"#      salt:  `{key}`")
    lines.append(f"#      hex: `{(message_bytes+key_bytes).hex()}`")
    lines.append(send_line)

    read_line = "0010__0"

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
    lines += make_trace_for("max key is 64 bytes", "Max password length is 64 bytes")
    # lines += make_trace_for("123456789012345678901234567890123456780123456789012345")

    print("\n".join(lines))
