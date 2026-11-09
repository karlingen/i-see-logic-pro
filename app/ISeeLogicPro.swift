// Launcher for the light theme. It stores the brightness settings in its own preferences
// domain, which theme/light-theme.m reads at launch, and starts Logic Pro with the theme.
import AppKit
import SwiftUI

let LOGIC_ID = "com.apple.logic10"
let LOGIC_PATH = "/Applications/Logic Pro.app"
// The limits, the gray rule and SELECTED_ROW_WHITE come from theme/gray-rule.h.
let SURFACE_RANGE = SURFACE_MAX_MIN...1.0
let GAMMA_RANGE = GAMMA_MIN...GAMMA_MAX
let PRESET_MATCH = 0.005
let CUSTOM = "Custom"
let WINDOW_SIZE = CGSize(width: 720, height: 400)
let SIDEBAR_WIDTH = 190.0
let HEADER_WIDTH = 290.0
let ROW_HEIGHT = 34.0
let RULER_HEIGHT = 20.0
let BAR_WIDTH = 46.0
let BAR_COUNT = 12
let STRIP_FOOTER = 14.0

// Stock Logic Pro grays of the track area, measured in a render of Logic Pro without the theme.
let STOCK_ROW = 0.18
let STOCK_SEPARATOR = 0.25
let STOCK_BUTTON = 0.26
let STOCK_SLIDER = 0.11
let STOCK_KNOB = 0.51
let STOCK_LANE = 0.1
let STOCK_GRID = 0.15
let STOCK_RULER = 0.25
let STOCK_LETTER = 0.9
let STOCK_TEXT = 1.0

struct Preset: Identifiable {
   let name: String
   let summary: String
   let surfaceMax: Double
   let gamma: Double
   var id: String { return name }
}

let PRESETS = [
   Preset(name: "Light", summary: "Full brightness", surfaceMax: 1, gamma: 0.75),
   Preset(name: "Soft", summary: "Dimmer grays", surfaceMax: 0.85, gamma: 0.85),
   Preset(name: "Gray", summary: "Middle gray", surfaceMax: 0.68, gamma: 1),
]

struct MockTrack: Identifiable {
   let number: Int
   let name: String
   let color: Color
   let hasRecord: Bool
   let isSoloed: Bool
   let volume: Double
   // Regions as (first bar, length in bars).
   let regions: [ (Double, Double) ]
   var id: Int { return number }
}

let MOCK_TRACKS = [
   MockTrack(number: 1, name: "Doing Science", color: Color(red: 0.84, green: 0.78, blue: 0.2),
      hasRecord: true, isSoloed: false, volume: 0.72, regions: [ (1, 2), (3, 2), (6, 2) ]),
   MockTrack(number: 2, name: "Chill Vocal Sequences", color: Color(red: 0.6, green: 0.8, blue: 0.24),
      hasRecord: true, isSoloed: true, volume: 0.6, regions: [ (0, 3), (4, 3) ]),
   MockTrack(number: 3, name: "Plucked Nylon Guitar", color: Color(red: 0.25, green: 0.72, blue: 0.68),
      hasRecord: false, isSoloed: false, volume: 0.45, regions: [ (2, 4) ]),
   MockTrack(number: 4, name: "Steinway Grand Piano", color: Color(red: 0.3, green: 0.76, blue: 0.82),
      hasRecord: true, isSoloed: false, volume: 0.55, regions: [ (0, 2), (5, 3) ]),
   MockTrack(number: 5, name: "Mellotron", color: Color(red: 0.36, green: 0.56, blue: 0.9),
      hasRecord: false, isSoloed: false, volume: 0.66, regions: [ (3, 2), (7, 2) ]),
]

struct ThemeValues {
   let surfaceMax: Double
   let gamma: Double

   func gray(_ stock: Double) -> Color {
      return Color(white: mapGrayLevel(stock, surfaceMax, gamma))
   }
}

enum LaunchStatus {
   case ready, logicRunning, logicMissing, libraryMissing, failed(String)
   case logicUntested(tested: String, installed: String)

   var text: String {
      switch self {
      case .ready: return "Ready. Logic Pro starts with the theme."
      case .logicRunning: return "Quit Logic Pro first. The theme loads only at launch."
      case .logicMissing: return "Logic Pro is not in the Applications folder."
      case .libraryMissing: return "The theme library is missing. Download the app again."
      case .logicUntested(let tested, let installed):
         return "Tested with Logic Pro build \(tested), but you have build \(installed). Some parts can stay dark."
      case .failed(let error): return "Logic Pro did not start. \(error)"
      }
   }

   var symbol: String {
      switch self {
      case .ready: return "checkmark.circle.fill"
      case .failed: return "xmark.octagon.fill"
      default: return "exclamationmark.triangle.fill"
      }
   }

   var tint: Color {
      switch self {
      case .ready: return .green
      case .failed: return .red
      default: return .orange
      }
   }

   var canStart: Bool {
      switch self {
      case .ready, .logicUntested, .failed: return true
      default: return false
      }
   }
}

/**
 * Reports if a copy of Logic Pro is running.
 *
 * @return Bool - true if Logic Pro is running
 */
func isLogicRunning() -> Bool {
   return !NSRunningApplication.runningApplications(withBundleIdentifier: LOGIC_ID).isEmpty
}

/**
 * Finds the state of the launch from the files and the running apps.
 *
 * @return LaunchStatus - the state to show
 */
func getLaunchStatus() -> LaunchStatus {
   let tested = Bundle.main.infoDictionary?["TestedLogicBuild"] as? String
   let installed = Bundle(path: LOGIC_PATH)?.infoDictionary?["CFBundleVersion"] as? String

   if Bundle.main.path(forResource: "light-theme", ofType: "dylib") == nil {
      return .libraryMissing
   }
   guard let installed else {
      return .logicMissing
   }
   if isLogicRunning() {
      return .logicRunning
   }
   if let tested, tested != installed {
      return .logicUntested(tested: tested, installed: installed)
   }
   return .ready
}

/**
 * A small drawing of Logic Pro track headers and regions, painted with the gray rule.
 */
struct MockStrip: View {
   let theme: ThemeValues

   var body: some View {
      VStack(spacing: 0) {
         HStack(spacing: 0) {
            theme.gray(STOCK_ROW).frame(width: HEADER_WIDTH)
            ruler
         }
         .frame(height: RULER_HEIGHT)
         ForEach(MOCK_TRACKS) { (track) in
            separator
            HStack(spacing: 0) {
               header(track)
               lane(track)
            }
            .frame(height: ROW_HEIGHT)
         }
         separator
         HStack(spacing: 0) {
            theme.gray(STOCK_ROW).frame(width: HEADER_WIDTH)
            laneGrid
         }
         .frame(height: STRIP_FOOTER)
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
   }

   var separator: some View {
      return theme.gray(STOCK_SEPARATOR).frame(height: 1)
   }

   var ruler: some View {
      return HStack(spacing: 0) {
         ForEach(0..<BAR_COUNT, id: \.self) { (bar) in
            Text("\(bar * 4 + 1)")
               .font(.system(size: 9).monospacedDigit())
               .foregroundStyle(theme.gray(STOCK_LETTER))
               .padding(.leading, 3)
               .frame(width: BAR_WIDTH, alignment: .leading)
         }
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .background(theme.gray(STOCK_RULER))
      .clipped()
   }

   var laneGrid: some View {
      return HStack(spacing: 0) {
         ForEach(0..<BAR_COUNT, id: \.self) { (_) in
            theme.gray(STOCK_GRID).frame(width: 1)
            Spacer().frame(width: BAR_WIDTH - 1)
         }
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .background(theme.gray(STOCK_LANE))
      .clipped()
   }

   func header(_ track: MockTrack) -> some View {
      let isSelected = track.number == 1
      let rowColor = isSelected
         ? Color(white: SELECTED_ROW_WHITE * theme.surfaceMax)
         : theme.gray(STOCK_ROW)

      return HStack(spacing: 6) {
         Text("\(track.number)")
            .font(.system(size: 11, weight: .semibold).monospacedDigit())
            .foregroundStyle(.black)
            .frame(width: 22, height: ROW_HEIGHT)
            .background(track.color)
         HStack(spacing: 2) {
            button("M", isOn: false, onColor: .clear)
            button("S", isOn: track.isSoloed, onColor: Color(red: 0.95, green: 0.78, blue: 0.2))
            if track.hasRecord {
               button("R", isOn: false, onColor: .clear)
               button("I", isOn: false, onColor: .clear)
            }
         }
         .frame(width: 76, alignment: .leading)
         Text(track.name)
            .font(.system(size: 11))
            .foregroundStyle(theme.gray(STOCK_TEXT))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
         volume(track.volume)
      }
      .padding(.trailing, 8)
      .frame(width: HEADER_WIDTH)
      .background(rowColor)
   }

   func button(_ letter: String, isOn: Bool, onColor: Color) -> some View {
      return Text(letter)
         .font(.system(size: 9, weight: .bold))
         .foregroundStyle(isOn ? .black : theme.gray(STOCK_LETTER))
         .frame(width: 17, height: 15)
         .background(isOn ? onColor : theme.gray(STOCK_BUTTON), in: RoundedRectangle(cornerRadius: 3))
   }

   func volume(_ level: Double) -> some View {
      return ZStack(alignment: .leading) {
         Capsule().fill(theme.gray(STOCK_SLIDER)).frame(width: 58, height: 12)
         Circle().fill(theme.gray(STOCK_KNOB)).frame(width: 10, height: 10).offset(x: 1 + level * 46)
      }
   }

   func lane(_ track: MockTrack) -> some View {
      return ZStack(alignment: .topLeading) {
         laneGrid
         ForEach(Array(track.regions.enumerated()), id: \.offset) { (_, region) in
            Text(track.name)
               .font(.system(size: 9, weight: .medium))
               .foregroundStyle(.white)
               .lineLimit(1)
               .padding(.horizontal, 3)
               .padding(.top, 2)
               .frame(width: region.1 * BAR_WIDTH - 2, height: ROW_HEIGHT - 4, alignment: .topLeading)
               .background(track.color, in: RoundedRectangle(cornerRadius: 3))
               .offset(x: region.0 * BAR_WIDTH + 1, y: 2)
         }
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .clipped()
   }
}

struct ContentView: View {
   @AppStorage("surfaceMax") var surfaceMax = 1.0
   @AppStorage("gamma") var gamma = 0.75
   @State var status = getLaunchStatus()
   @State var columns = NavigationSplitViewVisibility.all

   var presetName: String {
      let match = PRESETS.first { (p) in
         return abs(p.surfaceMax - surfaceMax) < PRESET_MATCH && abs(p.gamma - gamma) < PRESET_MATCH
      }

      return match?.name ?? CUSTOM
   }

   var selection: Binding<String?> {
      return Binding(
         get: { return presetName },
         set: { (name) in
            if let p = PRESETS.first(where: { (p) in return p.name == name }) {
               surfaceMax = p.surfaceMax
               gamma = p.gamma
            }
         }
      )
   }

   var body: some View {
      let workspace = NSWorkspace.shared.notificationCenter

      NavigationSplitView(columnVisibility: $columns) {
         List(selection: selection) {
            ForEach(PRESETS) { (p) in
               presetRow(name: p.name, summary: p.summary, surface: p.surfaceMax).tag(p.name)
            }
            presetRow(name: CUSTOM, summary: "Your own values", surface: surfaceMax).tag(CUSTOM)
         }
         .navigationSplitViewColumnWidth(SIDEBAR_WIDTH)
         .toolbar(removing: .sidebarToggle)
      } detail: {
         VStack(alignment: .leading, spacing: 18) {
            MockStrip(theme: ThemeValues(surfaceMax: surfaceMax, gamma: gamma))
               .accessibilityElement(children: .ignore)
               .accessibilityLabel("Preview of Logic Pro tracks at \(percent(surfaceMax)) lightness")
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
               sliderRow("Lightness", value: $surfaceMax, range: SURFACE_RANGE, low: "Dark", high: "Light",
                  shown: percent(surfaceMax))
               sliderRow("Middle grays", value: $gamma, range: GAMMA_RANGE, low: "Light", high: "Dark",
                  shown: String(format: "%.2f", gamma))
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
               Image(systemName: status.symbol).foregroundStyle(status.tint)
               Text(status.text).foregroundStyle(.secondary).lineLimit(2)
               Spacer()
               Button("Start Logic Pro", action: startLogic)
                  .keyboardShortcut(.defaultAction)
                  .controlSize(.large)
                  .disabled(!status.canStart)
            }
         }
         .padding(20)
         .navigationTitle("I See Logic Pro")
      }
      .frame(width: WINDOW_SIZE.width, height: WINDOW_SIZE.height)
      .onReceive(workspace.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { (_) in
         status = getLaunchStatus()
      }
      .onReceive(workspace.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { (_) in
         status = getLaunchStatus()
      }
   }

   func presetRow(name: String, summary: String, surface: Double) -> some View {
      return HStack(spacing: 10) {
         RoundedRectangle(cornerRadius: 4)
            .fill(Color(white: surface))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.separator))
            .frame(width: 18, height: 18)
         VStack(alignment: .leading, spacing: 1) {
            Text(name)
            Text(summary).font(.caption).foregroundStyle(.secondary)
         }
      }
      .padding(.vertical, 3)
   }

   func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, low: String,
      high: String, shown: String) -> some View {
      return GridRow {
         Text(label)
         Slider(value: value, in: range) {
            Text(label)
         } minimumValueLabel: {
            Text(low).font(.caption).foregroundStyle(.secondary)
         } maximumValueLabel: {
            Text(high).font(.caption).foregroundStyle(.secondary)
         }
         .labelsHidden()
         .accessibilityValue(shown)
         Text(shown).monospacedDigit().foregroundStyle(.secondary).frame(width: 40, alignment: .trailing)
      }
   }

   func percent(_ value: Double) -> String {
      return "\(Int((value * 100).rounded()))%"
   }

   /**
    * Starts Logic Pro with the theme library from this app bundle, then quits this app.
    */
   func startLogic() {
      let open = Process()

      guard let library = Bundle.main.path(forResource: "light-theme", ofType: "dylib") else {
         return
      }
      if isLogicRunning() {
         status = .logicRunning
         return
      }
      open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      open.arguments = [ "-n", "--env", "DYLD_INSERT_LIBRARIES=\(library)", "-a", LOGIC_PATH ]
      do {
         try open.run()
         open.waitUntilExit()
      } catch {
         status = .failed(error.localizedDescription)
         return
      }
      if open.terminationStatus != 0 {
         status = .failed("The open command ended with code \(open.terminationStatus).")
         return
      }
      NSApp.terminate(nil)
   }
}

class AppDelegate: NSObject, NSApplicationDelegate {
   /**
    * Removes the download quarantine flag from the theme library in this app bundle. The user
    * approved this app in Gatekeeper, and without this step macOS asks a second time when
    * Logic Pro loads the library.
    */
   func applicationDidFinishLaunching(_ notification: Notification) {
      if let library = Bundle.main.path(forResource: "light-theme", ofType: "dylib") {
         removexattr(library, "com.apple.quarantine", 0)
      }
   }

   func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
      return true
   }
}

@main
struct LauncherApp: App {
   @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

   var body: some Scene {
      Window("I See Logic Pro", id: "main") {
         ContentView()
      }
      .windowResizability(.contentSize)
   }
}
