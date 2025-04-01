import Foundation
import Speech
import SwiftUI
import Accelerate

@Observable class JournalViewModel: ObservableObject {
    var journalEntries: [JournalEntry] = []
    var currentText: String = ""
    var isRecording: Bool = false
    var timeRemaining: Double = 60.0
    var transcriptionInProgress: Bool = false
    var entrySaved: Bool = false
    var audioLevel: Double = 0.0
    var activeTranscriptionMode: TranscriptionMode?
    
    // Navigation state properties with debug prints
    var selectedEntry: JournalEntry? = nil {
        didSet {
            print("DEBUG: JournalViewModel.selectedEntry changed to: \(String(describing: selectedEntry?.id))")
        }
    }
    
    var selectedDay: Date? = nil {
        didSet {
            print("DEBUG: JournalViewModel.selectedDay changed to: \(String(describing: selectedDay))")
        }
    }
    
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
        debugPrintAllEntries()
    }
    
    private func setupSpeechRecognition() {
        // Initialize speech recognizer with specific configuration
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.defaultTaskHint = .dictation
        
        // Pre-warm audio engine
        audioEngine = AVAudioEngine()
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
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
        case .editing(let initialText):
            currentText = initialText
            timeRemaining = 300.0  // 5 minutes for editing
        }
        
        activeTranscriptionMode = mode
        
        // Configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        recognitionRequest.contextualStrings = ["minute", "record", "today", "think"]
        
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
            let threshold: Float = 0.01
            let normalizedLevel = rms * 15
            
            if normalizedLevel < threshold {
                self.audioLevel = max(0, self.audioLevel - 0.3)
            } else {
                self.audioLevel = Double(min(max(normalizedLevel, 0), 1))
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
        guard !currentText.isEmpty else { return }
        
        let textToSave = currentText
        currentText = ""
        
        transcriptionInProgress = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Save entry
            let newEntry = JournalEntry(text: textToSave)
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
            // Create a new entry with updated text but same ID and date
            var updatedEntry = journalEntries[index]
            updatedEntry.text = newText
            
            // Replace the old entry with the updated one
            journalEntries[index] = updatedEntry
        }
    }
    
    func debugPrintAllEntries() {
        print("DEBUG: ===== All Journal Entries =====")
        if journalEntries.isEmpty {
            print("DEBUG: No journal entries found")
            createTestEntries() // Add test entries if none exist
        } else {
            for (index, entry) in journalEntries.enumerated() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                print("DEBUG: Entry \(index + 1): ID=\(entry.id), Date=\(dateFormatter.string(from: entry.date)), TextLength=\(entry.text.count)")
            }
        }
        print("DEBUG: ===============================")
    }
    
    // Temporary function to create test entries
    private func createTestEntries() {
        print("DEBUG: Creating test entries for today")
        
        // Create entries for today
        let now = Date()
        journalEntries.append(JournalEntry(text: "Test entry 1 for today", date: now))
        
        // Create a second entry for today a few hours earlier
        if let earlierToday = Calendar.current.date(byAdding: .hour, value: -3, to: now) {
            journalEntries.append(JournalEntry(text: "Test entry 2 for today (earlier)", date: earlierToday))
        }
        
        print("DEBUG: Created \(journalEntries.count) test entries")
    }
} 
