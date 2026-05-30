import SwiftUI
import FlashbackKit

/// FlashbackKit の仮UIループを Simulator で確認するためのホスト画面。
///
/// 起動時に `Flashback.start()` を呼ぶと、SDK が overlay window に
/// デバッグ用フローティングボタン（🐞）を出す。
/// ボタン → ReportView → コメント入力 → 送信 でループが回る。
/// Webhook 未設定なので、送信内容は Xcode コンソールに出力される。
struct ContentView: View {
    @State private var counter = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("FlashbackKit Example")
                .font(.title2.bold())

            Text("右下の 🐞 ボタンでレポート UI を開く")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Stepper("ホスト操作カウンタ: \(counter)", value: $counter)
                .padding(.horizontal, 40)
        }
        .onAppear {
            // Webhook を設定するとここから Slack へ送れる。
            // 未設定（nil）の場合はレポート内容をコンソール出力する。
            Flashback.start(
                configuration: .init(
                    slackWebhookURL: nil,
                    debugTriggerEnabled: true
                )
            )
        }
    }
}
