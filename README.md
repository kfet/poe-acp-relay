# poe-acp-relay

Poe.com server-bot that drives ACP-compliant agents (default: `fir --mode acp`)
as a pure ACP client. One binary, no MCP server surface. Each Poe
`conversation_id` maps 1:1 to an ACP session inside a shared agent process.

See [docs/poe-acp-relay/DESIGN.md](docs/poe-acp-relay/DESIGN.md) for the full
design, scope, and milestones.

Module: `github.com/kfet/fir/external/poeacp`. Standalone — not linked into
the main fir binary.

## Quick start

```bash
# build
cd external/poeacp
go build -o ./bin/poe-acp-relay ./cmd/poe-acp-relay

# run (requires fir on $PATH or --agent-cmd override)
export POEACP_ACCESS_KEY=mysecret        # match the key in your Poe bot dashboard
./bin/poe-acp-relay \
  --http-addr :8080 \
  --agent-cmd "fir --mode acp" \
  --permission allow-all

# smoke test (separate shell)
POEACP_ACCESS_KEY=mysecret ./test/smoke.sh
```

Point your Poe bot at `https://<host>/poe` (with any reverse proxy or
`tailscale funnel` fronting the plain HTTP port).

## Endpoints

| Path                | Auth   | Purpose                                |
|---------------------|--------|----------------------------------------|
| `POST /poe`         | Bearer | Poe protocol: `query`/`settings`/etc.  |
| `GET  /healthz`     | none   | `ok sessions=N`                        |
| `GET  /debug/sessions` | Bearer | JSON dump of conv → session state   |

## Flags

```
--http-addr            HTTP listen address (default :8080)
--agent-cmd            ACP agent command + args (default "fir --mode acp")
--agent-dir            FIR_AGENT_DIR passed to the child (default inherit)
--state-dir            Per-conv state root (default $XDG_STATE_HOME/poe-acp-relay)
--permission           allow-all|read-only|deny-all (default allow-all)
--access-key-env       Env var holding the Poe bearer secret (default POEACP_ACCESS_KEY)
--introduction         Poe introduction message
--session-ttl          Idle TTL for a conv (default 2h)
--gc-interval          GC sweep interval (default 5m)
--heartbeat-interval   SSE heartbeat tick (default 10s, 0 to disable)
--version              Print version and exit
```

## Tests

```
go test ./...
```

Unit tests drive the router and HTTP handler with an in-process fake
`Agent`. The `test/smoke.sh` script black-box tests a running relay over
HTTP — no fir patching required.

## Layout

```
external/poeacp/
  cmd/poe-acp-relay/       entry point
  docs/poe-acp-relay/      design doc
  internal/acpclient/      acp.Client impl + stdio agent proc wrapper
  internal/httpsrv/        /poe handler with heartbeat + cancel plumbing
  internal/poeproto/       minimal Poe HTTP+SSE
  internal/policy/         allow-all / read-only / deny-all
  internal/router/         conv_id → ACP session map + GC
  test/smoke.sh            black-box SSE smoke test
```
