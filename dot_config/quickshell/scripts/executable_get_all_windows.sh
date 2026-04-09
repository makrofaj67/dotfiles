#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# GET ALL WINDOWS - virtual-desktops plugin compatible
#═══════════════════════════════════════════════════════════════════════════════
# Formula: VDESK = ceil(WS_ID / NUM_MONITORS)
# 2 monitors: WS 1,2 → VDESK 1 | WS 3,4 → VDESK 2 | ... | WS 17,18 → VDESK 9
# 1 monitor:  WS 1 → VDESK 1 | WS 2 → VDESK 2 | ... | WS 9 → VDESK 9
#═══════════════════════════════════════════════════════════════════════════════

# Get monitor count
NUM_MONITORS=$(hyprctl monitors -j | jq 'length')

# Fallback to 1 if no monitors detected
[[ "$NUM_MONITORS" -lt 1 ]] && NUM_MONITORS=1

hyprctl clients -j | jq --argjson nm "$NUM_MONITORS" '[
    .[]
    | select(.workspace.id >= 1)
    | .vdesk = (((.workspace.id - 1) / $nm | floor) + 1)
    | select(.vdesk >= 1 and .vdesk <= 9)
    | {
        vdesk: .vdesk,
        address: .address,
        title: .title,
        class: .class,
        monitor: .monitor,
        workspace: .workspace,
        at: .at,
        size: .size
    }
]'
