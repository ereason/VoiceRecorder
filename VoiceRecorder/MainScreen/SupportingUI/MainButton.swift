//
//  MainButton.swift
//  VoiceRecorder
//
//  Created by george on 07.10.2024.
//

import SwiftUI

struct MainButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(20)
            .background(Color.blue)
            .clipShape(Circle())
    }
}
