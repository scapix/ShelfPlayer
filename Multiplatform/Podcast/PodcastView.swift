//
//  PodcastView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import TipKit
import Defaults
import SPFoundation

struct PodcastView: View {
    @Default private var episodesFilter: AudiobookshelfClient.EpisodeFilter
    
    @Default private var episodesSort: AudiobookshelfClient.EpisodeSortOrder
    @Default private var episodesAscending: Bool
    
    var podcast: Podcast
    
    init(podcast: Podcast) {
        self.podcast = podcast
        
        _episodesFilter = .init(.episodesFilter(podcastId: podcast.id))
        
        _episodesSort = .init(.episodesSort(podcastId: podcast.id))
        _episodesAscending = .init(.episodesAscending(podcastId: podcast.id))
    }
    
    @State private var failed = false
    @State private var navigationBarVisible = false
    
    @State private var episodes = [Episode]()
    @State private var imageColors = Item.ImageColors.placeholder
    
    private var visibleEpisodes: [Episode] {
        let episodes = AudiobookshelfClient.filterSort(episodes: episodes, filter: episodesFilter, sortOrder: episodesSort, ascending: episodesAscending)
        return Array(episodes.prefix(15))
    }
    
    var body: some View {
        List {
            Header(podcast: podcast, imageColors: imageColors, navigationBarVisible: $navigationBarVisible)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if episodes.isEmpty {
                if failed {
                    ErrorView()
                        .listRowSeparator(.hidden)
                } else {
                    HStack {
                        Spacer()
                        LoadingView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .padding(.top, 50)
                }
            } else {
                HStack {
                    Text("episodes")
                        .bold()
                    
                    NavigationLink(destination: PodcastFullListView(episodes: episodes, podcastId: podcast.id)) {
                        HStack {
                            Spacer()
                            Text("episodes.all")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                TipView(EpisodePreviewTip())
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 10, bottom: 10, trailing: 10))
                
                EpisodeSingleList(episodes: visibleEpisodes)
            }
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .modifier(NowPlaying.SafeAreaModifier())
        .task { await fetchEpisodes() }
        .refreshable { await fetchEpisodes() }
        .onAppear {
            Task.detached {
                let colors = await podcast.getImageColors()
                
                Task { @MainActor in
                    withAnimation(.spring) {
                        self.imageColors = colors
                    }
                }
            }
        }
        .modifier(ToolbarModifier(podcast: podcast, navigationBarVisible: navigationBarVisible, imageColors: imageColors))
        .userActivity("io.rfk.shelfplayer.podcast") {
            $0.title = podcast.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = podcast.id
            $0.targetContentIdentifier = "podcast:\(podcast.id)"
            $0.userInfo = [
                "podcastId": podcast.id,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "item").appending(path: podcast.id)
        }
    }
}

// MARK: Helper

extension PodcastView {
    func fetchEpisodes() async {
        failed = false
        
        if let episodes = try? await AudiobookshelfClient.shared.getEpisodes(podcastId: podcast.id) {
            self.episodes = episodes
            podcast.episodeCount = episodes.count
        } else {
            failed = true
        }
    }
}

#Preview {
    NavigationStack {
        PodcastView(podcast: Podcast.fixture)
    }
}
