//
//  UnsafeBufferPointer+Extension.swift
//  VoiceRecorderApp
//
//  Created by george on 07.11.2024.
//

extension UnsafeBufferPointer {
    func item(at index: Int) -> Element? {
        if index >= self.count {
            return nil
        }
        
        return self[index]
    }
}
