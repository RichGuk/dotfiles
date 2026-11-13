#!/bin/bash
# Claude Code hook (Stop, SessionEnd) for Herdr's agents list: puts the agent's
# model, context size and prompt-cache lifetime on its herdr-core terminal as
# the label agent.ctx = "model|tokens|ttl seconds|unix time of the last reply".
# SessionEnd clears it. Outside an hc terminal it does nothing. Needs jq.

[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
hc=$(command -v hc || echo "$HOME/.local/bin/hc")
input=$(cat)

if [ "$(jq -r '.hook_event_name // ""' <<<"$input")" = SessionEnd ]; then
  "$hc" label "$HC_TERMINAL_ID" agent.ctx= >/dev/null 2>&1
  exit 0
fi

f=$(jq -r '.transcript_path // ""' <<<"$input")
[ -f "$f" ] || exit 0

# The last reply's usage: everything it read is the context. A reply that wrote
# only 5-minute cache gets 5 minutes; otherwise (1-hour writes, or reads only) an hour.
ctx=$(tail -c 524288 "$f" | grep -a '"usage":{' | grep -a '"type":"assistant"' | tail -n 1 | jq -r '
  .message as $m | $m.usage as $u | select($m.model != "<synthetic>")
  | [$m.model,
     ($u.input_tokens + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)),
     (if ($u.cache_creation.ephemeral_1h_input_tokens // 0) > 0 or ($u.cache_creation.ephemeral_5m_input_tokens // 0) == 0 then 3600 else 300 end),
     (.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdate)]
  | map(tostring) | join("|")' 2>/dev/null)

[ -n "$ctx" ] && "$hc" label "$HC_TERMINAL_ID" "agent.ctx=$ctx" >/dev/null 2>&1
exit 0
