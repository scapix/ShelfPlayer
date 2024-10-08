//
//  NowPlayingBarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import Defaults
import SPFoundation
import SPPlayback

extension NowPlaying {
    struct CompactBarModifier: ViewModifier {
        @Default(.skipForwardsInterval) private var skipForwardsInterval
        @Environment(CompactViewState.self) private var nowPlayingViewState
        
        var offset: CGFloat? = nil
        
        @State private var bounce = false
        @State private var animateForwards = false
        
        @State private var nowPlayingSheetPresented = false
        
        func body(content: Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    if let item = AudioPlayer.shared.item {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 300)
                                .mask {
                                    VStack(spacing: 0) {
                                        LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                                            .frame(height: 50)
                                        
                                        Rectangle()
                                            .frame(height: 250)
                                    }
                                }
                                .foregroundStyle(.regularMaterial)
                                .padding(.bottom, -225)
                                .allowsHitTesting(false)
                                .toolbarBackground(.hidden, for: .tabBar)
                            
                            if !nowPlayingViewState.presented {
                                HStack {
                                    ItemImage(image: item.image, aspectRatio: .none)
                                        .frame(height: 40)
                                        .scaleEffect(bounce ? AudioPlayer.shared.playing ? 1.1 : 0.9 : 1)
                                        .animation(.spring(duration: 0.2, bounce: 0.7), value: bounce)
                                        .matchedGeometryEffect(id: "image", in: nowPlayingViewState.safeNamespace, properties: .frame, anchor: .top)
                                        .onChange(of: AudioPlayer.shared.playing) {
                                            withAnimation {
                                                bounce = true
                                            } completion: {
                                                bounce = false
                                            }
                                        }
                                    
                                    VStack(alignment: .leading) {
                                        Group {
                                            if let chapterTitle = AudioPlayer.shared.chapter?.title {
                                                Text(chapterTitle)
                                                    .matchedGeometryEffect(id: "chapter", in: nowPlayingViewState.safeNamespace, properties: .frame, anchor: .top)
                                            } else {
                                                Text(item.name)
                                                    .matchedGeometryEffect(id: "title", in: nowPlayingViewState.safeNamespace, properties: .frame, anchor: .top)
                                            }
                                        }
                                        .lineLimit(1)
                                        
                                        Group {
                                            if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                                                Text(releaseDate, style: .date)
                                                    .matchedGeometryEffect(id: "releaseDate", in: nowPlayingViewState.safeNamespace, properties: .frame, anchor: .top)
                                            } else {
                                                Text(AudioPlayer.shared.adjustedTimeLeft.hoursMinutesSecondsString(includeSeconds: false, includeLabels: true))
                                                + Text(verbatim: " ")
                                                + Text("time.left")
                                            }
                                        }
                                        .lineLimit(1)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Group {
                                        Group {
                                            if AudioPlayer.shared.buffering {
                                                ProgressIndicator()
                                            } else {
                                                Button {
                                                    AudioPlayer.shared.playing = !AudioPlayer.shared.playing
                                                } label: {
                                                    Label("playback.toggle", systemImage: AudioPlayer.shared.playing ?  "pause.fill" : "play.fill")
                                                        .labelStyle(.iconOnly)
                                                        .contentTransition(.symbolEffect(.replace))
                                                }
                                            }
                                        }
                                        .transition(.blurReplace)
                                        .sensoryFeedback(.selection, trigger: AudioPlayer.shared.playing)
                                        
                                        Button {
                                            animateForwards.toggle()
                                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                                        } label: {
                                            Label("forwards", systemImage: "goforward.\(skipForwardsInterval)")
                                                .labelStyle(.iconOnly)
                                                .symbolEffect(.bounce, value: animateForwards)
                                        }
                                        .padding(.horizontal, 10)
                                        .sensoryFeedback(.increase, trigger: animateForwards)
                                    }
                                    .imageScale(.large)
                                }
                                .frame(height: 56)
                                .padding(.horizontal, 10)
                                .foregroundStyle(.primary)
                                .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .modifier(ContextMenuModifier(item: item, animateForwards: $animateForwards))
                                .background {
                                    Rectangle()
                                        .foregroundStyle(.regularMaterial)
                                }
                                .transition(.move(edge: .bottom))
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .shadow(color: .black.opacity(0.25), radius: 20)
                                .padding(.bottom, 10)
                                .padding(.horizontal, 10)
                                .zIndex(1)
                                .onTapGesture {
                                    nowPlayingViewState.setNowPlayingViewPresented(true)
                                }
                            }
                        }
                        .padding(.bottom, offset ?? 0)
                    }
                }
        }
    }
}
