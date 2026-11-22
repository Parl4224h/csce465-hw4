#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo."
    exit 1
fi

CHAIN="HW4-EGRESS"
BRIDGE="br-hw4"

# Remove the jump from DOCKER-USER.
if iptables -C DOCKER-USER \
    -i "$BRIDGE" -j "$CHAIN" 2>/dev/null; then
    iptables -D DOCKER-USER \
        -i "$BRIDGE" -j "$CHAIN"
fi

# Remove only the custom chain.
if iptables -nL "$CHAIN" >/dev/null 2>&1; then
    iptables -F "$CHAIN"
    iptables -X "$CHAIN"
fi

echo "HW4 firewall rules removed."
