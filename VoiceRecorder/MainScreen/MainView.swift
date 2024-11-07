//
//  ContentView.swift
//  VoiceRecorder
//
//  Created by george on 06.10.2024.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel = MainViewModel()
    
    var body: some View {
        VStack(spacing: 10) {
            VStack {
                
                if viewModel.soundState != .recording {
                    switch viewModel.pitchState {
                    case .high:
                        Text("Pitch high")
                    case .default:
                        Text("Pitch default")
                    case .low:
                        Text("Pitch low")
                    }
                }
                
                HStack() {
                    if viewModel.soundState == .waiting {
                        Button {
                            viewModel.toggleLowPithState()
                        } label: {
                            ImageButton(imageName: "waveform.path.badge.minus")
                        }
                        .buttonStyle(MainButton())
                        
                        Button {
                            viewModel.play()
                        } label: {
                            ImageButton(imageName: "play.circle.fill")
                        }
                        .buttonStyle(MainButton())
                        
                        Button {
                            viewModel.toggleHighPitchState()
                        } label: {
                            ImageButton(imageName:"waveform.path.badge.plus")
                        }
                        .buttonStyle(MainButton())
                    }
                    
                    if viewModel.soundState == .playing {
                        Button {
                            viewModel.stop()
                        } label: {
                            ImageButton(imageName: "pause.circle.fill")
                        }.buttonStyle(
                            MainButton()
                        )
                    }
                }
                
            }.frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            
            Group {
                
                if viewModel.soundState == .waiting {
                    Button {
                        viewModel.startRecord()
                    } label: {
                        Image(systemName: "microphone.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.green)
                    }
                    .background(.blue)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                }
                
                if viewModel.soundState == .recording {
                    Button {
                        viewModel.stopRecord()
                    } label: {
                        ImageButton(imageName: "microphone.circle.fill")
                    }
                    .background(.blue)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity)
                }
            }
            
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        
        
        if viewModel.soundState == .waiting {
            Button {
                viewModel.showPdf()
            } label: {
                ImageButton(imageName: "ecg.text.page")
            }
            .buttonStyle(MainButton())
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $viewModel.presentWaveChart) {
                if let url = viewModel.urlPdf {
                    PDFKitView(url: url)
                }
                
            }
        }
    }
}

#Preview {
    MainView()
}
