import SwiftUI
import AVFoundation
import UIKit

/// A muted, seamlessly-looping video that fills its bounds (aspect-fill),
/// for class animations (ART.md §7). Pauses when the app backgrounds and
/// releases the player when it leaves the view tree, so motion never costs
/// battery or memory off-screen. Playback uses the ambient audio category so
/// it never interrupts the user's own music — these clips are silent décor.
struct LoopingVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerView { LoopingPlayerView(url: url) }
    func updateUIView(_ view: LoopingPlayerView, context: Context) { view.use(url: url) }
    static func dismantleUIView(_ view: LoopingPlayerView, coordinator: ()) { view.teardown() }
}

final class LoopingPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?   // retained — the loop stops if it deallocates
    private var url: URL?

    init(url: URL) {
        super.init(frame: .zero)
        playerLayer.videoGravity = .resizeAspectFill
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(pause),
                       name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(resume),
                       name: UIApplication.willEnterForegroundNotification, object: nil)
        use(url: url)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func use(url: URL) {
        guard url != self.url else { return }
        self.url = url
        // Mix with (don't interrupt) the user's audio; our clips are muted.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [])

        let player = AVQueuePlayer()
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        playerLayer.player = player
        self.player = player
        player.play()
    }

    @objc private func pause() { player?.pause() }
    @objc private func resume() { player?.play() }

    func teardown() {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        playerLayer.player = nil
        looper = nil
        player = nil
    }
}
