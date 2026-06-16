#if DEBUG
import AVFoundation
import SwiftUI
import UIKit

/// DEBUG-only: renders the host app's own SwiftUI UI to a short `.mp4`, used as the Simulator's
/// mock "recording".
///
/// On the Simulator, ReplayKit in-app capture emits no frames, so there's no real clip. This
/// renders the live Gallery screen scrolling — via SwiftUI `ImageRenderer` → `AVAssetWriter`
/// (dependency-free) — so the report preview looks like a genuine screen recording of the app.
/// Wired into the SDK through `Flashback.enableSimulatorMockRecording`.
@MainActor
enum MockClipRenderer {
    /// Logical viewport (points); rendered at `scale` for crisp frames. 390×844 ≈ a modern iPhone.
    private static let viewport = CGSize(width: 390, height: 844)
    private static let scale: CGFloat = 3
    private static let fps: Int = 30
    private static let duration: Double = 6.5
    /// Fraction of the timeline spent scrolling; afterwards the feed holds and the bug pops in.
    private static let scrollPhase: Double = 0.68

    /// Cached so repeated triggers reuse identical footage (and return instantly). Regenerated if
    /// the file was purged.
    private static var cachedURL: URL?

    /// Renders the activity feed scrolling to the bottom, then a simulated bug dialog popping in over
    /// the final seconds; encodes it to an `.mp4` and returns the URL.
    static func makeActivityBugClip() async throws -> URL {
        if let cachedURL, FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        let pixel = CGSize(width: viewport.width * scale, height: viewport.height * scale)
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("flashback-mock-\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(pixel.width),
            AVVideoHeightKey: Int(pixel.height),
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard writer.canAdd(input) else { throw RenderError.writerSetup }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? RenderError.writerSetup }
        writer.startSession(atSourceTime: .zero)

        let total = max(2, Int(Double(fps) * duration))
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        // Scroll all the way to the bottom (where the bug fires).
        let scrollRange = max(0, SampleData.activityContentHeight() - viewport.height)

        for i in 0..<total {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 4_000_000)
            }
            let p = Double(i) / Double(total - 1)
            // Scroll over the first `scrollPhase` of the timeline, then hold while the bug pops in.
            let scrollT = min(p / scrollPhase, 1)
            let scrollY = flickScroll(scrollT, range: scrollRange)
            let bugProgress = max(0, min((p - scrollPhase) / 0.14, 1))

            let frame = ActivityClipFrame(scrollY: scrollY, bugProgress: bugProgress)
                .frame(width: viewport.width, height: viewport.height)
            let renderer = ImageRenderer(content: frame)
            renderer.scale = scale
            renderer.proposedSize = ProposedViewSize(viewport)

            guard let cg = renderer.cgImage,
                  let buffer = Self.pixelBuffer(from: cg, size: pixel) else { continue }
            adaptor.append(buffer, withPresentationTime: CMTimeMultiply(frameDuration, multiplier: Int32(i)))
            await Task.yield()
        }

        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? RenderError.encodeFailed
        }
        cachedURL = url
        return url
    }

    enum RenderError: Error { case writerSetup, encodeFailed }

    /// Decelerating ease-out (cubic): fast start, gentle settle — the feel of a finger flick.
    private static func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 3) }

    /// Flick-style scroll: a few quick decelerating flicks with short rests between them, so the
    /// recording reads like a person scrolling the feed rather than one slow continuous glide.
    /// `p` is scroll-phase progress (0...1); returns the vertical offset in points.
    private static func flickScroll(_ p: Double, range: CGFloat) -> CGFloat {
        // (timeFraction, distanceFraction): each flick moves fast then rests (flat) before the next.
        let keys: [(t: Double, d: Double)] = [
            (0.00, 0.00),
            (0.22, 0.38),   // flick 1
            (0.36, 0.38),   // rest
            (0.58, 0.76),   // flick 2
            (0.72, 0.76),   // rest
            (0.94, 1.00),   // flick 3 → bottom
            (1.00, 1.00),   // rest at bottom
        ]
        let t = max(0, min(p, 1))
        for i in 1..<keys.count where t <= keys[i].t {
            let (t0, d0) = keys[i - 1]
            let (t1, d1) = keys[i]
            let seg = t1 > t0 ? (t - t0) / (t1 - t0) : 1
            return CGFloat(d0 + (d1 - d0) * easeOut(seg)) * range
        }
        return range
    }

    private static func pixelBuffer(from cg: CGImage, size: CGSize) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        var pb: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(size.width), Int(size.height),
            kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pb
        )
        guard status == kCVReturnSuccess, let pixelBuffer = pb else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width), height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }
        ctx.draw(cg, in: CGRect(origin: .zero, size: size))
        return pixelBuffer
    }
}

/// One rendered frame: the activity feed offset by `scrollY`, clipped to the viewport, with the bug
/// dialog fading/scaling in once `bugProgress > 0`. Forced to dark mode for a premium look that
/// matches the README screenshots.
private struct ActivityClipFrame: View {
    let scrollY: CGFloat
    let bugProgress: Double

    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemBackground)
            ActivityFeedScreen(width: 390)
                .frame(width: 390, alignment: .top)
                .offset(y: -scrollY)
        }
        .frame(width: 390, height: 844, alignment: .top)
        .clipped()
        .overlay {
            if bugProgress > 0 {
                BugErrorDialog(cardScale: 0.9 + 0.1 * CGFloat(bugProgress))
                    .opacity(bugProgress)   // centered over the viewport
            }
        }
        .environment(\.colorScheme, .dark)
    }
}
#endif
