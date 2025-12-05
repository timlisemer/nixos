/* extension.js
 *
 * GNOME Quick Settings extension for Home Assistant webhook control
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import Soup from 'gi://Soup?version=3.0';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import {
  Extension,
  gettext as _,
} from 'resource:///org/gnome/shell/extensions/extension.js';
import {
  QuickToggle,
  SystemIndicator,
} from 'resource:///org/gnome/shell/ui/quickSettings.js';

const WEBHOOK_SECRET_PATH = '/run/secrets/webhook_id_audio_receiver';
const HOMEASSISTANT_URL = 'https://homeassistant.yakweide.de';

const AudioReceiverToggle = GObject.registerClass(
  class AudioReceiverToggle extends QuickToggle {
    constructor() {
      super({
        title: _('Audio Receiver'),
        iconName: 'audio-speakers-symbolic',
        toggleMode: false,
      });

      this._httpSession = new Soup.Session();
      this.connect('clicked', () => this._triggerWebhook());
    }

    _readWebhookId() {
      try {
        const file = Gio.File.new_for_path(WEBHOOK_SECRET_PATH);
        const [success, contents] = file.load_contents(null);
        if (success) {
          const decoder = new TextDecoder('utf-8');
          return decoder.decode(contents).trim();
        }
      } catch (e) {
        console.error(
          `[AudioReceiver] Failed to read webhook secret: ${e.message}`
        );
      }
      return null;
    }

    _triggerWebhook() {
      const webhookId = this._readWebhookId();
      if (!webhookId) {
        Main.notify(_('Audio Receiver'), _('Webhook secret not found'));
        return;
      }

      const url = `${HOMEASSISTANT_URL}/api/webhook/${webhookId}`;
      const message = Soup.Message.new('POST', url);

      this._httpSession.send_async(
        message,
        GLib.PRIORITY_DEFAULT,
        null,
        (session, result) => {
          try {
            session.send_finish(result);
            const status = message.get_status();
            if (status === Soup.Status.OK) {
              Main.notify(_('Audio Receiver'), _('Toggled Audio Receiver'));
            } else {
              Main.notify(_('Audio Receiver'), _(`Request failed: ${status}`));
            }
          } catch (e) {
            console.error(
              `[AudioReceiver] Webhook request failed: ${e.message}`
            );
            Main.notify(_('Audio Receiver'), _('Request failed'));
          }
        }
      );
    }
  }
);

const AudioReceiverIndicator = GObject.registerClass(
  class AudioReceiverIndicator extends SystemIndicator {
    constructor() {
      super();

      const toggle = new AudioReceiverToggle();
      this.quickSettingsItems.push(toggle);
    }
  }
);

export default class QuickSettingsExtension extends Extension {
  enable() {
    this._indicator = new AudioReceiverIndicator();
    Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
  }

  disable() {
    this._indicator.quickSettingsItems.forEach((item) => item.destroy());
    this._indicator.destroy();
    this._indicator = null;
  }
}
