//
//  VolumeSlider.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import MediaPlayer

struct VolumeSlider: View {
    @Binding var dragging: Bool
    
    @State private var volume: Double = 0
    
    var body: some View {
        HStack {
            Button {
                volume = 0
            } label: {
                Image(systemName: "speaker.fill")
            }
            
            Slider(percentage: $volume, dragging: $dragging)
            
            Button {
                volume = 100.0
            } label: {
                Image(systemName: "speaker.wave.3.fill")
            }
        }
        .dynamicTypeSize(dragging ? .xLarge : .medium)
        .frame(height: 0)
        .animation(.easeInOut, value: dragging)
        .onChange(of: volume) {
            if dragging {
                MPVolumeView.setVolume(Float(volume / 100))
            }
        }
        .onReceive(AVAudioSession.sharedInstance().publisher(for: \.outputVolume), perform: { value in
            if !dragging {
                withAnimation {
                    volume = Double(value) * 100
                }
            }
        })
    }
}
