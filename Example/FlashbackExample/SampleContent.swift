import SwiftUI

// MARK: - Sample data (general-consumer demo content)

/// Static, deterministic sample content for the rich Gallery / Activity tabs.
///
/// Deliberately fixed (no randomness) so the live screens and the mock recording clip show the
/// same thing every run — important for repeatable promo capture.
enum SampleData {

    // MARK: Gallery

    /// A photo-grid card. No bundled image assets (keeps the Example dependency-free); each card is
    /// a curated two-color gradient with a faint SF Symbol watermark, so the grid reads like a real
    /// photo / discovery feed.
    struct Photo: Identifiable {
        let id = UUID()
        let title: String
        let author: String
        let symbol: String
        let top: Color
        let bottom: Color
    }

    static let photos: [Photo] = [
        Photo(title: "Coastline at dawn", author: "Mika R.", symbol: "water.waves", top: rgb(0x2E5BFF), bottom: rgb(0x18C8FF)),
        Photo(title: "Desert highway", author: "Leo K.", symbol: "sun.max.fill", top: rgb(0xFF8A3D), bottom: rgb(0xFF3D77)),
        Photo(title: "Pine ridge", author: "Sora", symbol: "tree.fill", top: rgb(0x16A34A), bottom: rgb(0xA3E635)),
        Photo(title: "Night market", author: "Yui T.", symbol: "fork.knife", top: rgb(0x7C3AED), bottom: rgb(0xEC4899)),
        Photo(title: "Old town stairs", author: "Daniel", symbol: "building.columns.fill", top: rgb(0xF59E0B), bottom: rgb(0xB45309)),
        Photo(title: "Harbor lights", author: "Mei", symbol: "sailboat.fill", top: rgb(0x0EA5E9), bottom: rgb(0x1E3A8A)),
        Photo(title: "Rooftop garden", author: "Aki", symbol: "leaf.fill", top: rgb(0x10B981), bottom: rgb(0x065F46)),
        Photo(title: "Snow pass", author: "Noa", symbol: "snowflake", top: rgb(0x93C5FD), bottom: rgb(0x4338CA)),
        Photo(title: "Tea fields", author: "Haru", symbol: "cup.and.saucer.fill", top: rgb(0x84CC16), bottom: rgb(0x14532D)),
        Photo(title: "Lantern alley", author: "Rin", symbol: "lightbulb.fill", top: rgb(0xF43F5E), bottom: rgb(0x7E22CE)),
        Photo(title: "Salt flats", author: "Ben", symbol: "cloud.sun.fill", top: rgb(0xFDE68A), bottom: rgb(0xF59E0B)),
        Photo(title: "Subway platform", author: "Kai", symbol: "tram.fill", top: rgb(0x64748B), bottom: rgb(0x0F172A)),
        Photo(title: "Cherry path", author: "Emi", symbol: "camera.macro", top: rgb(0xFBCFE8), bottom: rgb(0xDB2777)),
        Photo(title: "Glacier bay", author: "Tomo", symbol: "mountain.2.fill", top: rgb(0x22D3EE), bottom: rgb(0x0E7490)),
        Photo(title: "Dune ripples", author: "Lia", symbol: "wind", top: rgb(0xFCD34D), bottom: rgb(0xC2410C)),
        Photo(title: "Forest creek", author: "Jun", symbol: "drop.fill", top: rgb(0x34D399), bottom: rgb(0x1D4ED8)),
        Photo(title: "City at dusk", author: "Eva", symbol: "building.2.fill", top: rgb(0xA78BFA), bottom: rgb(0x4C1D95)),
        Photo(title: "Wildflower hill", author: "Ren", symbol: "camera.macro", top: rgb(0xFB7185), bottom: rgb(0x9D174D)),
    ]

    // MARK: Activity feed

    struct ActivityItem: Identifiable {
        let id = UUID()
        let initials: String
        let name: String
        let action: String
        let time: String
        let tint: Color
        let unread: Bool
    }

    /// Activity feed grouped into sections. Sized to overflow the viewport so "scroll to the
    /// bottom" (which triggers the simulated bug) is a real gesture.
    static let activitySections: [(title: String, items: [ActivityItem])] = [
        ("TODAY", [
            ActivityItem(initials: "MR", name: "Mika Rossi", action: "liked your photo “Coastline at dawn”", time: "2m", tint: rgb(0x2E5BFF), unread: true),
            ActivityItem(initials: "LK", name: "Leo Kim", action: "started following you", time: "18m", tint: rgb(0xFF8A3D), unread: true),
            ActivityItem(initials: "S", name: "Sora", action: "commented: “the light here is unreal”", time: "41m", tint: rgb(0x16A34A), unread: true),
            ActivityItem(initials: "YT", name: "Yui Tanaka", action: "saved “Night market” to Inspiration", time: "1h", tint: rgb(0x7C3AED), unread: false),
            ActivityItem(initials: "DL", name: "Daniel", action: "replied to your comment", time: "3h", tint: rgb(0xF59E0B), unread: false),
            ActivityItem(initials: "ME", name: "Mei", action: "added “Harbor lights” to a board", time: "5h", tint: rgb(0x0EA5E9), unread: false),
        ]),
        ("THIS WEEK", [
            ActivityItem(initials: "AK", name: "Aki", action: "shared “Rooftop garden”", time: "Mon", tint: rgb(0x10B981), unread: false),
            ActivityItem(initials: "NO", name: "Noa", action: "invited you to the “Winter” album", time: "Mon", tint: rgb(0x4338CA), unread: false),
            ActivityItem(initials: "HA", name: "Haru", action: "liked 4 of your photos", time: "Tue", tint: rgb(0x14532D), unread: false),
            ActivityItem(initials: "RI", name: "Rin", action: "mentioned you in “Lantern alley”", time: "Wed", tint: rgb(0x7E22CE), unread: false),
            ActivityItem(initials: "BE", name: "Ben", action: "started following you", time: "Wed", tint: rgb(0xF59E0B), unread: false),
            ActivityItem(initials: "KA", name: "Kai", action: "commented: “love the framing”", time: "Thu", tint: rgb(0x0F172A), unread: false),
            ActivityItem(initials: "EM", name: "Emi", action: "saved “Cherry path”", time: "Fri", tint: rgb(0xDB2777), unread: false),
        ]),
        ("EARLIER", [
            ActivityItem(initials: "TO", name: "Tomo", action: "liked your photo “Glacier bay”", time: "May 28", tint: rgb(0x0E7490), unread: false),
            ActivityItem(initials: "LI", name: "Lia", action: "shared your profile", time: "May 26", tint: rgb(0xC2410C), unread: false),
            ActivityItem(initials: "JU", name: "Jun", action: "added “Forest creek” to Favorites", time: "May 24", tint: rgb(0x1D4ED8), unread: false),
            ActivityItem(initials: "EV", name: "Eva", action: "commented: “those colors!”", time: "May 22", tint: rgb(0x4C1D95), unread: false),
            ActivityItem(initials: "RE", name: "Ren", action: "started following you", time: "May 20", tint: rgb(0x9D174D), unread: false),
            ActivityItem(initials: "SO", name: "Sora", action: "liked your comment", time: "May 19", tint: rgb(0x16A34A), unread: false),
            ActivityItem(initials: "YT", name: "Yui Tanaka", action: "invited you to “Spring” album", time: "May 17", tint: rgb(0x7C3AED), unread: false),
        ]),
    ]

    /// Total laid-out height of the gallery screen at the given width (header + eager grid). Used by
    /// the mock-clip renderer to compute the scroll distance precisely.
    static func galleryContentHeight(width: CGFloat) -> CGFloat {
        GalleryHeader.height + PhotoGrid.height(itemCount: photos.count, width: width)
    }

    /// Total laid-out height of the activity feed (header + all sections). Used by the mock-clip
    /// renderer to scroll exactly to the bottom (where the simulated bug fires).
    static func activityContentHeight() -> CGFloat {
        var h = ActivityHeader.height
        for section in activitySections {
            h += ActivityFeedScreen.sectionTitleHeight
            h += CGFloat(section.items.count) * ActivityFeedScreen.rowHeight
            h += ActivityFeedScreen.sectionBottomPadding
        }
        return h + ActivityFeedScreen.bottomPadding
    }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Reusable views (shared by the live tabs and the mock-clip renderer)

/// A single gallery card: gradient "photo" + faint symbol watermark + a bottom caption (title / author).
struct PhotoCard: View {
    let photo: SampleData.Photo

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [photo.top, photo.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: photo.symbol)
                .font(.system(size: 70, weight: .semibold))
                .foregroundStyle(.white.opacity(0.16))
                .offset(x: 46, y: 16)

            LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 2) {
                Text(photo.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(photo.author)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 7, y: 4)
    }
}

/// Large-title gallery header with a search pill. Fixed height so the clip renderer's scroll math is exact.
struct GalleryHeader: View {
    static let height: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gallery")
                    .font(.largeTitle.bold())
                Spacer()
                Image(systemName: "person.crop.circle")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text("Search photos and people")
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(height: Self.height, alignment: .top)
    }
}

/// Eager (non-lazy) photo grid with a deterministic laid-out height. Used by the live Gallery tab
/// and by the mock-clip renderer (which needs every row realized regardless of scroll offset, and a
/// known total height).
struct PhotoGrid: View {
    let items: [SampleData.Photo]
    var width: CGFloat = 390

    static let columns = 2
    static let spacing: CGFloat = 12
    static let hPadding: CGFloat = 16
    static let topPadding: CGFloat = 8
    static let bottomPadding: CGFloat = 28
    private static let aspect: CGFloat = 4.0 / 3.0   // portrait card height / width

    static func cardWidth(for width: CGFloat) -> CGFloat {
        (width - hPadding * 2 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }
    static func cardHeight(for width: CGFloat) -> CGFloat {
        cardWidth(for: width) * aspect
    }
    static func height(itemCount: Int, width: CGFloat) -> CGFloat {
        let rows = Int(ceil(Double(itemCount) / Double(columns)))
        return topPadding
            + CGFloat(rows) * cardHeight(for: width)
            + CGFloat(max(0, rows - 1)) * spacing
            + bottomPadding
    }

    private var rows: [[SampleData.Photo]] {
        stride(from: 0, to: items.count, by: Self.columns).map {
            Array(items[$0..<min($0 + Self.columns, items.count)])
        }
    }

    var body: some View {
        let cw = Self.cardWidth(for: width)
        let ch = Self.cardHeight(for: width)
        VStack(spacing: Self.spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Self.spacing) {
                    ForEach(row) { photo in
                        PhotoCard(photo: photo).frame(width: cw, height: ch)
                    }
                    if row.count < Self.columns { Spacer(minLength: 0) }
                }
            }
        }
        .padding(.horizontal, Self.hPadding)
        .padding(.top, Self.topPadding)
        .padding(.bottom, Self.bottomPadding)
    }
}

/// The full gallery screen (header + eager grid). Shared verbatim by the live tab and the clip
/// renderer so the recorded preview matches what's on screen.
struct GalleryScreen: View {
    var width: CGFloat = 390

    var body: some View {
        VStack(spacing: 0) {
            GalleryHeader()
            PhotoGrid(items: SampleData.photos, width: width)
        }
    }
}

/// A single activity-feed row: gradient avatar (initials) + name/action + time + unread dot.
struct ActivityRow: View {
    let item: SampleData.ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [item.tint.opacity(0.95), item.tint.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(item.initials)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 3) {
                (Text(item.name).font(.subheadline.weight(.semibold))
                 + Text("  \(item.action)").font(.subheadline).foregroundColor(.secondary))
                    .lineLimit(2)
                Text(item.time)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            if item.unread {
                Circle().fill(Color.orange).frame(width: 9, height: 9)
            }
        }
    }
}

/// Large-title "Activity" header with filter chips. Fixed height for exact clip-scroll math.
struct ActivityHeader: View {
    static let height: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.largeTitle.bold())
                Spacer()
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                chip("All", selected: true)
                chip("Mentions", selected: false)
                chip("Unread", selected: false)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(height: Self.height, alignment: .top)
    }

    private func chip(_ title: String, selected: Bool) -> some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(selected ? Color.white : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(selected ? Color.accentColor : Color(uiColor: .secondarySystemBackground), in: Capsule())
    }
}

/// The full activity screen (header + grouped sections), eager-laid-out with a deterministic height.
/// Shared by the live Activity tab and the mock-clip renderer so the recorded preview matches what's
/// on screen.
struct ActivityFeedScreen: View {
    var width: CGFloat = 390

    static let rowHeight: CGFloat = 66
    static let sectionTitleHeight: CGFloat = 34
    static let sectionBottomPadding: CGFloat = 18
    static let bottomPadding: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActivityHeader()
            ForEach(Array(SampleData.activitySections.enumerated()), id: \.offset) { _, section in
                sectionView(title: section.title, items: section.items)
            }
        }
        .padding(.bottom, Self.bottomPadding)
    }

    private func sectionView(title: String, items: [SampleData.ActivityItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .frame(height: Self.sectionTitleHeight - 8, alignment: .bottom)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    ActivityRow(item: item)
                        .frame(height: Self.rowHeight)
                        .padding(.horizontal, 16)
                        .overlay(alignment: .bottom) {
                            if idx < items.count - 1 {
                                Rectangle()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 0.5)
                                    .padding(.leading, 68)
                            }
                        }
                }
            }
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
        .padding(.bottom, Self.sectionBottomPadding)
    }
}

/// Simulated app error ("a bug just happened") shown at the end of the activity list and baked into
/// the final seconds of the mock recording. The cue to launch a Flashback report. Solid (non-blur)
/// card so it renders identically live and inside `ImageRenderer`.
struct BugErrorDialog: View {
    /// Card scale (used by the clip renderer for a pop-in). Live uses 1.
    var cardScale: CGFloat = 1
    /// Dismiss handler (live). When nil (clip render), the button is shown but inert.
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.15)).frame(width: 72, height: 72)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.red)
                }
                Text("Something went wrong")
                    .font(.title3.bold())
                Text("We hit an unexpected error while loading more.\nError code: E-1024")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                dismissButton
                    .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: 300)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))
            .scaleEffect(cardScale)
        }
    }

    @ViewBuilder
    private var dismissButton: some View {
        let label = Text("Dismiss")
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        if let onDismiss {
            Button(action: onDismiss) { label }
        } else {
            label   // clip render: visual only
        }
    }
}
