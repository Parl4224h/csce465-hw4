#!/usr/bin/env bash
set -euo pipefail

# Must run as root.
if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo."
    exit 1
fi

# Enable filtering for traffic switched across Docker bridges.
modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-iptables=1

AGENT="172.30.0.10"
WEB="172.30.0.40"
C2="172.30.0.66"
BRIDGE="br-hw4"
CHAIN="HW4-EGRESS"

# Ensure Docker's forwarding chain exists.
iptables -nL DOCKER-USER >/dev/null

# Create the dedicated chain if necessary.
iptables -N "$CHAIN" 2>/dev/null || true

# Clear only the course rules.
iptables -F "$CHAIN"

# 1. Allow established and related traffic.
iptables -A "$CHAIN" \
    -m conntrack --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

# 2. Allow agent-node to access web-lab on TCP 8000.
iptables -A "$CHAIN" \
    -s "$AGENT" -d "$WEB" \
    -p tcp --dport 8000 \
    -m conntrack --ctstate NEW \
    -j ACCEPT

# 3. Log new connections to mock-C2 on TCP 8080.
iptables -A "$CHAIN" \
    -s "$AGENT" -d "$C2" \
    -p tcp --dport 8080 \
    -m conntrack --ctstate NEW \
    -j LOG --log-prefix "HW4-C2-DROP: " \
    --log-level 4

# Drop the logged connections.
iptables -A "$CHAIN" \
    -s "$AGENT" -d "$C2" \
    -p tcp --dport 8080 \
    -m conntrack --ctstate NEW \
    -j DROP

# 4. Default-deny all other NEW agent connections.
iptables -A "$CHAIN" \
    -s "$AGENT" \
    -m conntrack --ctstate NEW \
    -j DROP

# 5. Leave unrelated traffic unchanged.
iptables -A "$CHAIN" -j RETURN

# Connect the course chain to Docker's forwarding rules.
if ! iptables -C DOCKER-USER \
    -i "$BRIDGE" -j "$CHAIN" 2>/dev/null; then
    iptables -I DOCKER-USER 1 \
        -i "$BRIDGE" -j "$CHAIN"
fi

echo "HW4 firewall enabled."
iptables -L "$CHAIN" -n -v --line-numbers
