pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Hook connections for automatic script execution
  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      executeDarkModeHook(Settings.data.colorSchemes.darkMode)
    }
  }

  // Execute dark mode change hook
  function executeDarkModeHook(isDarkMode) {
    if (!Settings.data.hooks?.enabled) {
      return
    }

    const script = Settings.data.hooks?.darkModeChange
    if (!script || script === "") {
      return
    }

    try {
      const command = script.replace(/\$1/g, isDarkMode ? "true" : "false")
      Quickshell.execDetached(["sh", "-c", command])
      Logger.d("HooksService", `Executed dark mode hook: ${command}`)
    } catch (e) {
      Logger.e("HooksService", `Failed to execute dark mode hook: ${e}`)
    }
  }

  // Initialize the service
  function init() {
    Logger.i("HooksService", "Service initialized")
  }
}
