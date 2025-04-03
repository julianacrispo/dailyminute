import Foundation
import Speech
import SwiftUI
import Accelerate
import NaturalLanguage
import AVFoundation

@Observable class JournalViewModel: ObservableObject {
    var journalEntries: [JournalEntry] = []
    var currentText: String = ""
    var isRecording: Bool = false
    var timeRemaining: Double = 60.0
    var transcriptionInProgress: Bool = false
    var entrySaved: Bool = false
    var audioLevel: Double = 0.0
    var activeTranscriptionMode: TranscriptionMode?
    
    // Audio recording properties
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    
    // Navigation state properties
    var selectedEntry: JournalEntry? = nil
    var selectedDay: Date? = nil
    
    enum TranscriptionMode {
        case recording    // For new recordings
        case editing(String)  // For editing existing text, with initial text
    }
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?
    private var audioLevelTimer: Timer?
    private var textUpdateHandler: ((String) -> Void)?
    
    init() {
        setupSpeechRecognition()
    }
    
    private func setupSpeechRecognition() {
        // Initialize speech recognizer with specific configuration
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.defaultTaskHint = .dictation
        
        // Pre-warm audio engine
        audioEngine = AVAudioEngine()
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func requestSpeechAuthorization() {
        guard speechRecognizer?.isAvailable == true else {
            print("Speech recognition not available")
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self?.setupSpeechRecognition()
                }
            }
        }
    }
    
    // Set up an audio recorder
    private func setupAudioRecorder() -> Bool {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        currentRecordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            return true
        } catch {
            print("Could not set up audio recorder: \(error.localizedDescription)")
            return false
        }
    }
    
    // Get the documents directory
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func startTranscription(mode: TranscriptionMode, updateText: @escaping (String) -> Void) {
        guard !isRecording,
              let audioEngine = audioEngine,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else { return }
        
        // Store the update handler
        textUpdateHandler = updateText
        
        // Set initial state based on mode
        switch mode {
        case .recording:
            timeRemaining = 60.0
            currentText = ""
            
            // Start audio recording if we're in recording mode
            if setupAudioRecorder() {
                audioRecorder?.record()
            }
            
        case .editing(let initialText):
            currentText = initialText
            timeRemaining = 300.0  // 5 minutes for editing
            
            // We don't record audio when editing existing text
            currentRecordingURL = nil
        }
        
        activeTranscriptionMode = mode
        
        // Configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        recognitionRequest.contextualStrings = ["minute", "record", "today", "think"]
        recognitionRequest.addsPunctuation = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioLevel(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.currentText = transcription
                    self.textUpdateHandler?(transcription)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscription()
            }
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            startTimer()
        } catch {
            print("Audio engine failed to start: \(error)")
            stopTranscription()
        }
    }
    
    private func processAudioLevel(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength
        
        // Use vDSP for faster audio processing
        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(frames))
        rms = sqrt(rms)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // More sensitive threshold for voice detection
            let threshold: Float = 0.008
            
            // Apply more nuanced normalization to better distinguish volume levels
            // Use a lower multiplier to prevent hitting max level too easily
            let normalizedLevel = rms * 15
            
            if normalizedLevel < threshold {
                // Decay quickly to zero when silent
                self.audioLevel = max(0, self.audioLevel - 0.15)
            } else {
                // Map the audio level with more nuance
                // Map different ranges of input to different slopes of output
                let targetLevel: Double
                
                // Very soft sounds
                if normalizedLevel < 0.05 {
                    targetLevel = Double(normalizedLevel) * 3.0 // Gentle slope for quiet sounds
                }
                // Medium sounds
                else if normalizedLevel < 0.2 {
                    targetLevel = 0.15 + Double(normalizedLevel - 0.05) * 2.0 // Medium slope
                }
                // Loud sounds - make these harder to reach max
                else {
                    targetLevel = 0.45 + Double(normalizedLevel - 0.2) * 0.8 // Flatten curve at top end
                }
                
                // Cap at 1.0 and apply smoothing for natural transitions
                let cappedTarget = min(1.0, targetLevel)
                
                // Use more responsive smoothing for rising levels but keep smooth transitions
                let riseFactor = cappedTarget > self.audioLevel ? 0.4 : 0.3
                self.audioLevel = self.audioLevel * (1 - riseFactor) + cappedTarget * riseFactor
            }
        }
    }
    
    func stopTranscription() {
        // Prevent multiple calls
        guard isRecording else { return }
        
        // Stop audio engine and clean up
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Clean up recognition task
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        // Stop audio recording if we were recording
        if let recorder = audioRecorder, recorder.isRecording {
            recorder.stop()
        }
        
        isRecording = false
        stopTimer()
        audioLevel = 0.0
        
        // Handle completion based on mode
        if case .recording = activeTranscriptionMode {
            handleRecordingCompletion()
        }
        
        activeTranscriptionMode = nil
        textUpdateHandler = nil
    }
    
    private func handleRecordingCompletion() {
        // Skip saving if there's no text
        guard !currentText.isEmpty else {
            // Clean up audio recording if nothing to save
            if let url = currentRecordingURL {
                try? FileManager.default.removeItem(at: url)
            }
            currentRecordingURL = nil
            return
        }
        
        let textToSave = currentText
        let audioURL = currentRecordingURL
        currentText = ""
        currentRecordingURL = nil
        
        transcriptionInProgress = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Save entry with audio URL if available
            let newEntry = JournalEntry(text: textToSave, audioURL: audioURL)
            self.journalEntries.append(newEntry)
            
            // Update UI state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transcriptionInProgress = false
                self.entrySaved = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.entrySaved = false
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.timeRemaining -= 0.1
            if self.timeRemaining <= 0 {
                self.stopTranscription()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateEntry(id: UUID, newText: String) {
        if let index = journalEntries.firstIndex(where: { $0.id == id }) {
            // Create a new entry with updated text but same ID, date and audio URL
            var updatedEntry = journalEntries[index]
            updatedEntry.text = newText
            
            // Replace the old entry with the updated one
            journalEntries[index] = updatedEntry
        }
    }
} 
