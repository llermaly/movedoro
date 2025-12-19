import Foundation
import AVFoundation

// MARK: - TTS Service Protocol

/// Protocol for text-to-speech services
protocol TTSService: AnyObject {
    /// Whether the service is currently speaking
    var isSpeaking: Bool { get }

    /// Speak text immediately, stopping any current speech
    func speak(_ text: String)

    /// Queue text to be spoken after current speech finishes
    func speakAfterCurrent(_ text: String, checkInterval: TimeInterval)

    /// Stop any current speech
    func stopSpeaking()
}

extension TTSService {
    func speakAfterCurrent(_ text: String) {
        speakAfterCurrent(text, checkInterval: 0.2)
    }
}

// MARK: - Native TTS Service

/// TTS service using AVSpeechSynthesizer
final class NativeTTSService: NSObject, TTSService, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    /// The selected voice for speech synthesis
    private var selectedVoice: AVSpeechSynthesisVoice?

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    override init() {
        super.init()
        synthesizer.delegate = self

        // Find an enhanced English voice
        selectedVoice = findBestVoice()

        if let voice = selectedVoice {
            print("TTS using voice: \(voice.name) (\(voice.language))")
        }
    }

    /// Find the best available voice
    private func findBestVoice() -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // Look for enhanced English voices first
        let englishVoices = allVoices.filter { $0.language.hasPrefix("en") }

        // Prefer enhanced quality
        if let enhanced = englishVoices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }

        // Fall back to any English voice
        if let english = englishVoices.first {
            return english
        }

        // Last resort
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("TTS: Started")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("TTS: Finished")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("TTS: Cancelled")
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func speakAfterCurrent(_ text: String, checkInterval: TimeInterval = 0.2) {
        if synthesizer.isSpeaking {
            DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) { [weak self] in
                self?.speakAfterCurrent(text, checkInterval: checkInterval)
            }
        } else {
            speak(text)
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Set voice by identifier
    func setVoice(_ voice: AVSpeechSynthesisVoice) {
        selectedVoice = voice
        print("TTS voice changed to: \(voice.name) (\(voice.language))")
    }

    /// Get premium and enhanced voices only
    static func getPremiumVoices() -> [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        return allVoices.filter { voice in
            voice.quality == .premium || voice.quality == .enhanced
        }.sorted { $0.language < $1.language }
    }

    /// Get English premium/enhanced voices
    static func getEnglishPremiumVoices() -> [AVSpeechSynthesisVoice] {
        return getPremiumVoices().filter { $0.language.hasPrefix("en") }
    }

    /// Print available premium voices to console
    static func printPremiumVoices() {
        let voices = getPremiumVoices()
        print("=== Premium/Enhanced TTS Voices ===")
        for voice in voices {
            let quality = voice.quality == .premium ? "Premium" : "Enhanced"
            print("  [\(quality)] \(voice.name) - \(voice.language)")
        }
        print("Total: \(voices.count) voices")
        print("===================================")
    }
}

