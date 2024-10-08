//
//  ProgressOverlay.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SwiftData
import Defaults
import SPFoundation
import SPOffline
import SPOfflineExtended

struct StatusOverlay: View {
    @Default(.itemImageStatusPercentageText) private var itemImageStatusPercentageText
    @Default(.tintColor) private var tintColor
    
    let item: Item
    let entity: ItemProgress
    let offlineTracker: ItemOfflineTracker?
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
        
        entity = OfflineManager.shared.requireProgressEntity(item: item)
        offlineTracker = item.offlineTracker
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width / 2.5
            let fontSize = size * 0.23
            
            HStack(alignment: .top) {
                Spacer()
                
                if entity.progress > 0 {
                    ZStack {
                        Triangle()
                            .foregroundStyle(offlineTracker?.status == .downloaded && Defaults[.tintColor] != .purple ? tintColor.accent : Color.accentColor)
                            .overlay(alignment: .topTrailing) {
                                Group {
                                    if entity.progress < 1 {
                                        if itemImageStatusPercentageText {
                                            Text(verbatim: "\(Int(entity.progress * 100))")
                                                .font(.system(size: fontSize))
                                                .fontWeight(.heavy)
                                        } else {
                                            ZStack {
                                                Circle()
                                                    .trim(from: CGFloat(entity.progress), to: 360 - CGFloat(entity.progress))
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                                
                                                Circle()
                                                    .trim(from: 0, to: CGFloat(entity.progress))
                                                    .stroke(Color.white, style: .init(lineWidth: 3, lineCap: .round))
                                            }
                                            .rotationEffect(.degrees(-90))
                                        }
                                    } else {
                                        Label("finished", systemImage: "checkmark")
                                            .labelStyle(.iconOnly)
                                            .font(.system(size: fontSize))
                                            .fontWeight(.heavy)
                                    }
                                }
                                .frame(width: size / 3, height: size / 3)
                                .foregroundStyle(.white)
                                .padding(size / 7)
                            }
                    }
                    .frame(width: size, height: size)
                } else {
                    if offlineTracker?.status == .downloaded {
                        Label("downloaded", systemImage: "arrow.down.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.caption)
                            .foregroundStyle(.ultraThickMaterial)
                            .padding(4)
                    }
                }
            }
        }
    }
}

// MARK: Progress image

struct ItemStatusImage: View {
    let item: PlayableItem
    var aspectRatio = ItemImage.AspectRatioPolicy.square
    
    var body: some View {
        ItemImage(image: item.image, aspectRatio: aspectRatio)
            .overlay {
                StatusOverlay(item: item)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 7))
    }
}

#Preview {
    ItemStatusImage(item: Audiobook.fixture)
}
