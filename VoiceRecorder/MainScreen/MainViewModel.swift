//
//  MainViewModel.swift
//  VoiceRecorder
//
//  Created by george on 07.10.2024.
//

import SwiftUI
import PDFKit

class MainViewModel: ObservableObject {
    
    enum SoundState {
        case recording
        case playing
        case waiting
    }
    
    enum PitchValue: Float {
        case high = 700
        case `default` = 0
        case low = -700
    }
    
    @Published var soundState: SoundState = .waiting
    @Published var pitchState: PitchValue = .default
    @Published var presentWaveChart = false
    @Published var urlPdf: URL?
    
    // TODO: Try to use swinject
    private let audioManager: AudioManager
    private let pdfManager: PdfManager
    private let pdfFileName: String
    
    init() {
        self.audioManager = AudioManager()
        self.pdfManager = PdfManager(audioFileUrl: audioManager.bufferFileUrl)
        self.pdfFileName =  "RecordWaveChart.pdf"
    }
    
    func play() {
        soundState = .playing
        audioManager.play(pitchValue: pitchState.rawValue)
    }
    
    func stop() {
        audioManager.stop()
        soundState = .waiting
    }
    
    func startRecord() {
        soundState = .recording
        audioManager.startRecording()
    }
    
    func stopRecord() {
        audioManager.stopRecording()
        soundState = .waiting
    }
    
    func toggleLowPithState() {
        if pitchState == .low {
            pitchState = .default
        } else {
            pitchState = .low
        }
    }
    
    func toggleHighPitchState() {
        if pitchState == .high {
            pitchState = .default
        } else {
            pitchState = .high
        }
    }
    
    func showPdf() {
        let data = pdfManager.createDocument()
        
        urlPdf = URL.documentsDirectory.appending(path: pdfFileName)
        
        guard let urlPdf else { return }
        
        do {
            try data.write(to: urlPdf, options: [.atomic, .completeFileProtection])
        } catch {
            print(error.localizedDescription)
        }
        
        presentWaveChart = true
    }
}
