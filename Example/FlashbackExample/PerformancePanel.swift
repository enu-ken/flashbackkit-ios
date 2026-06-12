#if DEBUG
import SwiftUI
import Charts
import QuartzCore
import FlashbackKit

// MARK: - Performance monitor (Debug tab)

/// Measures what continuous ring-buffer recording actually costs, to answer the questions
/// every adopting team asks: "doesn't always-on recording degrade performance?" and "what
/// about memory / disk pressure?".
///
/// Usage: watch the baseline with recording off, then toggle recording (floating button)
/// and compare. ReplayKit delivers frames only while the screen *changes* — a static
/// screen costs almost nothing — so a load generator (Off / Light / Heavy) is built in;
/// Heavy approximates the worst case (full-rate animation = continuous frame supply +
/// encode).
///
/// What each metric demonstrates:
/// - **Memory**: the ring keeps segments on *disk*, not in RAM. The footprint delta while
///   recording is roughly the encoder session, and it stays flat over time (no growth).
/// - **CPU**: frame capture runs in replayd (out of process); the in-process cost is the
///   sample callback + the hardware H.264 encoder session (AVAssetWriter).
/// - **Ring files**: segment count / size plateau at the retention window — recording for
///   an hour stores no more than the last N seconds.
/// - **Frame pacing**: the worst gap between UI frames; recording-induced jank would show
///   up here as spikes while recording is on.
/// Compact live card for the Home tab: recording state plus the headline numbers, linking
/// to the full `PerformancePanel`. Runs the same sampler in "lite" mode (1 Hz, no display
/// link) so Home stays cheap.
struct PerfSummaryCard: View {
    @StateObject private var sampler = PerfSampler(framePacing: false)

    private var isRecording: Bool { sampler.samples.last?.recording ?? false }

    var body: some View {
        NavigationLink {
            PerformancePanel()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isRecording ? Color.red : Color.secondary)
                        .frame(width: 9, height: 9)
                    Text("Recording cost monitor")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                Text(sampler.samples.last.map { sample in
                    String(format: String(localized: "%.0f MB · CPU %.1f%% · ring %.1f MB"),
                           sample.footprintMB, sample.cpuPercent, sampler.ringMegabytes)
                } ?? "—")
                .font(.callout.bold())
                .monospacedDigit()
                Text("Tap for charts and the load generator")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onAppear { sampler.start() }
        .onDisappear { sampler.stop() }
    }
}

struct PerformancePanel: View {
    @StateObject private var sampler = PerfSampler(framePacing: true)
    @State private var load: LoadLevel = .light
    /// CSV written by the export button, presented via the share sheet.
    @State private var csvExport: ExportedCSV?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                recordingBanner
                metricTiles
                chartSection(title: "Memory footprint (MB)",
                             values: sampler.samples.map { ($0.date, $0.footprintMB, $0.recording) })
                chartSection(title: "CPU — app total, % of one core",
                             values: sampler.samples.map { ($0.date, $0.cpuPercent, $0.recording) })
                loadGenerator
                footnotes
            }
            .padding(16)
        }
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Phase boundary for soak comparisons: clear history so peak / avg / CSV
                // cover exactly one condition (e.g. recording OFF, then ON).
                Button {
                    sampler.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                Button {
                    if let url = sampler.exportCSV() {
                        csvExport = ExportedCSV(url: url)
                    }
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $csvExport) { export in
            ActivityView(items: [export.url])
        }
        .onAppear {
            sampler.start()
            // Unattended 10-minute soaks must not auto-lock (lock = suspend = dead samples).
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            sampler.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    /// Current recording state, refreshed with each sample (drives the banner color).
    private var isRecording: Bool { sampler.samples.last?.recording ?? false }

    private var recordingBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRecording ? Color.red : Color.secondary)
                .frame(width: 10, height: 10)
            Text(isRecording
                 ? "Recording ON — ring buffer running"
                 : "Recording OFF — toggle via the floating button to compare")
                .font(.footnote.weight(.semibold))
            Spacer()
            Text(sampler.thermalLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    private var metricTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(
                title: "Memory",
                value: sampler.samples.last.map { String(format: "%.0f MB", $0.footprintMB) } ?? "—",
                detail: String(format: String(localized: "peak %.0f MB"), sampler.peakFootprintMB)
            )
            MetricTile(
                title: "CPU (app)",
                value: sampler.samples.last.map { String(format: "%.1f %%", $0.cpuPercent) } ?? "—",
                detail: String(format: String(localized: "avg %.1f %%"), sampler.averageCPUPercent)
            )
            MetricTile(
                title: "Ring on disk",
                value: String(format: "%.1f MB", sampler.ringMegabytes),
                detail: String(format: String(localized: "%d segment files"), sampler.ringSegmentCount)
            )
            MetricTile(
                title: "Frame pacing",
                value: sampler.samples.last.map { String(format: "%.0f fps", $0.fps) } ?? "—",
                detail: sampler.samples.last.map {
                    String(format: String(localized: "worst gap %.0f ms"), $0.worstGapMS)
                } ?? ""
            )
        }
    }

    /// Line chart of one metric over the sample window, colored by the recording state at
    /// each sample (orange = recording) so the on/off delta is visible at a glance.
    /// Long histories are thinned to ~360 display points so a 15-minute chart redrawn every
    /// second doesn't become its own load; stats and the CSV keep the full resolution.
    private func chartSection(title: LocalizedStringKey,
                              values: [(date: Date, value: Double, recording: Bool)]) -> some View {
        let step = max(1, values.count / 360)
        let display = step == 1
            ? values
            : values.enumerated().compactMap { $0.offset % step == 0 ? $0.element : nil }
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Chart(Array(display.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Recording", point.recording ? "REC" : "off"))
                .interpolationMethod(.monotone)
            }
            .chartForegroundStyleScale(["REC": Color.orange, "off": Color.secondary])
            .chartXAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: 120)
        }
    }

    private var loadGenerator: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screen load (frame supply)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Screen load", selection: $load) {
                ForEach(LoadLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)
            LoadStage(level: load)
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
            Text("ReplayKit only delivers frames while the screen changes — a static screen costs almost nothing. Heavy redraws a full-width canvas every frame ≒ worst case while recording.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footnotes: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Soak comparison (answering \"what does it cost?\")")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("• Fix the load, tap reset, leave it ~10 min with recording OFF, export the CSV. Then turn recording ON, reset, and repeat. The ON−OFF delta is the SDK's net cost.")
            Text("• Auto-lock is disabled while this panel is visible, so unattended soaks keep running.")
            Text("How to read the numbers")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            Text("• Memory: ring segments live on disk, not in RAM — the recording delta is roughly the encoder session and stays flat over time.")
            Text("• Ring on disk: plateaus at the retention window (the ring drops old segments) — an hour of recording stores no more than the last N seconds.")
            Text("• CPU: frame capture runs in replayd (out of process). What you see here is the in-process cost: sample callbacks + the hardware H.264 encoder.")
            Text("• Frame pacing: spikes in the worst frame gap while recording would indicate UI jank caused by the SDK.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

/// Identifiable wrapper so `.sheet(item:)` can present the exported CSV's share sheet.
private struct ExportedCSV: Identifiable {
    let id = UUID()
    let url: URL
}

/// Minimal `UIActivityViewController` bridge for sharing the exported CSV
/// (AirDrop / Files / Slack etc.).
private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// One numeric metric card (current value + a small detail line).
private struct MetricTile: View {
    let title: LocalizedStringKey
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Load generator

/// Selectable screen-motion level. ReplayKit's frame supply (and therefore the encode
/// cost) follows screen changes, so the level directly controls how hard recording works.
private enum LoadLevel: String, CaseIterable, Identifiable {
    case off, light, heavy
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .off: return "Off (static)"
        case .light: return "Light"
        case .heavy: return "Heavy"
        }
    }
}

/// The animated content for each load level. `off` renders a static placeholder (no frame
/// supply), `light` a small pulsing dot (small dirty region), `heavy` a full-width canvas
/// redrawn every frame (continuous full-region updates ≒ worst case).
private struct LoadStage: View {
    let level: LoadLevel

    var body: some View {
        switch level {
        case .off:
            Text("static — no frames for ReplayKit")
                .font(.caption)
                .foregroundStyle(.tertiary)
        case .light:
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Circle()
                    .fill(.orange)
                    .frame(width: 18, height: 18)
                    .scaleEffect(1 + 0.5 * sin(t * 4))
                    .opacity(0.6 + 0.4 * sin(t * 4))
            }
        case .heavy:
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    // Full-region redraw every frame: 48 drifting hue-cycling circles.
                    for i in 0..<48 {
                        let phase = t * 1.6 + Double(i) * .pi / 24
                        let x = size.width * (0.5 + 0.46 * sin(phase))
                        let y = size.height * (0.5 + 0.38 * cos(phase * 1.3 + Double(i)))
                        let hue = (t / 5 + Double(i) / 48).truncatingRemainder(dividingBy: 1)
                        let rect = CGRect(x: x - 8, y: y - 8, width: 16, height: 16)
                        ctx.fill(Path(ellipseIn: rect),
                                 with: .color(Color(hue: hue, saturation: 0.8, brightness: 0.95)))
                    }
                }
            }
        }
    }
}

// MARK: - Sampler

/// Samples process metrics once per second while the panel is visible, and counts UI
/// frames via CADisplayLink in between (fps + worst frame gap per window).
@MainActor
private final class PerfSampler: NSObject, ObservableObject {
    struct Sample {
        let date: Date
        let footprintMB: Double
        let cpuPercent: Double
        let fps: Double
        let worstGapMS: Double
        let recording: Bool
        let ringMB: Double
        let ringSegments: Int
    }

    @Published private(set) var samples: [Sample] = []
    @Published private(set) var ringSegmentCount = 0
    @Published private(set) var ringMegabytes = 0.0
    @Published private(set) var thermalLabel = ""

    /// 15 minutes of history at 1 Hz — a full 10-minute soak phase fits in one chart
    /// (the submission evidence for "flat over 10 minutes"). Charts thin the display
    /// points; stats and the CSV export use the full history.
    private static let maxSamples = 900

    /// Whether to run the CADisplayLink for fps / frame-gap tracking. The Home card runs
    /// without it (1 Hz sampling only) so the always-visible summary stays cheap.
    private let framePacing: Bool
    private var displayLink: CADisplayLink?
    private var samplingTask: Task<Void, Never>?
    /// Frame counters accumulated by the display link between samples.
    private var tickCount = 0
    private var lastTickTimestamp: CFTimeInterval = 0
    private var worstGap: CFTimeInterval = 0
    private var lastSampleDate = Date()

    init(framePacing: Bool) {
        self.framePacing = framePacing
        super.init()
    }

    var peakFootprintMB: Double { samples.map(\.footprintMB).max() ?? 0 }
    var averageCPUPercent: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.cpuPercent).reduce(0, +) / Double(samples.count)
    }

    func start() {
        guard samplingTask == nil else { return }           // idempotent (onAppear can re-fire)
        lastSampleDate = Date()
        tickCount = 0
        lastTickTimestamp = 0
        worstGap = 0
        if framePacing {
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
        samplingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                self.sample()
            }
        }
        sample()                                            // first data point immediately
    }

    func stop() {
        displayLink?.invalidate()                           // releases the link's strong ref to self
        displayLink = nil
        samplingTask?.cancel()
        samplingTask = nil
    }

    /// Display-link tick on the main run loop: count frames and track the worst gap.
    @objc private func tick(_ link: CADisplayLink) {
        tickCount += 1
        if lastTickTimestamp > 0 {
            worstGap = max(worstGap, link.timestamp - lastTickTimestamp)
        }
        lastTickTimestamp = link.timestamp
    }

    private func sample() {
        let now = Date()
        let elapsed = max(0.001, now.timeIntervalSince(lastSampleDate))
        let fps = Double(tickCount) / elapsed
        let gapMS = worstGap * 1000
        tickCount = 0
        worstGap = 0
        lastSampleDate = now

        let ring = Self.ringFilesOnDisk()
        ringSegmentCount = ring.count
        ringMegabytes = ring.megabytes
        thermalLabel = Self.thermalText(ProcessInfo.processInfo.thermalState)

        samples.append(Sample(
            date: now,
            footprintMB: Self.memoryFootprintMB(),
            cpuPercent: Self.appCPUPercent(),
            fps: fps,
            worstGapMS: gapMS,
            recording: Flashback.debugIsRecording,
            ringMB: ring.megabytes,
            ringSegments: ring.count
        ))
        if samples.count > Self.maxSamples {
            samples.removeFirst(samples.count - Self.maxSamples)
        }
    }

    /// Clear the history at a phase boundary (so peak / avg / CSV cover one condition only).
    func reset() {
        samples.removeAll()
        tickCount = 0
        lastTickTimestamp = 0
        worstGap = 0
        lastSampleDate = Date()
    }

    /// Write the sample history to a CSV in tmp and return its URL (for the share sheet).
    /// Deliberately NOT prefixed "flashback-" so the SDK's once-per-launch temp purge can
    /// never collide with a pending share on a later launch.
    func exportCSV() -> URL? {
        var lines = ["time,memory_mb,cpu_percent,fps,worst_frame_gap_ms,recording,ring_mb,ring_segments"]
        let iso = ISO8601DateFormatter()
        for s in samples {
            lines.append([
                iso.string(from: s.date),
                String(format: "%.1f", s.footprintMB),
                String(format: "%.1f", s.cpuPercent),
                String(format: "%.1f", s.fps),
                String(format: "%.0f", s.worstGapMS),
                s.recording ? "1" : "0",
                String(format: "%.2f", s.ringMB),
                String(s.ringSegments),
            ].joined(separator: ","))
        }
        let stamp = DateFormatter()
        stamp.dateFormat = "yyyyMMdd-HHmmss"
        stamp.locale = Locale(identifier: "en_US_POSIX")
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FlashbackPerf-\(stamp.string(from: Date())).csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: Process metrics (mach)

    /// App memory footprint in MB (`phys_footprint` — the figure Xcode's memory gauge shows).
    private static func memoryFootprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        return Double(info.phys_footprint) / 1_048_576
    }

    /// Total CPU usage of the app's threads, in % of one core (can exceed 100 on multi-core).
    private static func appCPUPercent() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threadList, &threadCount) == KERN_SUCCESS,
              let threads = threadList else { return 0 }
        defer {
            let bytes = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)), bytes)
        }
        var total = 0.0
        for i in 0..<Int(threadCount) {
            var info = thread_basic_info()
            var count = mach_msg_type_number_t(
                MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
            let kr = withUnsafeMutablePointer(to: &info) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            guard kr == KERN_SUCCESS, info.flags & TH_FLAGS_IDLE == 0 else { continue }
            total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100
        }
        return total
    }

    /// Count + total size of the SDK's ring segment files in tmp (`flashback-seg-*`).
    /// Demonstrates that disk usage plateaus at the retention window.
    private static func ringFilesOnDisk() -> (count: Int, megabytes: Double) {
        let fm = FileManager.default
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        guard let items = try? fm.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.fileSizeKey]) else { return (0, 0) }
        var count = 0
        var bytes = 0
        for url in items where url.lastPathComponent.hasPrefix("flashback-seg-") {
            count += 1
            bytes += (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return (count, Double(bytes) / 1_048_576)
    }

    private static func thermalText(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return String(localized: "thermal: nominal")
        case .fair: return String(localized: "thermal: fair")
        case .serious: return String(localized: "thermal: serious")
        case .critical: return String(localized: "thermal: critical")
        @unknown default: return "thermal: ?"
        }
    }
}
#endif
