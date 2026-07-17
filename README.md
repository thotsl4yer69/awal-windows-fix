# awal Windows fix

The Coinbase `awal` CLI (Agentic Wallet, v2.12.x) is broken on Windows in two ways:

1. **`Failed to start server: spawn EINVAL`** — the CLI spawns `electron.cmd` without `shell: true`. Node >= 18.20 / 20.12 / 21.7 (CVE-2024-27980 hardening) rejects spawning `.cmd` files that way, so the wallet server never starts.
2. **Every CLI request silently times out** — the wallet's bridge validates requesters by running `ps -p <pid> -o command=`, a Unix command that does not exist on Windows. The validation throws, the bridge rejects the request, and the CLI reports `Request timed out. The wallet may be unresponsive.`

`fix-awal.ps1` works around both without modifying awal itself:

- installs a tiny `ps.cmd` shim that faithfully reproduces the original check (resolves the PID's command line via CIM and answers `awal-cli` only for genuine awal/payments-mcp processes)
- starts the wallet's Electron server manually with the shim on its `PATH`

## Usage

```powershell
# after at least one (failed) run of: npx awal status
powershell -ExecutionPolicy Bypass -File .\fix-awal.ps1
npx awal status   # should now report the server running
```

Re-run `fix-awal.ps1` after reboots (or register it as a scheduled task).

## Security note

The shim answers `awal-cli` only when the requesting PID's command line matches awal/payments-mcp/bundle-electron — the same intent as the original Unix check. It does not weaken validation beyond platform parity.

---

*Found while wiring a Claude agent into the agent economy. Related: [Agent Work Radar](https://github.com/thotsl4yer69/agent-work-radar) — a paid x402 API aggregating open work for AI agents.*
