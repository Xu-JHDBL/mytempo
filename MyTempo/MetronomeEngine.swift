//
//  MetronomeEngine.swift
//  MyTempo
//
//  节拍器核心：用 AVAudioEngine + AVAudioSourceNode 实现「采样级」精确打拍。
//
//  为什么不用 Timer 计时？
//  - Timer 由系统调度，会抖动、漂移，快节奏下每个 tick 可能差几毫秒，练习时跟不上。
//  - 音频渲染回调每次处理一块采样（如 512 个），我们在这里按「采样点」计数，
//    每个采样点是 1/44100 秒，天然精确，且和声音输出完全同步。
//  （注意：这里说的「不用 Timer」指的是「计时发声」；下方视觉灯珠用的是一个
//   60Hz 的 Timer，只负责把音频线程的拍点同步到 UI，轻微抖动不影响观感。）
//

import Foundation
import AVFoundation
import AudioToolbox
import Combine

final class MetronomeEngine: ObservableObject {

    // MARK: - 可调参数（UI 直接绑定）
    @Published var tempo: Double = 120.0
    @Published var timeSignature: TimeSignature = TimeSignature(beatsPerMeasure: 4, noteValue: 4)
    @Published var sound: SoundType = .classic {
        didSet { rebuildClicks() }
    }
    @Published var accentEnabled: Bool = true
    @Published var volume: Double = 0.8

    // MARK: - 运行状态（只读，UI 观察）
    @Published private(set) var isPlaying = false
    /// 当前小节内的第几拍（0 开始，0 = 重音拍）
    @Published private(set) var currentBeat = 0
    /// 每次打拍 +1，用来触发 UI 闪烁动画
    @Published private(set) var beatPulse = 0

    // MARK: - 音频
    private let engine = AVAudioEngine()
    private let sourceNode: AVAudioSourceNode
    private let sampleRate: Double = 44100.0
    private let lock = NSLock()

    // 合成好的节拍波形（重音 / 普通拍）
    private var accentWave: [Float] = []
    private var beatWave: [Float] = []

    // 以下变量只在音频渲染线程访问
    private var currentSample: Double = 0
    private var nextBeatSample: Double = 0
    private var internalBeat = 0

    private struct Voice {
        var position = 0
        let wave: [Float]
    }
    private var voices: [Voice] = []

    // 打拍计数：渲染线程写入，主线程读取（用于视觉同步）
    private var beatCounter: Int64 = 0
    private var timer: Timer?
    private var lastSeenCounter: Int64 = -1

    // 打拍定速（tap tempo）
    private var lastTapTime: Date?
    private var tapIntervals: [Double] = []

    // MARK: - 初始化
    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        sourceNode = AVAudioSourceNode(format: format) { [weak self] isSilence, _, frameCount, outputData -> OSStatus in
            guard let self = self else {
                isSilence.pointee = true
                return noErr
            }
            self.render(frameCount: Int(frameCount), outputData: outputData)
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        rebuildClicks()
        startTimer()
    }

    // MARK: - 控制
    func start() {
        guard !isPlaying else { return }
        configureSessionIfNeeded()
        if !engine.isRunning {
            try? engine.start()
        }
        lock.lock()
        isPlaying = true
        lock.unlock()
        currentBeat = 0
        beatPulse += 1
    }

    func stop() {
        lock.lock()
        isPlaying = false
        lock.unlock()
        currentBeat = 0
    }

    /// 打拍定速：根据两次点击的时间间隔估算 BPM。
    func tap() {
        let now = Date()
        defer { lastTapTime = now }
        guard let last = lastTapTime else { return }
        let interval = now.timeIntervalSince(last)
        guard interval > 0.2, interval < 2.0 else { return } // 忽略误触 / 间隔过久
        tapIntervals.append(60.0 / interval)
        if tapIntervals.count > 4 { tapIntervals.removeFirst() }
        let avg = tapIntervals.reduce(0, +) / Double(tapIntervals.count)
        tempo = min(max(avg.rounded(), 40), 240)
    }

    // MARK: - 渲染回调（音频线程）
    private func render(frameCount: Int, outputData: UnsafeMutablePointer<AudioBufferList>) {
        // 拷贝参数（短临界区，避免在音频线程长时间持锁）
        lock.lock()
        let playing = isPlaying
        let samplesPerBeat = sampleRate * 60.0 / max(tempo, 20)
        let beats = max(timeSignature.beatsPerMeasure, 1)
        let accentOn = accentEnabled
        let vol = Float(volume)
        let accent = accentWave
        let beat = beatWave
        lock.unlock()

        let abl = UnsafeMutableAudioBufferListPointer(outputData)
        guard let buffer = abl.first, let raw = buffer.mData else { return }
        let out = raw.assumingMemoryBound(to: Float.self)
        let frames = min(frameCount, Int(buffer.mDataByteSize) / MemoryLayout<Float>.size)

        // 停止状态：输出静音，并把内部计时复位，好让下次从头开始
        guard playing else {
            for i in 0..<frames { out[i] = 0 }
            currentSample = 0
            nextBeatSample = 0
            internalBeat = 0
            voices.removeAll(keepingCapacity: true)
            return
        }

        for i in 0..<frames {
            // 到拍点了 -> 触发一次敲击
            while currentSample >= nextBeatSample {
                let isAccent = (internalBeat == 0) && accentOn
                voices.append(Voice(position: 0, wave: isAccent ? accent : beat))
                internalBeat = (internalBeat + 1) % beats
                nextBeatSample += samplesPerBeat
                lock.lock(); beatCounter += 1; lock.unlock()
            }
            currentSample += 1

            // 混合所有正在发声的敲击（敲击很短，最多同时 2~3 个）
            var sample: Float = 0
            var j = 0
            while j < voices.count {
                if voices[j].position < voices[j].wave.count {
                    sample += voices[j].wave[voices[j].position]
                    voices[j].position += 1
                    j += 1
                } else {
                    voices.remove(at: j)
                }
            }
            out[i] = sample * vol
        }
    }

    // MARK: - 视觉同步（主线程，60Hz，只负责把拍点刷到 UI）
    private func startTimer() {
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.displayTick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func displayTick() {
        lock.lock(); let c = beatCounter; lock.unlock()
        guard c != lastSeenCounter else { return }
        lastSeenCounter = c
        currentBeat = Int(c % Int64(max(timeSignature.beatsPerMeasure, 1)))
        beatPulse += 1
    }

    // MARK: - 声音合成
    private func rebuildClicks() {
        let (accent, beat) = Self.makeClicks(for: sound, sampleRate: sampleRate)
        lock.lock()
        accentWave = accent
        beatWave = beat
        lock.unlock()
    }

    /// 合成带衰减的「敲击」音：基频正弦 + 少量二次谐波 + 指数衰减包络。
    private static func makeClick(frequency: Double,
                                  harmonic: Double,
                                  duration: Double,
                                  decay: Double,
                                  sampleRate: Double) -> [Float] {
        let n = Int(duration * sampleRate)
        var wave = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / sampleRate
            let env = exp(-t / decay)
            let v = (sin(2 * .pi * frequency * t) + harmonic * sin(2 * .pi * frequency * 2 * t)) * env
            wave[i] = Float(v * 0.85)
        }
        return wave
    }

    /// 白噪声 + 衰减包络，用于「踩镲」这类音色。
    private static func makeNoiseBurst(duration: Double,
                                       decay: Double,
                                       gain: Double,
                                       sampleRate: Double) -> [Float] {
        let n = Int(duration * sampleRate)
        var wave = [Float](repeating: 0, count: n)
        var seed: UInt64 = 0x9E3779B97F4A7C15
        for i in 0..<n {
            seed ^= seed << 13
            seed ^= seed >> 7
            seed ^= seed << 17
            let r = Double(seed % 20001) / 10000.0 - 1.0
            let t = Double(i) / sampleRate
            wave[i] = Float(r * exp(-t / decay) * gain)
        }
        return wave
    }

    private static func makeClicks(for sound: SoundType, sampleRate: Double) -> (accent: [Float], beat: [Float]) {
        switch sound {
        case .classic:
            return (makeClick(frequency: 1200, harmonic: 0.3, duration: 0.03, decay: 0.006, sampleRate: sampleRate),
                    makeClick(frequency: 800,  harmonic: 0.3, duration: 0.03, decay: 0.006, sampleRate: sampleRate))
        case .woodblock:
            return (makeClick(frequency: 880, harmonic: 0.9, duration: 0.05, decay: 0.012, sampleRate: sampleRate),
                    makeClick(frequency: 620, harmonic: 0.9, duration: 0.05, decay: 0.012, sampleRate: sampleRate))
        case .beep:
            return (makeClick(frequency: 2093, harmonic: 0.0, duration: 0.07, decay: 0.02, sampleRate: sampleRate),
                    makeClick(frequency: 1568, harmonic: 0.0, duration: 0.07, decay: 0.02, sampleRate: sampleRate))
        case .hihat:
            return (makeNoiseBurst(duration: 0.05, decay: 0.008, gain: 0.9, sampleRate: sampleRate),
                    makeNoiseBurst(duration: 0.05, decay: 0.012, gain: 0.6, sampleRate: sampleRate))
        }
    }

    // MARK: - 音频会话
    private func configureSessionIfNeeded() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // .mixWithOthers：练习时允许后台音乐/伴奏继续播放，若想独占可去掉这个 option
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    deinit {
        timer?.invalidate()
        engine.stop()
    }
}
