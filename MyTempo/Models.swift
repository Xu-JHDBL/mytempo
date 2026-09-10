//
//  Models.swift
//  MyTempo
//
//  节拍器的数据模型：拍号、音色。
//

import Foundation

/// 拍号（节拍型）。
/// - `beatsPerMeasure`：分子，每小节的拍数；
/// - `noteValue`：分母，一拍对应的音符时值（4 = 四分音符，8 = 八分音符）。
/// 例如 6/8 表示每小节 6 个八分音符，节拍器在 6 个点上打拍，第一拍是重音。
struct TimeSignature: Identifiable, Hashable {
    let beatsPerMeasure: Int
    let noteValue: Int

    var id: String { "\(beatsPerMeasure)/\(noteValue)" }
    var label: String { "\(beatsPerMeasure)/\(noteValue)" }

    /// 常用拍号预设
    static let presets: [TimeSignature] = [
        TimeSignature(beatsPerMeasure: 2, noteValue: 4),
        TimeSignature(beatsPerMeasure: 3, noteValue: 4),
        TimeSignature(beatsPerMeasure: 4, noteValue: 4),
        TimeSignature(beatsPerMeasure: 5, noteValue: 4),
        TimeSignature(beatsPerMeasure: 6, noteValue: 8),
        TimeSignature(beatsPerMeasure: 7, noteValue: 8),
        TimeSignature(beatsPerMeasure: 9, noteValue: 8),
        TimeSignature(beatsPerMeasure: 12, noteValue: 8),
    ]
}

/// 音色。每种音色内部都包含「重音」和「普通拍」两种声音（在引擎里合成）。
enum SoundType: String, CaseIterable, Identifiable {
    case classic   = "经典"
    case woodblock = "木鱼"
    case beep      = "电子"
    case hihat     = "踩镲"

    var id: String { rawValue }
}
