import AVFoundation
import Foundation

private final class NoiseCore {
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0

    func fill(bufferList: UnsafeMutablePointer<AudioBufferList>, frameCount: AVAudioFrameCount) -> OSStatus {
        let abl = UnsafeMutableAudioBufferListPointer(bufferList)
        let fc = Int(frameCount)
        for buffer in abl {
            let bp = buffer.mData?.assumingMemoryBound(to: Float.self)
            guard let bp else { continue }
            for i in 0 ..< fc {
                let w = Float.random(in: -1 ... 1)
                let p = pink()
                bp[i] = (w * 0.55 + p * 0.45) * 0.085
            }
        }
        return noErr
    }

    private func pink() -> Float {
        let white = Float.random(in: -1 ... 1)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        return b0 + b1 + b2 + b3 + b4 + b5 + white * 0.5362
    }
}

/// Layered radio bed: band‑limited noise plus optional HTTPS stream (public‑domain / CC sources you provide).
@MainActor
final class RadioAudioManager: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var bedVolume: Float = 0.4
    @Published var streamVolume: Float = 0.15

    /// Paste an MP3/AAC HTTPS URL (for example Internet Archive public-domain material). Leave empty for noise only.
    @Published var streamURLString: String = ""

    private var engine: AVAudioEngine?
    private let noiseCore = NoiseCore()
    private var player: AVPlayer?
    private var timeObserver: Any?

    func start() {
        guard !isRunning else { return }
        configureSession()
        startNoiseEngine()
        restartStreamIfNeeded()
        isRunning = true
    }

    func stop() {
        engine?.stop()
        engine = nil
        if let obs = timeObserver, let p = player {
            p.removeTimeObserver(obs)
        }
        timeObserver = nil
        player?.pause()
        player = nil
        isRunning = false
    }

    func applyStreamURLFromStorage(_ s: String?) {
        streamURLString = (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if isRunning { restartStreamIfNeeded() }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func startNoiseEngine() {
        let engine = AVAudioEngine()
        let main = engine.mainMixerNode
        let format = main.outputFormat(forBus: 0)

        let core = noiseCore
        let src = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            core.fill(bufferList: audioBufferList, frameCount: frameCount)
        }

        engine.attach(src)
        engine.connect(src, to: main, format: format)
        main.outputVolume = bedVolume
        engine.prepare()
        try? engine.start()
        self.engine = engine
    }

    private func restartStreamIfNeeded() {
        if let obs = timeObserver, let old = player {
            old.removeTimeObserver(obs)
        }
        timeObserver = nil
        player?.pause()
        player = nil

        let raw = streamURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let url = URL(string: raw), ["http", "https"].contains(url.scheme?.lowercased()) else { return }

        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.volume = streamVolume
        p.play()
        player = p
    }

    func updateMixLevels() {
        engine?.mainMixerNode.outputVolume = bedVolume
        player?.volume = streamVolume
    }
}
