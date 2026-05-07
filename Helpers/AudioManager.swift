import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var engine = AVAudioEngine()
    private var tonePlayer: AVAudioPlayerNode?
    private var bgPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func playBeesAmbience() {
        playFile("beesloop")
    }
    
    func playWindAmbience() {
        // non usato per ora
    }
    
    func playHoneyCollect() {
        playEffect("honeycollect")
    }
    
    func playEventAlert() {
        playEffect("eventalert")
    }
    
    func stopBackground() {
        bgPlayer?.stop()
    }
    
    func fadeOut(duration: Double = 1.5) {
        bgPlayer?.stop()
    }
    
    private var loopPlayer: AVAudioPlayer?
    private var effectPlayer: AVAudioPlayer?
    
    private func playFile(_ name: String) {
        let extensions = ["m4a", "mp3", "caf", "wav"]
        var url: URL? = nil
        
        for ext in extensions {
            if let found = Bundle.main.url(forResource: name, withExtension: ext) {
                url = found
                break
            }
        }
        
        guard let url else { return }
        
        do {
            loopPlayer = try AVAudioPlayer(contentsOf: url)
            loopPlayer?.numberOfLoops = -1
            loopPlayer?.volume = 0.5
            loopPlayer?.prepareToPlay()
            loopPlayer?.play()
        } catch {
            print("❌ Errore: \(error.localizedDescription)")
        }
    }
    
    private func playEffect(_ name: String) {
        let extensions = ["m4a", "mp3", "caf", "wav"]
        var url: URL? = nil
        
        for ext in extensions {
            if let found = Bundle.main.url(forResource: name, withExtension: ext) {
                url = found
                break
            }
        }
        
        guard let url else { return }
        
        do {
            effectPlayer = try AVAudioPlayer(contentsOf: url)
            effectPlayer?.numberOfLoops = 0
            effectPlayer?.volume = 0.8
            effectPlayer?.prepareToPlay()
            effectPlayer?.play()
        } catch {
            print("❌ Errore effetto: \(error.localizedDescription)")
        }
    }
}
