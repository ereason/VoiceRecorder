//
//  AudioQueuePlayer.swift
//  VoiceRecorder
//
//  Created by george on 07.10.2024.
//

import AudioToolbox

class AudioQueuePlayer {
    private(set) var isPlaying = false
    
    private let fileURL: URL
    
    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?] = [nil, nil, nil]
    private var audioFile: AudioFileID?
    private var bufferSize: UInt32 = 1024
    private var currentPacket: Int64 = 0
    private var audioFormat = AudioStreamBasicDescription()
    
    private var handleAudioQueueOutput: AudioQueueOutputCallback = { inUserData, inAQ, inBuffer in
        let audioPlayer = Unmanaged<AudioQueuePlayer>.fromOpaque(inUserData!).takeUnretainedValue()
        guard let audioFile = audioPlayer.audioFile else { return }
        
        guard audioPlayer.isPlaying else { return }
        
        var ioNumBytes: UInt32 = inBuffer.pointee.mAudioDataBytesCapacity
        var ioNumPacket: UInt32 = ioNumBytes / 2
        
        guard AudioFileReadPacketData(
            audioPlayer.audioFile!,
            false,
            &ioNumBytes,
            nil,
            audioPlayer.currentPacket,
            &ioNumPacket,
            inBuffer.pointee.mAudioData ) == noErr,
              ioNumPacket != 0
        else {
            audioPlayer.stopPlaying()
            return
        }
        
        inBuffer.pointee.mAudioDataByteSize = ioNumBytes
        
        guard AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil) == noErr else {
            print("Error enqueue buffer while recording")
            return
        }
        
        audioPlayer.currentPacket += Int64(ioNumPacket)
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
}

// MARK: - Start/Stop

extension AudioQueuePlayer {
    func startPlaying(pitchValue: Float? = nil) {
        guard !isPlaying else { return }
        isPlaying = true
        
        setupAudioQueue()
        
        if let pitchValue {
            changePitch(with: pitchValue)
        }
        
        guard let audioQueue else {
            print("startPlaying. AudioQueue is nil after creation")
            return
        }
        
        guard AudioQueueStart(audioQueue, nil) == noErr else {
            print("startPlayingCan't start audio queue")
            return
        }
    }
    
    func stopPlaying() {
        guard isPlaying else { return }
        isPlaying = false
        
        guard let audioQueue else {
            print("stopPlaying. Can't stop playing AudioQueue is nil")
            return
        }
        
        guard AudioQueueStop(audioQueue, true) == noErr else {
            print("stopPlaying. Can't stop output AudioQueue")
            return
        }
        
        guard AudioQueueDispose(audioQueue, true) == noErr else {
            print("stopPlaying. Can't dispose output AudioQueue")
            return
        }
        
        self.audioQueue = nil
        
        currentPacket = 0
        audioQueueBuffers = [nil, nil, nil]
        
        guard let audioFile else {
            print("stopPlaying. Can't stop playing: AudioFile is nil")
            return
        }
        
        guard AudioFileClose(audioFile) == noErr else {
            print("stopPlaying. Can't close file while playing")
            return
        }
        
        self.audioFile = nil
    }
}

// MARK: - Setup AudioQueue

private extension AudioQueuePlayer {
    func setupAudioQueue() {
        let fileURL = self.fileURL as CFURL
        
        guard AudioFileOpenURL(fileURL, .readPermission, 0, &audioFile) == noErr else {
            print("setupAudioQueue. Can't open file while playing")
            return
        }
        
        var descSize: UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        
        guard AudioFileGetProperty(
            audioFile!,
            kAudioFilePropertyDataFormat,
            &descSize,
            &audioFormat) == noErr
        else {
            print("setupAudioQueue. Can't get audio format while playing")
            return
        }
        
        let userData = Unmanaged.passUnretained(self).toOpaque()
        
        guard AudioQueueNewOutput(
            &audioFormat,
            handleAudioQueueOutput,
            userData,
            nil,
            nil,
            0,
            &audioQueue) == noErr
        else {
            print("setupAudioQueue. Can't create audio queue output")
            return
        }
        
        guard let audioQueue else {
            print("setupAudioQueue. AudioQueue is nil after creation")
            return
        }
        
        for i in audioQueueBuffers.indices {
            guard AudioQueueAllocateBuffer(
                audioQueue,
                bufferSize,
                &audioQueueBuffers[i]) == noErr
            else {
                print("Alocate buffer(\(i)) error")
                return
            }
            
            if let buffer = audioQueueBuffers[i] {
                handleAudioQueueOutput(userData, audioQueue, buffer)
            }
        }
    }
    
    func changePitch(with value: Float) {
        guard let audioQueue else {
            print("changePitch. AudioQueue is nil")
            return
        }
        
        var enable: UInt32 = 1
        AudioQueueSetProperty(
            audioQueue,
            kAudioQueueProperty_EnableTimePitch,
            &enable,
            UInt32(MemoryLayout<UInt32>.size)
        )
        
        AudioQueueSetParameter(
            audioQueue,
            kAudioQueueParam_Pitch,
            value
        )
    }
}
