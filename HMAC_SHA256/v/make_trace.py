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

    print(hash_sum_2.hexdigest())
    assert hash_sum_2.hexdigest() == correct
    # end reimpl

    lines: [str] = []
    return lines


if __name__ == "__main__":
    lines: [str] = []
    lines += make_trace_for("key", "The quick brown fox jumps over the lazy dog")
    # lines += make_trace_for("123456789012345678901234567890123456780123456789012345")

    print("\n".join(lines))
