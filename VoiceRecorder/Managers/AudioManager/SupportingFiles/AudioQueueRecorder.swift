//
//  AudioQueueRecorder.swift
//  VoiceRecorder
//
//  Created by george on 07.10.2024.
//

import CoreAudio
import AudioToolbox

class AudioQueueRecorder {
    private let fileURL: URL
    private var audioQueue: AudioQueueRef?
    private var audioQueueBuffers: [AudioQueueBufferRef?] = [nil, nil, nil]
    private var audioFile: AudioFileID?
    private var writePtr: Int64 = 0
    private let bufferSize: UInt32 = 1024
    
    private var audioFormat = AudioStreamBasicDescription(
        mSampleRate: 44100.0,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
        mBytesPerPacket: 2,
        mFramesPerPacket: 1,
        mBytesPerFrame: 2,
        mChannelsPerFrame: 1,
        mBitsPerChannel: 16,
        mReserved: 0
    )
    
    var handleAudioQueueInput: AudioQueueInputCallback = { inUserData, inAQ, inBuffer, inStartTime, inNumPackets, inPacketDesc in
        guard let inUserData else { return }
        
        let audioRecorder = Unmanaged<AudioQueueRecorder>.fromOpaque(inUserData).takeUnretainedValue()
        
        guard let audioFile = audioRecorder.audioFile else { return }
        
        var ioNumBytes = inBuffer.pointee.mAudioDataBytesCapacity
        
        guard AudioFileWriteBytes(
            audioFile,
            false,
            audioRecorder.writePtr,
            &ioNumBytes,
            inBuffer.pointee.mAudioData) == noErr
        else {
            print("Error writing filr bytes")
            return
        }
        
        audioRecorder.writePtr += Int64(ioNumBytes)
        
        guard AudioQueueEnqueueBuffer(
            inAQ,
            inBuffer,
            0,
            nil) == noErr
        else {
            print("Error enqueue buffer while recording")
            return
        }
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
        print(fileURL)
    }
}

// MARK: - Start/Stop

extension AudioQueueRecorder {
    func startRecording() {
        guard
            setupAudioQueue(),
            let audioQueue,
            AudioQueueStart(audioQueue, nil) == noErr
        else {
            clear()
            return
        }
    }
    
    func stopRecording() {
        guard let audioQueue else { return }
        
        var timeLine: AudioQueueTimelineRef?
        if AudioQueueCreateTimeline(audioQueue, &timeLine) == noErr {
            var timeStamp = AudioTimeStamp()
            AudioQueueGetCurrentTime(audioQueue, timeLine, &timeStamp, nil);
        }
        
        guard AudioQueueStop(audioQueue, true) == noErr else {
            print("Can't stop input AudioQueue")
            return
        }
        
        guard AudioQueueDispose(audioQueue, true) == noErr else {
            print("Can't dispose input AudioQueue")
            return
        }
        
        guard let audioFile else {
            print("Can't stop recording: AudioFile is nil")
            return
        }
        
        guard AudioFileClose(audioFile) == noErr else {
            print("Can't close file while recording")
            return
        }
        
        clear()
    }
}

// MARK: - Setup AudioQueue

private extension AudioQueueRecorder {
    func setupAudioQueue() -> Bool {
        guard createAudioFile(fileUrl: fileURL as CFURL) else {
            print("Can't create audio file")
            return false
        }
        
        guard createAudioQueueInput() else {
            print("Can't create audio queue input")
            return false
        }
        
        guard
            let audioQueue,
            setupQueueBuffers(audioQueue:audioQueue)
        else {
            print("Can't setup buffers")
            return false
        }
        
        return true
    }
    
    func createAudioFile(fileUrl: CFURL) -> Bool {
        AudioFileCreateWithURL(
            fileUrl,
            kAudioFileCAFType,
            &audioFormat,
            .eraseFile,
            &audioFile
        ) == noErr
    }
    
    func createAudioQueueInput() -> Bool {
        AudioQueueNewInput(
            &audioFormat,
            handleAudioQueueInput,
            Unmanaged.passUnretained(self).toOpaque(),
            nil,
            nil,
            0,
            &audioQueue
        ) == noErr
    }
    
    func setupQueueBuffers(audioQueue: AudioQueueRef) -> Bool {
        for i in audioQueueBuffers.indices {
            guard AudioQueueAllocateBuffer(
                audioQueue,
                bufferSize,
                &audioQueueBuffers[i]) == noErr
            else {
                print("Alocate buffer(\(i)) error")
                return false
            }
            
            guard let buffer = audioQueueBuffers[i] else {
                print("Buffer(\(i)) not allocated but after allocation")
                return false
            }
            
            guard AudioQueueEnqueueBuffer(audioQueue, buffer, 0, nil) == noErr else {
                print("Enqueue buffer(\(i)) error")
                return false
            }
        }
        
        return true
    }
    
    func clear() {
        audioQueue = nil
        audioFile = nil
        writePtr = 0
        audioQueueBuffers = [nil, nil, nil]
    }
}
