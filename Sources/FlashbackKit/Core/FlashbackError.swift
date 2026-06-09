import Foundation

/// Errors used internally by the recording / trimming pipeline.
///
/// Not part of the public contract: these are thrown and handled within the SDK
/// (the host interacts only through `Flashback.start(onReport:)`), so the type is `internal`.
enum FlashbackError: Error {
    /// The current build/environment has no ReplayKit implementation (non-iOS fallback).
    case notImplemented
    /// Recording isn't running or available, so there's no buffered clip to export.
    case recordingUnavailable
    /// Trimming/exporting the clip failed.
    case clipTrimFailed
}
