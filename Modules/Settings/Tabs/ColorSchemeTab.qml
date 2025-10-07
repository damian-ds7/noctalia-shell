import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets

ColumnLayout {
  id: root

  // Cache for scheme JSON (can be flat or {dark, light})
  property var schemeColorsCache: ({})

  spacing: Style.marginL * scaling

  // Helper function to extract scheme name from path
  function extractSchemeName(schemePath) {
    var pathParts = schemePath.split("/")
    var filename = pathParts[pathParts.length - 1] // Get filename
    var schemeName = filename.replace(".json", "") // Remove .json extension

    // Convert folder names back to display names
    if (schemeName === "Noctalia-default") {
      schemeName = "Noctalia (default)"
    } else if (schemeName === "Noctalia-legacy") {
      schemeName = "Noctalia (legacy)"
    } else if (schemeName === "Tokyo-Night") {
      schemeName = "Tokyo Night"
    }

    return schemeName
  }

  // Helper function to get color from scheme file (supports dark/light variants)
  function getSchemeColor(schemePath, colorKey) {
    // Extract scheme name from path
    var schemeName = extractSchemeName(schemePath)

    // Try to get from cached data first
    if (schemeColorsCache[schemeName]) {
      var entry = schemeColorsCache[schemeName]
      var variant = entry
      if (entry.dark || entry.light) {
        variant = Settings.data.colorSchemes.darkMode ? (entry.dark || entry.light) : (entry.light || entry.dark)
      }
      if (variant && variant[colorKey])
        return variant[colorKey]
    }

    // Return a default color if not cached yet
    return "#000000"
  }

  // This function is called by the FileView Repeater when a scheme file is loaded
  function schemeLoaded(schemeName, jsonData) {
    var value = jsonData || {}
    var newCache = schemeColorsCache
    newCache[schemeName] = value
    schemeColorsCache = newCache
  }

  // When the list of available schemes changes, clear the cache.
  // The Repeater below will automatically re-create the FileViews.
  Connections {
    target: ColorSchemeService
    function onSchemesChanged() {
      schemeColorsCache = {}
    }
  }

  // A non-visual Item to host the Repeater that loads the color scheme files.
  Item {
    visible: false
    id: fileLoaders

    Repeater {
      model: ColorSchemeService.schemes

      // The delegate is a Component, which correctly wraps the non-visual FileView
      delegate: Item {
        FileView {
          path: modelData
          blockLoading: true
          onLoaded: {
            // Extract scheme name from path
            var schemeName = extractSchemeName(path)

            try {
              var jsonData = JSON.parse(text())
              root.schemeLoaded(schemeName, jsonData)
            } catch (e) {
              Logger.warn("ColorSchemeTab", "Failed to parse JSON for scheme:", schemeName, e)
              root.schemeLoaded(schemeName, null) // Load defaults on parse error
            }
          }
        }
      }
    }
  }

  // Main Toggles - Dark Mode
  NHeader {
    label: I18n.tr("settings.color-scheme.color-source.section.label")
    description: I18n.tr("settings.color-scheme.color-source.section.description")
  }

  // Dark Mode Toggle (affects both Matugen and predefined schemes that provide variants)
  NToggle {
    label: I18n.tr("settings.color-scheme.color-source.dark-mode.label")
    description: I18n.tr("settings.color-scheme.color-source.dark-mode.description")
    checked: Settings.data.colorSchemes.darkMode
    enabled: true
    onToggled: checked => Settings.data.colorSchemes.darkMode = checked
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
    visible: !Settings.data.colorSchemes.useWallpaperColors
  }

  // Predefined Color Schemes
  ColumnLayout {
    spacing: Style.marginM * scaling
    Layout.fillWidth: true
    visible: !Settings.data.colorSchemes.useWallpaperColors

    NHeader {
      label: I18n.tr("settings.color-scheme.predefined.section.label")
      description: I18n.tr("settings.color-scheme.predefined.section.description")
    }

    // Color Schemes Grid
    GridLayout {
      columns: Math.max(1, Math.floor((root.width + columnSpacing) / (222 * scaling + columnSpacing)))
      rowSpacing: Style.marginM * scaling
      columnSpacing: Style.marginM * scaling
      Layout.fillWidth: true

      Repeater {
        model: ColorSchemeService.schemes

        Rectangle {
          id: schemeItem

          property string schemePath: modelData

          Layout.alignment: Qt.AlignHCenter
          width: 222 * scaling
          height: 50 * scaling
          radius: Style.radiusS * scaling
          color: getSchemeColor(modelData, "mSurface")
          border.width: Math.max(1, Style.borderL * scaling)
          border.color: {
            if (Settings.data.colorSchemes.predefinedScheme === extractSchemeName(modelData)) {
              return Color.mSecondary
            }
            if (itemMouseArea.containsMouse) {
              return Color.mTertiary
            }
            return Color.mOutline
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM * scaling
            spacing: Style.marginXS * scaling

            NText {
              text: extractSchemeName(schemePath)
              pointSize: Style.fontSizeS * scaling
              font.weight: Style.fontWeightMedium
              color: Color.mOnSurface
              Layout.fillWidth: true
              // Layout.maximumWidth: 150 * scaling
              elide: Text.ElideRight
              verticalAlignment: Text.AlignVCenter
              wrapMode: Text.WordWrap
              maximumLineCount: 1
            }

            Rectangle {
              width: 14 * scaling
              height: 14 * scaling
              radius: width * 0.5
              color: getSchemeColor(modelData, "mPrimary")
            }

            Rectangle {
              width: 14 * scaling
              height: 14 * scaling
              radius: width * 0.5
              color: getSchemeColor(modelData, "mSecondary")
            }

            Rectangle {
              width: 14 * scaling
              height: 14 * scaling
              radius: width * 0.5
              color: getSchemeColor(modelData, "mTertiary")
            }

            Rectangle {
              width: 14 * scaling
              height: 14 * scaling
              radius: width * 0.5
              color: getSchemeColor(modelData, "mError")
            }
          }

          MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Settings.data.colorSchemes.useWallpaperColors = false
              Logger.log("ColorSchemeTab", "Disabled wallpaper colors")

              Settings.data.colorSchemes.predefinedScheme = extractSchemeName(schemePath)
              ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme)
            }
          }

          // Selection indicator
          Rectangle {
            visible: (Settings.data.colorSchemes.predefinedScheme === extractSchemeName(schemePath))
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -3 * scaling
            anchors.topMargin: -3 * scaling
            width: 20 * scaling
            height: 20 * scaling
            radius: width * 0.5
            color: Color.mSecondary
            border.width: Math.max(1, Style.borderS * scaling)
            border.color: Color.mOnSecondary

            NIcon {
              icon: "check"
              pointSize: Style.fontSizeXS * scaling
              font.weight: Style.fontWeightBold
              color: Color.mOnSecondary
              anchors.centerIn: parent
            }
          }

          Behavior on border.color {
            ColorAnimation {
              duration: Style.animationNormal
            }
          }
        }
      }
    }

    // Generate templates for predefined schemes
    NCheckbox {
      Layout.fillWidth: true
      label: I18n.tr("settings.color-scheme.predefined.generate-templates.label")
      description: I18n.tr("settings.color-scheme.predefined.generate-templates.description")
      checked: Settings.data.colorSchemes.generateTemplatesForPredefined
      onToggled: checked => {
                   Settings.data.colorSchemes.generateTemplatesForPredefined = checked
                   // Re-generate templates if a predefined scheme is currently active
                   if (!Settings.data.colorSchemes.useWallpaperColors && Settings.data.colorSchemes.predefinedScheme) {
                     ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme)
                   }
                 }
      Layout.topMargin: Style.marginL * scaling
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXL * scaling
    Layout.bottomMargin: Style.marginXL * scaling
  }
}
