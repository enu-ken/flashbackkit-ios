#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// 「端末を2回振ると起動できる」一回限りヒント（中央アラート風カード）。
///
/// `FlashbackSettingsStore.floatingButtonVisible` を OFF にした直後、FAB が消えて起動方法が
/// 見えなくなるため、**シェイク2回でも起動できる**ことをその場で一度だけ伝える受動的 FYI。
/// 端末1回（`hasSeenShakeHint`）で抑制する。プライミング（`.sheet`/能動ステップ）とは役割が違うため、
/// 中央アラート風カードで差別化する（正本 shakehint.jsx・採用コピー C＝見出しなし）。
///
/// 色ルール厳守: 録画と無関係の中立案内なので **オレンジは使わない**。基調は Slate（中立ブランド）、
/// OK は標準の systemBlue（iOS アラート流儀のボーダレス）。
struct ShakeHintView: View {
    /// OK で閉じる。
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // アニメする端末グリフ（支点は下端・±12°/±9pt の2回シェイク）。装飾なので VoiceOver 非対象。
                ShakeGlyph()
                    .frame(width: 132, height: 132)

                // 採用コピー C: 見出しなし・本文のみ・常に「2 回」と明示する。
                Text("端末を 2 回振ると、レポートを起動できます。")
                    .font(.subheadline)
                    .foregroundStyle(FlashbackColor.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                    .padding(.horizontal, 4)
                    .accessibilitySortPriority(2)             // 読み上げ順: 本文 → OK
            }
            .padding(.top, 18)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // OK: iOS アラート流儀（上部 0.5 セパレータ＋ボーダレス systemBlue）。
            Divider()
            Button(action: onDismiss) {
                Text("OK")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FlashbackColor.settingsLink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
            }
            .accessibilitySortPriority(1)
        }
        .frame(width: 270)                                   // 標準 iOS アラート幅
        .background(Self.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 20, y: 12)
        .accessibilityElement(children: .contain)
    }

    /// カード面。ライト = systemBackground（白）/ ダーク = secondarySystemBackground（#1C1C1E）。
    /// 暗転した背景（おやすみ Settings）の上で浮く（README「Card surface = systemBackground / secondarySystemBackground」）。
    static let cardBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
    })
}

// MARK: - アニメする端末グリフ

/// 端末を左右に2回振る動作のループアニメーション（正本 shakehint.jsx `fbShake`/`fbArcs` の数値再現）。
///
/// 仕様（README「6. Shake Hint」）: 支点 = 下端中央。**回転 ±12° / 平行移動 ±9pt**、
/// 片振り ≈130ms ease-in-out。**4振り ≈520ms（= 2 shakes）→ 約1480ms 静止 → 2000ms ループ ∞**。
/// 動線アーク（Slate）は振りと同期して点滅（不透明度 0→0.85→0）。
/// 端末縦横比 ≈ 0.50（実機比）。`keyframeAnimator` は iOS17+ のため、iOS16 でも動くよう
/// 非同期ループ＋`withAnimation(.easeInOut)` でキーフレームを再現する。
///
/// **Reduce Motion** 時は transform を当てず、静止のアーク＋アイコンのみ（意味は本文が担う）。
struct ShakeGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var angle: Double = 0
    @State private var translateX: CGFloat = 0
    @State private var arcsOpacity: Double = 0

    private let slate = FlashbackColor.slate

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let phoneHeight = side * 0.68
            let phoneWidth = phoneHeight * 0.50          // 実機比

            ZStack {
                // 動線アーク（左右・振りに同期して点滅）。
                ShakeArcs()
                    .stroke(slate, style: StrokeStyle(lineWidth: side * (3.0 / 150), lineCap: .round, lineJoin: .round))
                    .opacity(reduceMotion ? 0.8 : arcsOpacity)

                // 端末グリフ（下端を支点に左右へ回転＋平行移動）。
                PhoneGlyph(slate: slate)
                    .frame(width: phoneWidth, height: phoneHeight)
                    .rotationEffect(.degrees(reduceMotion ? 0 : angle), anchor: .bottom)
                    .offset(x: reduceMotion ? 0 : translateX)
                    // 支点（端末の下端）を矩形の縦 84% に置く。
                    .position(x: side / 2, y: side * 0.84 - phoneHeight / 2)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)                       // 装飾。意味は本文の Text が持つ。
        .task {
            guard !reduceMotion else { return }
            await runLoop()
        }
    }

    /// 2000ms ループ: 4振り（520ms）→ 静止（1480ms）。CSS `fbShake`/`fbArcs` のタイムラインを再現。
    @MainActor
    private func runLoop() async {
        while !Task.isCancelled {
            // 0% → 3.25%: rest → +12°/+9pt（同時にアークをフェードイン）。
            apply(angle: 12, tx: 9, duration: 0.065, arcs: 0.85, arcsDuration: 0.08)
            if await sleep(0.065) { return }
            // 3.25% → 9.75%: -12°/-9pt（片振り ≈130ms）。
            apply(angle: -12, tx: -9, duration: 0.130)
            if await sleep(0.130) { return }
            apply(angle: 12, tx: 9, duration: 0.130)
            if await sleep(0.130) { return }
            apply(angle: -12, tx: -9, duration: 0.130)
            if await sleep(0.130) { return }
            // 22.75% → 26%: 中央へ戻す（アークをフェードアウト）。
            apply(angle: 0, tx: 0, duration: 0.065, arcs: 0, arcsDuration: 0.28)
            if await sleep(0.065) { return }
            // 26% → 100%: 静止（≈1480ms）。
            if await sleep(1.480) { return }
        }
    }

    @MainActor
    private func apply(angle: Double, tx: CGFloat, duration: Double, arcs: Double? = nil, arcsDuration: Double = 0) {
        withAnimation(.easeInOut(duration: duration)) {
            self.angle = angle
            self.translateX = tx
        }
        if let arcs {
            withAnimation(.easeInOut(duration: arcsDuration)) { self.arcsOpacity = arcs }
        }
    }

    /// キャンセルされたら `true` を返す（ループ終了）。
    private func sleep(_ seconds: Double) async -> Bool {
        do { try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
        catch { return true }
        return Task.isCancelled
    }
}

/// 端末グリフ（リング＋くさび＝中立 Time Slice マークを内蔵）。design 座標 48×96（実機比 0.50）を
/// frame へ等倍スケールして描く。全要素 Slate で「録画と無関係＝オレンジ不使用」を守る。
private struct PhoneGlyph: View {
    let slate: Color

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / 48                  // design viewBox 48 幅からのスケール
            ZStack(alignment: .topLeading) {
                // 筐体（塗りはカード面と同色＝輪郭のみ見える）。
                RoundedRectangle(cornerRadius: 11 * k, style: .continuous)
                    .fill(ShakeHintView.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11 * k, style: .continuous)
                            .stroke(slate, lineWidth: 3.2 * k)
                    )
                    .frame(width: 44 * k, height: 92 * k)
                    .offset(x: 2 * k, y: 2 * k)

                // スクリーン。
                RoundedRectangle(cornerRadius: 5.5 * k, style: .continuous)
                    .fill(Self.screen)
                    .frame(width: 35 * k, height: 74 * k)
                    .offset(x: 6.5 * k, y: 9 * k)

                // スピーカー。
                Capsule()
                    .fill(slate.opacity(0.5))
                    .frame(width: 12 * k, height: 2.2 * k)
                    .offset(x: 18 * k, y: 5.2 * k)

                // 中立ミニマーク（全 Slate・くさび @0.32）。design では translate(8,30) scale(0.50) で 32pt 角。
                TimeSliceMark(ringColor: slate, wedgeColor: slate.opacity(0.32), hubColor: slate)
                    .frame(width: 32 * k, height: 32 * k)
                    .offset(x: 8 * k, y: 30 * k)

                // ホームライン。
                Capsule()
                    .fill(slate.opacity(0.5))
                    .frame(width: 16 * k, height: 2.4 * k)
                    .offset(x: 16 * k, y: 88 * k)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// グリフ内スクリーン面（装飾）。ライト ≈ #F2F2F7 / ダーク ≈ #2C2C2E（正本の見え方準拠）。
    static let screen = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255, alpha: 1)
            : UIColor(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF7 / 255, alpha: 1)
    })
}

/// 動線アーク（左右）＋先端の小さな矢じり。design viewBox 150×150 を frame へ等倍スケール。
private struct ShakeArcs: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 150       // 150 座標からのスケール
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

        var path = Path()

        // 左アーク: design の M30 62 A24 24 …30 96（外＝左へ膨らむ）を二次ベジェで等価再現。
        path.move(to: p(30, 62))
        path.addQuadCurve(to: p(30, 96), control: p(16, 79))
        // 左の矢じり: M28 67 l-6 -4 m6 4 l-5 6（左上＝振り出し方向を指す）。
        path.move(to: p(28, 67)); path.addLine(to: p(22, 63))
        path.move(to: p(28, 67)); path.addLine(to: p(23, 73))

        // 右アーク: M120 62 A24 24 …120 96（外＝右へ膨らむ）。
        path.move(to: p(120, 62))
        path.addQuadCurve(to: p(120, 96), control: p(134, 79))
        // 右の矢じり: M122 67 l6 -4 m-6 4 l5 6
        path.move(to: p(122, 67)); path.addLine(to: p(128, 63))
        path.move(to: p(122, 67)); path.addLine(to: p(127, 73))

        return path
    }
}

// MARK: - 提示ホスト（暗転スクリム＋中央カード）

/// overlay window 上に暗転スクリムと中央カードを重ねる提示ホスト。
/// 提示は `.overFullScreen` + `.crossDissolve`（FlashbackPresenter）で、カードはばね効果で
/// わずかに拡大して現れる（プライミングのスライドアップとは別の「アラート」感）。
struct ShakeHintHostView: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()
            ShakeHintView(onDismiss: onDismiss)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

#if DEBUG
#Preview("Shake Hint") {
    ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        ShakeHintHostView(onDismiss: {})
    }
}
#endif
#endif
