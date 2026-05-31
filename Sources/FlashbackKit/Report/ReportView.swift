#if canImport(SwiftUI)
import SwiftUI

/// レポート入力 UI: 直前クリップのプレビュー＋トリミング + コメント + 送信。
///
/// `clipURL` が無い場合（Simulator / 録画不可）はコメントのみの最小フォームになる。
struct ReportView: View {
    let clipURL: URL?
    /// 送信。クリップがある場合は選択範囲（秒）を伴う。無い場合は nil。
    let onSend: (String, ClosedRange<Double>?) -> Void
    let onCancel: () -> Void

    @State private var comment: String = ""
    /// 選択範囲（秒）。`0...0` は未確定で、トリマーが尺確定後に全体へ広げる。
    @State private var selection: ClosedRange<Double> = 0...0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    #if canImport(AVFoundation) && canImport(UIKit)
                    if let clipURL {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("必要な部分だけ残す")
                                .font(.subheadline.weight(.semibold))
                            VideoTrimmerView(url: clipURL, selection: $selection)
                        }
                    }
                    #endif

                    VStack(alignment: .leading, spacing: 6) {
                        Text("何が起きた？")
                            .font(.subheadline.weight(.semibold))
                        TextEditor(text: $comment)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.3))
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("Flashback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        onSend(comment, clipURL == nil ? nil : selection)
                    }
                    .disabled(comment.isEmpty)
                }
            }
        }
    }
}
#endif
