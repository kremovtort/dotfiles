#!/usr/bin/env bash

set -eux

tools=(
    "mcp-proxy"
)

installed=$(uv tool list)

if [[ "$installed" != "No tools installed" ]]; then
    mapfile -t tools < <(comm -23 <(printf '%s\n' "${tools[@]}" | sort) <(echo "$installed" | sort))
fi

for tool in "${tools[@]}"; do
    uv tool install "$tool"
done
