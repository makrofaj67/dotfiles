#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
# WORKSPACE GUARDIAN - 3x3 Grid Enforcer
#═══════════════════════════════════════════════════════════════════════════════
# Strict 1-9 workspace boundary enforcement daemon.
# Monitors Hyprland IPC socket and immediately:
#   1. Moves all windows from workspace 10+ to workspace 9
#   2. Forces focus back to valid workspace
#   3. Destroys invalid workspaces
#
# Why this exists:
# - Native `hyprctl dispatch workspace 10` bypasses virtual-desktops plugin
# - Session restore can create workspaces beyond the grid
# - Some apps may request specific workspace IDs
#═══════════════════════════════════════════════════════════════════════════════

MAX_WORKSPACE=9
FALLBACK_WORKSPACE=9
LOG_FILE="/tmp/workspace_guardian.log"

# Truncate log on start
echo "" > "$LOG_FILE"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup_invalid_workspaces() {
    local found_invalid=0
    
    # Get all invalid workspaces
    local invalid_list=$(hyprctl workspaces -j 2>/dev/null | jq -r ".[] | select(.id > $MAX_WORKSPACE) | .id" | sort -n)
    
    [[ -z "$invalid_list" ]] && return 0
    
    for ws_id in $invalid_list; do
        found_invalid=1
        log "🚨 VIOLATION: Workspace $ws_id detected!"
        
        # Move all windows from invalid workspace to fallback
        local windows=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.workspace.id == $ws_id) | .address")
        
        if [[ -n "$windows" ]]; then
            local count=0
            while IFS= read -r addr; do
                if [[ -n "$addr" && "$addr" != "null" ]]; then
                    hyprctl dispatch movetoworkspacesilent "$FALLBACK_WORKSPACE,address:$addr" 2>/dev/null
                    log "  → Moved $addr → WS $FALLBACK_WORKSPACE"
                    ((count++))
                fi
            done <<< "$windows"
            [[ $count -gt 0 ]] && log "  ✓ Relocated $count windows"
        fi
    done
    
    # If we're on an invalid workspace, switch away
    local active_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
    if [[ "$active_ws" -gt "$MAX_WORKSPACE" ]]; then
        log "  → Switching from invalid WS $active_ws → WS $FALLBACK_WORKSPACE"
        hyprctl dispatch workspace "$FALLBACK_WORKSPACE" 2>/dev/null
    fi
    
    return $found_invalid
}

# Initial cleanup on startup
startup_cleanup() {
    log "═══════════════════════════════════════════════════"
    log "  WORKSPACE GUARDIAN - 3x3 Grid Enforcer"
    log "  Max workspace: $MAX_WORKSPACE | Fallback: $FALLBACK_WORKSPACE"
    log "═══════════════════════════════════════════════════"
    log "Performing initial workspace audit..."
    
    if cleanup_invalid_workspaces; then
        log "⚠ Invalid workspaces were cleaned up"
    else
        log "✓ All workspaces within bounds (1-$MAX_WORKSPACE)"
    fi
}

# Main event loop
main() {
    startup_cleanup
    
    local socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    
    if [[ ! -S "$socket" ]]; then
        log "ERROR: Hyprland socket not found!"
        log "Socket path: $socket"
        exit 1
    fi
    
    log "🔒 Guardian active - monitoring Hyprland socket..."
    
    # Monitor workspace events via socat
    socat -u "UNIX-CONNECT:$socket" - 2>/dev/null | while IFS= read -r line; do
        # Events that might create invalid workspaces:
        # - workspace>>ID (switched to workspace)
        # - createworkspace>>ID (new workspace created)
        # - createworkspacev2>>ID,NAME
        # - movewindow>>ADDR,WSNAME
        # - openwindow>>ADDR,WSNAME,...
        
        case "$line" in
            workspace\>\>*|createworkspace*|movewindow\>\>*|openwindow\>\>*)
                # Small delay to let Hyprland finish the operation
                sleep 0.05
                cleanup_invalid_workspaces
                ;;
        esac
    done
    
    log "⚠ Socket connection lost - guardian exiting"
}

# Handle termination gracefully
trap 'log "Guardian terminated by signal"; exit 0' SIGTERM SIGINT SIGHUP

main
