---
date: 2026-01-11T12:00:00-08:00
researcher: Claude
topic: "Mobile access to Claude Code sessions from phone"
tags: [research, mobile, remote-access, claude-code, security]
status: complete
last_updated: 2026-01-11
---

# Research: Mobile Access to Claude Code Sessions

**Date**: 2026-01-11
**Researcher**: Claude
**Research Type**: Integration / Tools

## Research Question

How can a user access long-running Claude Code sessions from a Google Pixel Android phone, with options including:
- Direct Claude Code access
- Terminal viewing/mirroring
- tmux configuration
- Windows remote viewing
- Other identified options

Security is critical. Simplicity is preferred over full desktop remote viewing (e.g., prefer terminal-like experience over full Windows RDP).

## Summary

- **Best option for security + simplicity**: SSH via Tailscale + tmux with a quality mobile SSH client (Termius or JuiceSSH)
- **Best purpose-built solution**: Happy Coder - end-to-end encrypted mobile client designed specifically for Claude Code
- **Lightweight browser option**: Muxile tmux plugin (convenient but lower security - no E2E encryption)
- **Full Windows access if needed**: Microsoft RDP or Chrome Remote Desktop (less simple, but secure)
- Avoid solutions without encryption when handling sensitive code or credentials

## Detailed Findings

### Option 1: Happy Coder (Purpose-Built Claude Code Mobile Client)

**Security**: Excellent - End-to-end encrypted using TweetNaCl (same as Signal)

**How it works**:
- Install CLI: `npm install -g happy-coder`
- Run `happy` instead of `claude` to start sessions
- Scan QR code to pair mobile app with desktop
- Zero-knowledge architecture - relay server only handles encrypted blobs

**Pros**:
- Purpose-built for Claude Code
- Push notifications for permission requests and task completion
- Access conversation history even when terminal is offline
- Open source and auditable
- Available on [Google Play](https://play.google.com/store/apps/details?id=com.ex3ndr.happy)

**Cons**:
- Third-party tool (not from Anthropic)
- Requires replacing `claude` command with `happy`

**Setup complexity**: Low (npm install + QR scan)

**References**:
- [Happy Coder Website](https://happy.engineering/)
- [GitHub Repository](https://github.com/slopus/happy)
- [Google Play Store](https://play.google.com/store/apps/details?id=com.ex3ndr.happy)

---

### Option 2: Tailscale + tmux + SSH Client (Most Flexible)

**Security**: Excellent - WireGuard-based VPN with zero-trust architecture

**How it works**:
1. Install Tailscale on your VM/WSL host and your phone
2. Start Claude Code in a tmux session: `tmux new -s claude`
3. SSH from phone to your machine via Tailscale network
4. Reattach to tmux session: `tmux attach -t claude`

**Recommended SSH Clients for Android**:

| App | Pros | Cons |
|-----|------|------|
| **Termius** | Best UI, Mosh support, vault encryption | Premium features cost |
| **JuiceSSH** | Free, excellent performance, biometric auth | Less fancy UI |
| **Termux** | Full Linux environment, can run tmux locally too | Steeper learning curve |
| **ConnectBot** | Open source, lightweight | Basic UI |

**Tailscale Security Features**:
- End-to-end WireGuard encryption
- SOC 2 Type II certified
- No open ports on your machines
- MFA via SSO providers
- Device authorization required

**Pros**:
- True terminal experience (matches Windows Terminal Preview feel)
- Works across any network (no port forwarding needed)
- Session persists with tmux - disconnect and reconnect anytime
- Can run multiple Claude Code instances in different tmux windows

**Cons**:
- Requires Tailscale account (free tier available)
- Initial setup more involved

**tmux configuration for mobile**:
```bash
# Add to ~/.tmux.conf
set -g mouse on                 # Enable touch/mouse scrolling
set -g history-limit 50000      # Keep more history
set -g status-position top      # Status bar at top for mobile
```

**References**:
- [Tailscale Security](https://tailscale.com/security)
- [tmux + Tailscale for Claude Code](https://sameerhalai.com/blog/access-your-desktop-claude-code-session-from-your-phone-using-tmux-tailscale/)
- [Termius Android](https://play.google.com/store/apps/details?id=com.server.auditor.ssh.client)

---

### Option 3: Muxile (tmux Browser Plugin)

**Security**: Low - No end-to-end encryption, data passes through Cloudflare relay

**How it works**:
- Install tmux plugin
- Press keybinding to generate QR code
- Scan with phone to view/control session in browser

**Pros**:
- No app installation on phone (browser-based)
- Very quick to set up
- Works for monitoring long-running processes

**Cons**:
- **No encryption** - terminal data passes through third-party servers unencrypted
- Not suitable for sensitive code or credentials
- Requires active session on computer to start sharing

**When to use**: Only for non-sensitive monitoring of public/non-sensitive processes

**References**:
- [Muxile GitHub](https://github.com/bjesus/muxile)

---

### Option 4: Claude Code UI (Web Interface)

**Security**: Limited - No built-in authentication or encryption for remote access

**How it works**:
- Install: `npx @siteboon/claude-code-ui`
- Access via browser on any device
- Responsive design for mobile

**Pros**:
- Full web UI for Claude Code
- PWA support (add to home screen)
- Tools disabled by default (must opt-in)

**Cons**:
- **No authentication** by default
- **No encryption** for remote access
- Would need to add security layers (reverse proxy with auth, HTTPS) for safe remote use

**When to use**: Only on trusted local networks, or with additional security configuration

**References**:
- [Claude Code UI GitHub](https://github.com/siteboon/claudecodeui)

---

### Option 5: Windows Remote Desktop (RDP)

**Security**: Good - Native Windows encryption, supports NLA

**How it works**:
- Enable Remote Desktop on Windows host
- Use Microsoft Remote Desktop app on Android
- Connect directly or via Tailscale for better security

**Pros**:
- Full Windows access
- Native Microsoft solution
- Good performance with modern RDP

**Cons**:
- Full screen view (not terminal-focused like requested)
- Heavier bandwidth usage
- Requires Windows Pro/Enterprise for host

**Android Apps**:
- [Microsoft Remote Desktop](https://play.google.com/store/apps/details?id=com.microsoft.rdc.android)

---

### Option 6: Chrome Remote Desktop

**Security**: Good - Google authentication, encrypted connection

**Pros**:
- Free
- Easy setup
- Works on Windows Home

**Cons**:
- Full screen view (not minimal terminal)
- Requires Chrome browser on host

---

## Architecture Insights

Your current setup (WSL + tmux on VM via SSH) is already well-suited for mobile access:

```
[Pixel Phone]
    |
    | Tailscale encrypted tunnel
    v
[Windows Host / VM]
    |
    | SSH via Tailscale IP
    v
[tmux session running Claude Code]
```

The key additions needed:
1. Tailscale on phone + host (creates secure network)
2. Quality SSH app on phone
3. Named tmux sessions for easy reattachment

## Feasibility Assessment

**All options are feasible with your current setup.** Recommended approach based on your requirements:

| Requirement | Best Match |
|-------------|------------|
| Security critical | Happy Coder or Tailscale+SSH |
| Terminal-like experience | Tailscale+SSH+tmux with Termius/JuiceSSH |
| Simplicity | Happy Coder (npm install + QR) |
| Permission handling | Happy Coder (push notifications) |
| Works with existing tmux workflow | Tailscale+SSH |

## Recommendations

### Primary Recommendation: Tailscale + Termius + tmux

This matches your stated preferences best:
- **Security**: WireGuard encryption end-to-end
- **Simplicity**: Termius provides terminal experience similar to Windows Terminal Preview
- **Works with existing tmux**: Seamlessly attach to running sessions
- **Handles permissions**: You can respond to Claude prompts directly in the terminal

**Setup steps**:
1. Install Tailscale on your VM host and Android phone
2. Install Termius on your Pixel
3. Configure Termius with your Tailscale hostname/IP
4. Start Claude Code in tmux: `tmux new -s claude-dev`
5. From phone: SSH in and `tmux attach -t claude-dev`

### Secondary Recommendation: Happy Coder

If you want a more purpose-built solution with push notifications for permissions:
1. `npm install -g happy-coder`
2. Install Happy Coder from Google Play
3. Pair via QR code
4. Run `happy` instead of `claude`

### Avoid

- **Muxile**: Convenient but no encryption - unsuitable for sensitive work
- **Claude Code UI without additional security**: No auth by default
- **Full RDP solutions**: Overkill for terminal-focused workflow

## Open Questions

1. Do you need to interact with multiple concurrent Claude Code sessions, or typically just one?
2. Is your VM accessible via Tailscale already, or would you need to set that up?
3. Do you have specific concerns about third-party tools (Happy Coder) vs. infrastructure-level solutions (Tailscale)?

## Security Comparison Matrix

| Solution | Encryption | Authentication | Open Source | Self-hostable |
|----------|------------|----------------|-------------|---------------|
| Happy Coder | E2E (TweetNaCl) | QR pairing | Yes | Relay server yes |
| Tailscale+SSH | WireGuard | SSH keys + Tailscale | Partial | No (uses coord server) |
| Muxile | None | QR only | Yes | Yes |
| Claude Code UI | None | None by default | Yes | Yes |
| RDP | TLS | Windows auth | No | N/A |
| Chrome Remote | Google TLS | Google account | No | No |

---

**Related Commands:**
- After setup: Test connection and document in project notes

**Sources:**
- [Happy Coder](https://happy.engineering/)
- [Tailscale](https://tailscale.com/)
- [Termius](https://termius.com/)
- [Muxile](https://github.com/bjesus/muxile)
- [Claude Code UI](https://github.com/siteboon/claudecodeui)
