import Foundation

/// FlashbackKit public entry point.
///
/// > Recall the moment before the bug.
public enum Flashback {

    /// FlashbackKit を起動する。
    /// バッファ録画を開始し、有効なトリガ（既定: シェイク / フローティングボタン）で
    /// レポート UI を出す。`configuration.triggers` で手段を絞れる。
    ///
    /// アプリ起動直後（SwiftUI `App.init` / `AppDelegate.didFinishLaunching` /
    /// `SceneDelegate.scene(_:willConnectTo:)` / ルートビューの `.onAppear` のいずれか）で
    /// 一度だけ呼ぶ。SceneDelegate 採用アプリでシーン接続前（`didFinishLaunching`）に呼んでも、
    /// SDK 内部でシーン接続を待って overlay window を自動設置するため、呼び出しタイミングに
    /// 依存せず動作する。
    ///
    /// - Parameter onReport: 録画→トリム→共有まで終えた成果物 `FlashbackReport`
    ///   （タイトル・端末情報・クリップ URL）をホストへ手渡すコールバック（唯一の拡張点）。
    ///   AI 要約・Slack 送信・自社バックエンド送信などホスト固有の処理はここで行う
    ///   （SDK の役割は成果物を渡すところまで）。MainActor で呼ばれる。
    ///   注意: `report.clipURL` は一時ファイル。残すならこの中でコピー/アップロードすること。
    @MainActor
    public static func start(
        configuration: FlashbackConfiguration = .init(),
        onReport: (@MainActor (FlashbackReport) -> Void)? = nil
    ) {
        FlashbackController.shared.start(configuration: configuration, onReport: onReport)
    }

    /// 録画とリスナーを停止する。
    @MainActor
    public static func stop() {
        FlashbackController.shared.stop()
    }
}
