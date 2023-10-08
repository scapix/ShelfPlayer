//
//  PodcastLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct HomeView: View {
        @Environment(\.libraryId) var libraryId: String
        
        @State var episodeRows: [EpisodeHomeRow]?
        @State var podcastRows: [PodcastHomeRow]?
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack {
                        if let episodeRows = episodeRows {
                            ForEach(episodeRows) {
                                EpisodeTableContainer(title: $0.label, episodes: $0.episodes)
                            }
                        }
                        if let podcastRows = podcastRows {
                            ForEach(podcastRows) {
                                PodcastsRowContainer(title: $0.label, podcasts: $0.podcasts)
                            }
                        }
                        
                        if episodeRows == nil || podcastRows == nil {
                            LoadingView()
                                .padding(.top, 50)
                        }
                    }
                }
                .navigationTitle("Listen now")
                .modifier(LibrarySelectorModifier())
                .task(loadRows)
                .refreshable(action: loadRows)
            }
            .tabItem {
                Label("Listen now", systemImage: "waveform")
            }
        }
    }
}

// MARK: Helper

extension PodcastLibraryView.HomeView {
    @Sendable
    func loadRows() {
        Task.detached {
            (episodeRows, podcastRows) = (try? await AudiobookshelfClient.shared.getPodcastsHome(libraryId: libraryId)) ?? (nil, nil)
        }
    }
}
