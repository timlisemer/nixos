import app from "ags/gtk4/app"
import Time from "./Time";
import { Astal, Gtk, Gdk } from "ags/gtk4"

// Left component
function Left() {
  return (
    <box>
      <Time />
    </box>
  )
}

// Center component
function Center() {
  return (
    <box>
      <Time />
    </box>
  )
}

// Right component
function Right() {
  return (
    <box>
      <Time />
    </box>
  )
}

// Main Bar component
export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={BOTTOM | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="centerbox">
        <Left $type="start" />
        <Center $type="center" />
        <Right $type="end" />
      </centerbox>
    </window>
  )
}