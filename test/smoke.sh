#!/usr/bin/env bash
# test/smoke.sh — black-box end-to-end check against a running poe-acp-relay.
#
# Assumes: relay binary running on $POEACP_ADDR (default localhost:8080) with
# $POEACP_ACCESS_KEY set to the same value in this shell. Typically:
#
#   export POEACP_ACCESS_KEY=testsecret
#   go run ./cmd/poe-acp-relay --agent-cmd "fir --mode acp" &
#   ./test/smoke.sh
#
# Exits non-zero on failure. Prints the SSE stream to stderr for eyeballing.

set -euo pipefail

ADDR="${POEACP_ADDR:-localhost:8080}"
KEY="${POEACP_ACCESS_KEY:?POEACP_ACCESS_KEY required}"

conv="smoke-$(date +%s)"
msg="${1:-Say the word \"pong\" and stop.}"

echo "--- /healthz ---" >&2
curl -fsS "http://${ADDR}/healthz" >&2
echo >&2

echo "--- /poe settings ---" >&2
curl -fsS -H "Authorization: Bearer ${KEY}" \
     -H 'Content-Type: application/json' \
     -d '{"type":"settings"}' \
     "http://${ADDR}/poe" >&2
echo >&2

echo "--- /poe query (conv=${conv}) ---" >&2
body=$(cat <<JSON
{
  "type": "query",
  "conversation_id": "${conv}",
  "user_id": "smoke-user",
  "message_id": "msg-1",
  "query": [{"role": "user", "content": "${msg}"}]
}
JSON
)

out=$(curl -fsSN -H "Authorization: Bearer ${KEY}" \
           -H 'Content-Type: application/json' \
           --data-raw "$body" \
           "http://${ADDR}/poe")
echo "$out" >&2

echo "$out" | grep -q '^event: meta'  || { echo "FAIL: no meta" >&2; exit 1; }
echo "$out" | grep -q '^event: text'  || { echo "FAIL: no text" >&2; exit 1; }
echo "$out" | grep -q '^event: done'  || { echo "FAIL: no done" >&2; exit 1; }
echo "--- /debug/sessions ---" >&2
curl -fsS -H "Authorization: Bearer ${KEY}" "http://${ADDR}/debug/sessions" >&2
echo >&2
echo "OK"
