
/*
 * Noctalia – made by https://github.com/noctalia-dev
 * Licensed under the MIT License.
 * Forks and modifications are allowed under the MIT License,
 * but proper credit must be given to the original author.
*/

// Qt & Quickshell Core
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets

// Commons & Services
import qs.Commons
import qs.Services
import qs.Widgets

// Core Modules
import qs.Modules.SessionMenu

// Bar & Bar Components
import qs.Modules.Bar
import qs.Modules.Bar.Extras
import qs.Modules.Bar.Bluetooth
import qs.Modules.Bar.Calendar
import qs.Modules.Bar.WiFi

// Panels & UI Components
import qs.Modules.ControlCenter
import qs.Modules.Notification
import qs.Modules.Settings
import qs.Modules.Toast

ShellRoot {
  id: shellRoot

  property bool i18nLoaded: false
  property bool settingsLoaded: false

  Component.onCompleted: {
    Logger.log("Shell", "---------------------------")
    Logger.log("Shell", "Noctalia Hello!")
  }

  Connections {
    target: Quickshell
    function onReloadCompleted() {
      Quickshell.inhibitReloadPopup()
    }
  }

  Connections {
    target: I18n ? I18n : null
    function onTranslationsLoaded() {
      i18nLoaded = true
    }
  }

  Connections {
    target: Settings ? Settings : null
    function onSettingsLoaded() {
      settingsLoaded = true
    }
  }

  Loader {
    active: i18nLoaded && settingsLoaded

    sourceComponent: Item {
      Component.onCompleted: {
        Logger.log("Shell", "---------------------------")
        ColorSchemeService.init()
        BarWidgetRegistry.init()
        LocationService.init()
        NightLightService.apply()
        FontService.init()
        HooksService.init()
        BluetoothService.init()
      }

      Bar {}

      Notification {
        id: notification
      }

      ToastOverlay {}

      // IPCService is treated as a service
      // but it's actually an Item that needs to exists in the shell.
      IPCService {}

      // ------------------------------
      // All the NPanels
      ControlCenterPanel {
        id: controlCenterPanel
        objectName: "controlCenterPanel"
      }

      CalendarPanel {
        id: calendarPanel
        objectName: "calendarPanel"
      }

      SettingsPanel {
        id: settingsPanel
        objectName: "settingsPanel"
      }

      NotificationHistoryPanel {
        id: notificationHistoryPanel
        objectName: "notificationHistoryPanel"
      }

      SessionMenu {
        id: sessionMenuPanel
        objectName: "sessionMenuPanel"
      }

      WiFiPanel {
        id: wifiPanel
        objectName: "wifiPanel"
      }

      BluetoothPanel {
        id: bluetoothPanel
        objectName: "bluetoothPanel"
      }
    }
  }
}
