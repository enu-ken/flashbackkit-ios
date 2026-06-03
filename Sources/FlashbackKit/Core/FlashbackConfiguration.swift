import Foundation

public struct FlashbackConfiguration: Sendable {
    /// リングバッファに保持する直前秒数。既定 20（設定画面の選択肢 10/20/30/60 と整合）。
    public var bufferSeconds: TimeInterval

    /// 有効フラグ。Release ビルドでは原則 false 運用を想定。
    public var isEnabled: Bool

    /// レポート UI を起動するトリガ手段の集合（`OptionSet`、複数同時有効）。
    /// 既定は手持ち=シェイク / 据え置き=フローティングボタン の両対応。
    /// 環境に応じて `.init(triggers: [.shake])` のように絞れる。
    public var triggers: FlashbackTrigger

    /// `.floatingButton` の初期表示位置（四隅）。既定は右下。
    /// 表示後は QA がドラッグで動かせる。
    public var floatingButtonCorner: FloatingButtonCorner

    /// アプリ起動時に画面収録の許可を確認する（＝起動直後に `startCapture`）か。
    /// **既定は false**：起動時に OS 許可ダイアログを出さず、ユーザが「録画をオンにする」
    /// （→ プライミング）で能動的に開始する。設定トグルで opt-in でき、選択は永続化される
    /// （永続値が無い初回のみ本既定値を採用）。
    public var promptOnLaunch: Bool

    /// シミュレータ上で起動するか。**既定は false**：シミュレータは ReplayKit 実録画が
    /// 物理的に不可なので、`Flashback.start()` を何もしない（FAB・トリガ・オーバーレイを置かない）。
    /// 開発者がシム上で別アプリを開発・新規シムを多用する際に、使えない FAB が常駐したり
    /// オンボーディングが走ったりする煩わしさを避けるため。
    /// SDK 自体の UI をシムで確認したい場合のみ true にする（Example アプリは true）。
    /// 実機ビルドには影響しない（このフラグは `targetEnvironment(simulator)` 時のみ参照）。
    public var runsOnSimulator: Bool

    public init(
        bufferSeconds: TimeInterval = 20,
        isEnabled: Bool = true,
        triggers: FlashbackTrigger = .default,
        floatingButtonCorner: FloatingButtonCorner = .bottomTrailing,
        promptOnLaunch: Bool = false,
        runsOnSimulator: Bool = false
    ) {
        self.bufferSeconds = bufferSeconds
        self.isEnabled = isEnabled
        self.triggers = triggers
        self.floatingButtonCorner = floatingButtonCorner
        self.promptOnLaunch = promptOnLaunch
        self.runsOnSimulator = runsOnSimulator
    }
}

/// フローティングボタンの初期表示位置（四隅）。
public enum FloatingButtonCorner: Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}
