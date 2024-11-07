//
//  ImageButton.swift
//  VoiceRecorder
//
//  Created by george on 07.11.2024.
//

import SwiftUI

struct ImageButton: View {
    var imageName: String

    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.white)
    }
}
