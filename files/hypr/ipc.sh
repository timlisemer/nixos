#!/bin/bash

get_focused_monitor() {
    hyprctl monitors | grep -B 11 "focused: yes" | grep "Monitor" | awk '{print $2}'
}

get_max_workspace_id() {
    local monitor_name="$1"
    hyprctl workspaces | grep "$monitor_name" -A 5 | grep "workspace ID" | awk '{print $3}' | sort -n | tail -n 1
}

get_active_workspace() {
    local monitor_name="$1"
    hyprctl monitors | grep -A 6 "Monitor $monitor_name" | grep "active workspace" | awk '{print $3}'
}

should_ignore_app() {
    local window_title="$1"
    local ignore_apps="Discord|WebCord|VenCord|Spotify"
    if [[ "$window_title" =~ $ignore_apps ]]; then
        return 0  # True, should ignore
    else
        return 1  # False, should not ignore
    fi
}

move_to_highest_workspace() {
  local focused_monitor=$(get_focused_monitor)
  max_workspace_id=$(get_max_workspace_id "$focused_monitor")
  echo "Moving window to workspace $max_workspace_id on $focused_monitor."
  hyprctl dispatch movetoworkspace "$max_workspace_id"
}

create_empty_workspace() {
  local focused_monitor=$(get_focused_monitor)
  local max_workspace_id=$(get_max_workspace_id)
  local new_workspace_id=$((max_workspace_id+1))
  hyprctl dispatch workspace $new_workspace_id
}

handle_event() {
    case "$1" in
        openwindow*)
            focused_monitor=$(get_focused_monitor)

            local window_title=$(echo "${@}" | cut -d, -f4)
            if should_ignore_app "$window_title"; then
                echo "Ignoring window for $window_title"
                return
            fi

            if [[ "$focused_monitor" == "DP-2" || "$focused_monitor" == "HDMI-A-1" ]]; then
                echo "Window opened on $focused_monitor, leaving it on the active workspace."
            elif [[ "$focused_monitor" == "HDMI-A-2" ]]; then
                active_workspace=$(get_active_workspace "$focused_monitor")
                if [[ "$active_workspace" == "2" || "$active_workspace" == "3" ]]; then
                   move_to_highest_workspace 
                else
                    echo "Window opened on $focused_monitor - workspace: $active_workspace, leaving it on the active workspace."
                fi
            else
                echo "Unknown monitor: $focused_monitor"
            fi
            ;;
        *)
            # Ignore other events
            ;;
    esac
}

echo "Started Listening for Hyprland IPC Socket Events..."
socat UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
    handle_event "$line"
done

