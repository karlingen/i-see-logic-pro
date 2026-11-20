// Launcher for the light theme. It stores the brightness and tint settings in its own
// preferences domain, which theme/light-theme.m reads at launch, and starts Logic Pro with the
// theme.
import AppKit
import SwiftUI

let LOGIC_ID = "com.apple.logic10"
let LOGIC_PATH = "/Applications/Logic Pro.app"
// The limits, the gray rule and SELECTED_ROW_WHITE come from theme/gray-rule.h.
let SURFACE_RANGE = SURFACE_MAX_MIN...1.0
let GAMMA_RANGE = GAMMA_MIN...GAMMA_MAX
let CONTRAST_RANGE = TEXT_CONTRAST_MIN...TEXT_CONTRAST_MAX
let PRESET_MATCH = 0.005
let CUSTOM = "Custom"
let CLASSIC = "Classic"
// The Logic Pro 12 grays of a track row and a selected track row, which the classic mode uses.
let CLASSIC_ROW = 0.341
let CLASSIC_SELECTED_ROW = 0.45
// Taller than 400: the contrast slider adds a fourth row, and the buttons at the bottom
// must stay inside the window. (20.11.2026)
let WINDOW_SIZE = CGSize(width: 720, height: 520)
let SIDEBAR_WIDTH = 190.0
let HEADER_WIDTH = 290.0
let ROW_HEIGHT = 34.0
let RULER_HEIGHT = 20.0
let BAR_WIDTH = 46.0
let BAR_COUNT = 12
let STRIP_FOOTER = 14.0
let END_LABEL_WIDTH = 30.0
let SWATCH_SIZE = 18.0
let SWATCH_RING = 3.0
// The swatches show each tint this many times stronger than the theme, so that the hues are
// easy to tell apart. The preview shows the true strength.
let SWATCH_GAIN = 3.0

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

// A tint multiplies each themed gray. The largest part is 1, and the others are at least 0.88,
// so that black text stays neutral and Logic Pro colors such as record red stay clear.
struct Tint: Identifiable {
   let name: String
   let red: Double
   let green: Double
   let blue: Double
   var id: String { return name }
   // The format that the theme reads, "r,g,b".
   var stored: String { return "\(red),\(green),\(blue)" }
}

let NO_TINT = Tint(name: "None", red: 1, green: 1, blue: 1)
let TINTS = [
   NO_TINT,
   Tint(name: "Cool", red: 0.9, green: 0.94, blue: 1),
   Tint(name: "Mist", red: 0.89, green: 0.99, blue: 1),
   Tint(name: "Sage", red: 0.91, green: 1, blue: 0.91),
   Tint(name: "Sand", red: 1, green: 0.96, blue: 0.88),
   Tint(name: "Rose", red: 1, green: 0.91, blue: 0.93),
   Tint(name: "Lilac", red: 0.95, green: 0.91, blue: 1),
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
   let tint: Tint
   // The classic mode keeps Logic Pro dark, without the sliders and the tint.
   let isClassic: Bool

   var selectedRow: Color {
      return isClassic ? tinted(CLASSIC_SELECTED_ROW) : tinted(SELECTED_ROW_WHITE * surfaceMax)
   }

   func gray(_ stock: Double) -> Color {
      return tinted(isClassic ? mapClassicLevel(stock) : mapGrayLevel(stock, surfaceMax, gamma))
   }

   // A themed gray level with the tint, as the theme draws it.
   func tinted(_ white: Double) -> Color {
      if isClassic {
         return Color(white: white)
      }
      return Color(red: white * tint.red, green: white * tint.green, blue: white * tint.blue)
   }
}

/// What GitHub reports as the newest release.
struct ReleaseInfo {
   let tag: String
   let page: String
}

/// Asks GitHub for the newest release. It only reads the public release list and never
/// replaces the app: this copy may carry changes that an update would throw away.
enum UpdateCheck {
   static let repository = "karlingen/i-see-logic-pro"

   static var current: String {
      return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
   }

   /// Compares "1.2.0" with "1.1.1" number by number, so that 1.10 counts as newer than 1.9.
   static func isNewer(_ candidate: String, than current: String) -> Bool {
      let a = numbers(in: candidate)
      let b = numbers(in: current)

      for index in 0..<max(a.count, b.count) {
         let left = index < a.count ? a[index] : 0
         let right = index < b.count ? b[index] : 0

         if left != right {
            return left > right
         }
      }
      return false
   }

   static func numbers(in text: String) -> [Int] {
      return text.split(whereSeparator: { (c) in return !c.isNumber }).map { (part) in
         return Int(part) ?? 0
      }
   }

   static func latest() async throws -> ReleaseInfo {
      let address = "https://api.github.com/repos/\(repository)/releases/latest"
      var request = URLRequest(url: URL(string: address)!)

      request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
      request.timeoutInterval = 15

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let http = response as? HTTPURLResponse, http.statusCode == 200,
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tag = json["tag_name"] as? String else {
         throw NSError(domain: "UpdateCheck", code: 1,
                       userInfo: [NSLocalizedDescriptionKey: "Unexpected answer from GitHub."])
      }
      return ReleaseInfo(tag: tag,
                         page: json["html_url"] as? String ?? "https://github.com/\(repository)/releases")
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
      let rowColor = isSelected ? theme.selectedRow : theme.gray(STOCK_ROW)

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
   /// The contrast that secondary text keeps, 4.5 to 12. The theme reads it as "contrast".
   @AppStorage("contrast") var contrast = TEXT_CONTRAST
   @AppStorage("tint") var storedTint = NO_TINT.stored
   @AppStorage("classic") var isClassic = false
   /// When on, Logic Pro starts without the theme: exactly as Apple ships it.
   @AppStorage("themeOff") var themeOff = false
   @State var status = getLaunchStatus()
   @State var columns = NavigationSplitViewVisibility.all
   /// The answer of the update check, shown under the status line.
   @State var updateText = ""
   /// Where the newest release can be downloaded, once one was found.
   @State var updatePage: String?

   var presetName: String {
      let match = PRESETS.first { (p) in
         return abs(p.surfaceMax - surfaceMax) < PRESET_MATCH && abs(p.gamma - gamma) < PRESET_MATCH
      }

      return match?.name ?? CUSTOM
   }

   var tint: Tint {
      return TINTS.first { (t) in return t.stored == storedTint } ?? NO_TINT
   }

   var theme: ThemeValues {
      return ThemeValues(surfaceMax: surfaceMax, gamma: gamma, tint: tint, isClassic: isClassic)
   }

   var selection: Binding<String?> {
      return Binding(
         get: { return isClassic ? CLASSIC : presetName },
         set: { (name) in
            isClassic = name == CLASSIC
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
         VStack(spacing: 0) {
            List(selection: selection) {
               ForEach(PRESETS) { (p) in
                  presetRow(name: p.name, summary: p.summary, surface: p.surfaceMax).tag(p.name)
               }
               presetRow(name: CUSTOM, summary: "Your own values", surface: surfaceMax).tag(CUSTOM)
               presetRow(name: CLASSIC, summary: "Logic Pro 12 grays", surface: CLASSIC_ROW).tag(CLASSIC)
            }
            Divider()
            Toggle("No theme", isOn: $themeOff)
               .toggleStyle(.switch)
               .controlSize(.small)
               .padding(10)
               .accessibilityHint("Starts Logic Pro exactly as Apple ships it")
         }
         .navigationSplitViewColumnWidth(SIDEBAR_WIDTH)
         .toolbar(removing: .sidebarToggle)
      } detail: {
         VStack(alignment: .leading, spacing: 18) {
            MockStrip(theme: theme)
               .accessibilityElement(children: .ignore)
               .accessibilityLabel(isClassic
                  ? "Preview of Logic Pro tracks with the Logic Pro 12 grays"
                  : "Preview of Logic Pro tracks at \(percent(surfaceMax)) lightness, tint \(tint.name)")
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
               sliderRow("Lightness", value: $surfaceMax, range: SURFACE_RANGE, low: "Dark", high: "Light",
                  shown: percent(surfaceMax))
               sliderRow("Text contrast", value: $contrast, range: CONTRAST_RANGE, low: "Soft", high: "Crisp",
                  shown: String(format: "%.1f:1", contrast), step: 0.1)
               sliderRow("Middle grays", value: $gamma, range: GAMMA_RANGE, low: "Light", high: "Dark",
                  shown: String(format: "%.2f", gamma))
               tintRow
            }
            .disabled(isClassic)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
               Image(systemName: status.symbol).foregroundStyle(status.tint)
               VStack(alignment: .leading, spacing: 2) {
                  Text(status.text).foregroundStyle(.secondary).lineLimit(2)
                  if !updateText.isEmpty {
                     Text(updateText).font(.caption).foregroundStyle(.tertiary).lineLimit(2)
                  }
               }
               Spacer()
               if let page = updatePage {
                  Button("Get \(updateText)") {
                     if let address = URL(string: page) {
                        NSWorkspace.shared.open(address)
                     }
                  }
                  .controlSize(.large)
               }
               Button("Check for Updates") {
                  checkForUpdates()
               }
               .controlSize(.large)
               .disabled(updateText == "Checking ...")
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

   /**
    * Asks GitHub for the newest release and shows it. It does not replace the app itself:
    * this copy is built from a branch of its own, and an ad-hoc signed bundle that overwrites
    * itself is a good way to end up with something that no longer starts.
    */
   @MainActor func checkForUpdates() {
      updatePage = nil
      updateText = "Checking ..."
      Task {
         do {
            let release = try await UpdateCheck.latest()
            let current = UpdateCheck.current

            if current == "dev" || !UpdateCheck.isNewer(release.tag, than: current) {
               updateText = current == "dev"
                  ? "Local build, newest is \(release.tag)"
                  : "Up to date (\(release.tag))"
               updatePage = nil
            } else {
               updateText = release.tag
               updatePage = release.page
            }
         } catch {
            updateText = "No answer from GitHub"
            updatePage = nil
         }
      }
   }

   func presetRow(name: String, summary: String, surface: Double) -> some View {
      return HStack(spacing: 10) {
         RoundedRectangle(cornerRadius: 4)
            .fill(theme.tinted(surface))
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
      high: String, shown: String, step: Double = 0.01) -> some View {
      return GridRow {
         Text(label)
         // The end labels are plain text, because macOS draws the value labels of a Slider dimmed.
         HStack(spacing: 8) {
            Text(low).font(.caption).foregroundStyle(.secondary)
               .frame(width: END_LABEL_WIDTH, alignment: .trailing)
               .accessibilityHidden(true)
            Slider(value: value, in: range, step: step) {
               Text(label)
            }
            .labelsHidden()
            .accessibilityValue(shown)
            Text(high).font(.caption).foregroundStyle(.secondary)
               .frame(width: END_LABEL_WIDTH, alignment: .leading)
               .accessibilityHidden(true)
         }
         Text(shown).monospacedDigit().foregroundStyle(.secondary).frame(width: 40, alignment: .trailing)
      }
   }

   var tintRow: some View {
      return GridRow {
         Text("Tint")
         HStack(spacing: 6) {
            ForEach(TINTS) { (t) in
               swatch(t)
            }
         }
         .accessibilityElement(children: .contain)
         .accessibilityLabel("Tint")
         Text(tint.name).foregroundStyle(.secondary).frame(width: 40, alignment: .trailing)
      }
   }

   func swatch(_ t: Tint) -> some View {
      let isSelected = t.id == tint.id
      let fill = Color(red: 1 - (1 - t.red) * SWATCH_GAIN, green: 1 - (1 - t.green) * SWATCH_GAIN,
         blue: 1 - (1 - t.blue) * SWATCH_GAIN)

      return Button {
         storedTint = t.stored
      } label: {
         ZStack {
            Circle().fill(fill)
            if t.id == NO_TINT.id {
               // A slash marks the swatch that removes the tint.
               Path { (path) in
                  path.move(to: CGPoint(x: SWATCH_SIZE * 0.25, y: SWATCH_SIZE * 0.75))
                  path.addLine(to: CGPoint(x: SWATCH_SIZE * 0.75, y: SWATCH_SIZE * 0.25))
               }
               .stroke(.secondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            Circle().strokeBorder(.black.opacity(0.15), lineWidth: 0.5)
         }
         .frame(width: SWATCH_SIZE, height: SWATCH_SIZE)
         .padding(SWATCH_RING)
         .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 2).opacity(isSelected ? 1 : 0))
         .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .help(t.name)
      .accessibilityLabel(t.name)
      .accessibilityAddTraits(isSelected ? .isSelected : [])
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
      // "Theme off" starts Logic Pro the plain way, without injecting the library. (20.11.2026)
      open.arguments = themeOff
         ? [ "-n", "-a", LOGIC_PATH ]
         : [ "-n", "--env", "DYLD_INSERT_LIBRARIES=\(library)", "-a", LOGIC_PATH ]
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
