//
//  AudioManager.swift
//  VoiceRecorder
//
//  Created by george on 07.10.2024.
//

import AVFoundation
import UIKit

final class AudioManager {
    
    enum SessionState {
        case playing
        case recording
        case `default`
    }
    
    static let bufferFileName = "bufferFile.caf"
    
    let bufferFileUrl: URL =  URL.documentsDirectory.appending(path: bufferFileName)
    
    private(set) var state: SessionState = .default
    
    private let audioSession: AVAudioSession
    private let audioRecorder: AudioQueueRecorder
    private let audioPlayer: AudioQueuePlayer
    
    init() {
        self.audioSession = AVAudioSession.sharedInstance()
        self.audioRecorder = AudioQueueRecorder(fileURL: bufferFileUrl)
        self.audioPlayer = AudioQueuePlayer(fileURL: bufferFileUrl)
    }
    
    func startRecording() {
        // MARK: - states not working
        //        guard  state != .recording else {
        //            print("Already recording")
        //            return
        //        }
        state = .recording
        
        do {
            try audioSession.setCategory(.record)
            try audioSession.setActive(
                true,
                options: [.notifyOthersOnDeactivation]
            )
            audioRecorder.startRecording()
        } catch {
            state = .default
            print(error)
        }
    }
    
    func stopRecording() {
        // MARK: - states not working
        //        guard  state == .recording else {
        //            print("Not recording")
        //            return
        //        }
        do {
            audioRecorder.stopRecording()
            try audioSession.setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
            try audioSession.setCategory(.soloAmbient)
            state = .default
        } catch {
            // add eror states?
            print(error)
        }
    }
    
    func play(pitchValue: Float? = nil) {
        // MARK: - states not working
        //        guard  state != .default else {
        //            print("Try play at not default state")
        //            return
        //        }
        state = .playing
        
        do {
            try audioSession.setCategory(.soloAmbient)
            try audioSession.setActive(
                true,
                options: [.notifyOthersOnDeactivation]
            )
            audioPlayer.startPlaying(pitchValue: pitchValue)
        } catch {
            state = .default
            print(error)
        }
    }
    
    func stop() {
        // MARK: - states not working
        //        guard  state == .playing else {
        //            print("Not playing")
        //            return
        //        }
        do {
            audioPlayer.stopPlaying()
            try audioSession.setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
            try audioSession.setCategory(.soloAmbient)
            state = .default
        } catch {
            print(error)
        }
    }
}
