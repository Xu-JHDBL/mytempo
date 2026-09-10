//
//  ContentView.swift
//  MyTempo
//

import SwiftUI

struct ContentView: View {
    @StateObject private var metronome = MetronomeEngine()

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                beatIndicator
                tempoControl
                timeSignaturePicker
                soundPicker
                options
                playButton
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("节拍器")
        }
        .tint(.orange)
    }

    // MARK: - 视觉节拍指示（重音拍高亮，当前拍放大闪烁）
    private var beatIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<metronome.timeSignature.beatsPerMeasure, id: \.self) { i in
                let isCurrent = metronome.isPlaying && metronome.currentBeat == i
                let isDownbeat = i == 0
                Circle()
                    .fill(isCurrent ? Color.orange : Color.gray.opacity(0.25))
                    .overlay(
                        Circle()
                            .stroke(isDownbeat ? Color.orange.opacity(0.8) : .clear, lineWidth: 1.5)
                    )
                    .frame(width: 24, height: 24)
                    .scaleEffect(isCurrent ? 1.4 : 1.0)
                    .animation(.spring(response: 0.1, dampingFraction: 0.45), value: metronome.beatPulse)
            }
        }
        .frame(height: 48)
    }

    // MARK: - 速度
    private var tempoControl: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(metronome.tempo))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("BPM")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Slider(value: $metronome.tempo, in: 40.0...240.0, step: 1.0)

            HStack {
                stepperButton(symbol: "minus", action: { metronome.tempo = max(40, metronome.tempo - 1) })
                Spacer()
                Button("打拍定速") { metronome.tap() }
                    .font(.headline)
                Spacer()
                stepperButton(symbol: "plus", action: { metronome.tempo = min(240, metronome.tempo + 1) })
            }
        }
    }

    // MARK: - 节拍型
    private var timeSignaturePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("节拍型")
                .font(.subheadline)
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TimeSignature.presets) { ts in
                        Button {
                            metronome.timeSignature = ts
                        } label: {
                            Text(ts.label)
                                .font(.title3.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule().fill(
                                        metronome.timeSignature == ts
                                            ? Color.orange
                                            : Color.gray.opacity(0.15)
                                    )
                                )
                                .foregroundColor(metronome.timeSignature == ts ? .white : .primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 音效
    private var soundPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("音效")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("音效", selection: $metronome.sound) {
                ForEach(SoundType.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - 其它选项（重音开关 + 音量）
    private var options: some View {
        VStack(spacing: 16) {
            Toggle("重音（第一拍）", isOn: $metronome.accentEnabled)
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                Slider(value: $metronome.volume, in: 0.0...1.0)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 播放/停止
    private var playButton: some View {
        Button {
            if metronome.isPlaying {
                metronome.stop()
            } else {
                metronome.start()
            }
        } label: {
            Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 88, height: 88)
                .background(Circle().fill(Color.orange))
        }
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.gray.opacity(0.15)))
        }
    }
}
