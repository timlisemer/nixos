import app from 'ags/gtk4/app';
import Time from './bar/Time';
import AppsBar from './bar/Apps';
import Workspaces from './bar/Workspaces';
import SysTray from './bar/SysTray';
import { Astal, Gdk } from 'ags/gtk4';

// Main Bar component
export default function Bar(gdkmonitor: Gdk.Monitor, index: number) {
  const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

  // Left component
  function Left() {
    let monitorDesc = gdkmonitor.get_description() ?? 'DP-2';
    let monitorNameMatch = monitorDesc.match(/\(([^)]+)\)/);
    let monitorName = monitorNameMatch ? monitorNameMatch[1] : monitorDesc;
    return (
      <box>
        {Workspaces(monitorName)}
        <SysTray />
      </box>
    );
  }

  // Center component
  function Center() {
    return (
      <box>
        <AppsBar />
      </box>
    );
  }

  // Right component
  function Right() {
    return (
      <box>
        <Time />
      </box>
    );
  }

  return (
    <window
      visible
      name={`bar-${index}`}
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={BOTTOM | LEFT | RIGHT}
      application={app}
      hexpand={false}
      vexpand={false}
    >
      <centerbox cssName="centerbox">
        <Left $type="start" />
        <Center $type="center" />
        <Right $type="end" />
      </centerbox>
    </window>
  );
}
