import Foundation
import os

/// FlashbackKit 共通のロガー。
///
/// `os.Logger` ベース。Console.app では `subsystem:FlashbackKit` で絞り込める。
/// Release ビルドでは `.debug` / `.info` レベルは既定で出力が抑制される。
/// 依存ゼロ方針のため、標準の `os` 以外は使わない。
enum FlashbackLog {
    /// レポート生成・送信まわり。
    static let report = Logger(subsystem: "FlashbackKit", category: "report")

    /// ライフサイクル（start / stop / トリガー）まわり。
    static let lifecycle = Logger(subsystem: "FlashbackKit", category: "lifecycle")
}
