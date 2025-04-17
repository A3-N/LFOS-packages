# LeanFreak OS Package Repository

This is the official custom package repository for [LeanFreak OS](https://github.com/A3-N/LeanFreak).

It includes curated and purpose-built packages used across LeanFreak system tooling, including system configuration utilities, installer components, and lightweight enhancements.

To add this repository to your system, edit your `/etc/pacman.conf` and include:

```ini
[lfos]
SigLevel = Optional TrustAll
Server = https://adriaanbosch.com/repo/
```

sync


```sh
pacman -Sy

```

_You might face some dependency hell since this was made for LFOS and not necessary your build. This is also some of my personal stuff, so dont consider this your next production build._


# Packages

## getfreaky

Install script - after booting `leanfreak-v*-x86_64.iso`

- [ ] Todo - make install script (oops lol)

## lf-stackmask

This package acts as a **Stack Masquerading & Network Stealth Tool**

`lf-stackmask` is a network stack spoofing utility designed for stealthy or hardened deployments on LeanFreak OS. It manipulates system-level TCP/IP characteristics to mimic different operating systems or obscure fingerprintable traits in outbound traffic.

#### Specs:

- Modifies outbound TTL (Time To Live) to 128 to resemble Windows systems (default Linux is 64)
- Clamps TCP MSS (Maximum Segment Size) to 1460 — mimicking NATed or Windows hosts
- Drops ICMP echo-request packets (disables ping responses) to reduce visibility on the network
- Disables TCP timestamps via sysctl to prevent passive OS fingerprinting from tools like Zeek, p0f, or DPI middleboxes
- Applies artificial packet delay (via tc netem) to simulate human-like interaction or hide scripted automation
- Disables avahi-daemon to eliminate mDNS advertisement and reduce local network discovery exposure
- Persists and reverts system modifications cleanly using snapshots and tracked changes

#### Use Case:

Stack fingerprinting is a common technique in:

- Network security monitoring (e.g., Zeek, IDS/IPS)
- Red team infrastructure detection
- Device classification and segmentation

`lf-stackmask` provides a controlled way to masquerade your Linux system as a different host type (e.g., a Windows box behind a router), while ensuring clean reversion and system stability.

#### Usage

```sh
lf-stackmask start   # Apply spoofing rules
lf-stackmask stop    # Revert to previous state
```

or 

```sh
systemctl enable lf-stackmask
systemctl start lf-stackmask
```

#### whereami

```
/usr/local/bin/lf-stackmask.sh	            #Main executable script
/etc/systemd/system/lf-stackmask.service    #Optional systemd integration
/var/lib/lf-stackmask/	                    #Snapshot + tracking state
```

