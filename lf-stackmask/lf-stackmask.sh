#!/bin/bash
set -e

SNAPSHOT_DIR="/var/lib/lf-stackmask"
SNAPSHOT_FILE="$SNAPSHOT_DIR/snapshot.txt"
TC_FILE="$SNAPSHOT_DIR/tc.rules"
RULES_ADDED="$SNAPSHOT_DIR/rules-added.log"

mkdir -p "$SNAPSHOT_DIR"

get_iface() {
    ip route get 1 | awk '{print $5; exit}'
}
IFACE=$(get_iface)

log() {
    echo "[*] $*"
}

snapshot() {
    log "Taking system state snapshot..."
    log "Detected interface: $IFACE"
    sysctl net.ipv4.ip_default_ttl > "$SNAPSHOT_FILE"
    tc qdisc show dev "$IFACE" > "$TC_FILE"
}

add_rule() {
    local rule="$1"
    if ! iptables $rule 2>/dev/null; then
        iptables ${rule/-C/-A}
        echo "$rule" >> "$RULES_ADDED"
        log "Added rule: iptables ${rule/-C/-A}"
    else
        log "Rule already exists: $rule"
    fi
}

remove_added_rules() {
    if [ -f "$RULES_ADDED" ]; then
        log "Removing rules added by lf-stackmask..."
        while IFS= read -r rule; do
            if iptables $rule 2>/dev/null; then
                iptables ${rule/-C/-D}
                log "Removed rule: iptables ${rule/-C/-D}"
            fi
        done < "$RULES_ADDED"
        rm -f "$RULES_ADDED"
    else
        log "No tracked rules to remove."
    fi
}

apply_lf_stackmask() {
    snapshot

    log "Setting TTL to 128"
    sysctl -w net.ipv4.ip_default_ttl=128

    log "Disabling TCP timestamps"
    sysctl -w net.ipv4.tcp_timestamps=0
    echo "net.ipv4.tcp_timestamps = 0" > /etc/sysctl.d/99-lf-stackmask.conf

    log "Adding iptables rules..."
    add_rule "-C OUTPUT -t mangle -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1460"
    add_rule "-C OUTPUT -t mangle -p tcp -j TTL --ttl-set 128"
    add_rule "-C INPUT -p icmp --icmp-type echo-request -j DROP"

    log "Adding tc delay (25ms)"
    tc qdisc add dev "$IFACE" root netem delay 25ms || true
}

restore_lf_stackmask() {
    log "Restoring original system state..."

    if [ -f "$SNAPSHOT_FILE" ]; then
        sysctl -w "$(cat "$SNAPSHOT_FILE")"
    else
        log "No TTL snapshot found."
    fi

    log "Restoring TCP timestamps..."
    sysctl -w net.ipv4.tcp_timestamps=1
    rm -f /etc/sysctl.d/99-lf-stackmask.conf
    sysctl --system > /dev/null

    remove_added_rules

    log "Clearing tc qdisc on $IFACE..."
    tc qdisc del dev "$IFACE" root 2>/dev/null || true
}

case "$1" in
  start)
    apply_lf_stackmask
    ;;
  stop)
    restore_lf_stackmask
    ;;
  *)
    echo "[!] Usage: $0 {start|stop}"
    exit 1
    ;;
esac
