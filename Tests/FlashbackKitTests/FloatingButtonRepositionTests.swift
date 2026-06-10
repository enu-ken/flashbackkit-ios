#if canImport(UIKit)
import XCTest
import UIKit
@testable import FlashbackKit

/// Verifies the FAB re-clamps into the new container bounds on a size change (rotation /
/// iPad multitasking) via `repositionAfterBoundsChange`. A bare `UIView` container has zero
/// `safeAreaInsets` and no host tab bar, so expected centers come from `edgeMargin` + `half`
/// alone. The synchronous first `place` settles the position, so no RunLoop spin is needed.
final class FloatingButtonRepositionTests: XCTestCase {
    // FAB layout constants (mirrored from FloatingButtonView; see those static lets for origin).
    private let diameter: CGFloat = 56     // FloatingButtonView.diameter
    private let half: CGFloat = 28         // diameter / 2
    private let edgeMargin: CGFloat = 16   // FloatingButtonView.edgeMargin
    private let peek: CGFloat = 22         // FloatingButtonView.peek

    // FABPositionStore UserDefaults keys (mirrored to set up the saved state directly).
    private let edgeKey = "FlashbackKit.fabEdgeIsTrailing"
    private let yKey = "FlashbackKit.fabYFraction"
    private let tuckedKey = "FlashbackKit.fabTucked"

    private let portrait = CGRect(x: 0, y: 0, width: 393, height: 852)
    private let landscape = CGRect(x: 0, y: 0, width: 852, height: 393)

    override func setUp() {
        super.setUp()
        clearStore()
    }

    override func tearDown() {
        clearStore()
        super.tearDown()
    }

    /// Clears the persisted FAB position so tests don't pollute each other (or the device).
    /// `nonisolated`: `UserDefaults` is thread-safe, so this is callable from `setUp`/`tearDown`.
    private func clearStore() {
        let d = UserDefaults.standard
        d.removeObject(forKey: edgeKey)
        d.removeObject(forKey: yKey)
        d.removeObject(forKey: tuckedKey)
    }

    // MARK: - Tests

    /// Trailing edge, un-tucked: after a portrait→landscape resize, x re-clamps to the new
    /// right edge and y stays within the new clamp range.
    @MainActor
    func testRepositionTrailingUntucked() {
        UserDefaults.standard.set(true, forKey: edgeKey)    // trailing
        UserDefaults.standard.set(0.5, forKey: yKey)        // mid-height
        UserDefaults.standard.set(false, forKey: tuckedKey)

        let container = UIView(frame: portrait)
        let fab = FloatingButtonView()
        container.addSubview(fab)
        fab.place(in: container, corner: .bottomTrailing)

        // Portrait: right edge = width - edgeMargin - half.
        XCTAssertEqual(fab.center.x, 393 - edgeMargin - half, accuracy: 0.5)

        container.frame = landscape
        fab.repositionAfterBoundsChange(in: container, corner: .bottomTrailing)

        // Landscape: re-clamped to the new right edge.
        XCTAssertEqual(fab.center.x, 852 - edgeMargin - half, accuracy: 0.5)
        // y stays within the new vertical clamp range [minY, maxY].
        let minY = edgeMargin + half
        let maxY = landscape.height - edgeMargin - half
        XCTAssertGreaterThanOrEqual(fab.center.y, minY)
        XCTAssertLessThanOrEqual(fab.center.y, maxY)
    }

    /// Tucked at the trailing edge: after the resize, x tucks at the new right edge
    /// (width + half - peek), leaving only `peek` visible.
    @MainActor
    func testRepositionTuckedTrailing() {
        UserDefaults.standard.set(true, forKey: edgeKey)    // trailing
        UserDefaults.standard.set(0.5, forKey: yKey)
        UserDefaults.standard.set(true, forKey: tuckedKey)  // tucked

        let container = UIView(frame: portrait)
        let fab = FloatingButtonView()
        container.addSubview(fab)
        fab.place(in: container, corner: .bottomTrailing)

        container.frame = landscape
        fab.repositionAfterBoundsChange(in: container, corner: .bottomTrailing)

        // Tucked right edge: only `peek` shows past the new right edge.
        XCTAssertEqual(fab.center.x, 852 + half - peek, accuracy: 0.5)
    }

    /// No saved position: the default `.bottomTrailing` corner lands at the right edge in
    /// both orientations (saved-state load is skipped, corner default applies).
    @MainActor
    func testRepositionDefaultCornerNoSavedState() {
        let container = UIView(frame: portrait)
        let fab = FloatingButtonView()
        container.addSubview(fab)
        fab.place(in: container, corner: .bottomTrailing)

        XCTAssertEqual(fab.center.x, 393 - edgeMargin - half, accuracy: 0.5)
        XCTAssertEqual(fab.center.y, 852 - edgeMargin - half, accuracy: 0.5)

        container.frame = landscape
        fab.repositionAfterBoundsChange(in: container, corner: .bottomTrailing)

        XCTAssertEqual(fab.center.x, 852 - edgeMargin - half, accuracy: 0.5)
        XCTAssertEqual(fab.center.y, 393 - edgeMargin - half, accuracy: 0.5)
    }
}
#endif
