import Foundation

/// The artifact Flashback hands back to the host.
///
/// The core's responsibility ends at "record → trim → hand off the artifact." AI-generated
/// repro steps / probable cause and Slack delivery are the host's job, downstream of `onReport`.
public struct FlashbackReport: Sendable, Codable, Equatable, Hashable {
    /// One-line title entered by QA (the report screen's "title" field).
    public var title: String
    /// Device info bundled with the report.
    public var device: DeviceInfo
    /// Temp-file URL of the trimmed clip (nil when recording was unavailable). Copy/upload it host-side if you need to keep it.
    public var clipURL: URL?

    public init(title: String, device: DeviceInfo, clipURL: URL?) {
        self.title = title
        self.device = device
        self.clipURL = clipURL
    }
}
