//
//  LibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI
import SPFoundation

struct Tabs: View {
    @State var failed = false
    @State var libraries = [Library]()
    @State var activeLibrary: Library?
    
    var body: some View {
        if let activeLibrary = activeLibrary, !libraries.isEmpty {
            Group {
                switch activeLibrary.type {
                    case .audiobooks:
                        AudiobookTabs()
                            .id(activeLibrary.id)
                    case .podcasts:
                        PodcastTabs()
                            .id(activeLibrary.id)
                    default:
                        ErrorView()
                }
            }
            .modifier(NowPlaying.CompactViewModifier())
            .environment(\.libraryId, activeLibrary.id)
            .environment(AvailableLibraries(libraries: libraries))
            .onReceive(NotificationCenter.default.publisher(for: Library.libraryChangedNotification), perform: { notification in
                if let libraryId = notification.userInfo?["libraryId"] as? String, let library = libraries.first(where: { $0.id == libraryId }) {
                    setActiveLibrary(library)
                }
            })
            .modifier(Navigation.NotificationModifier(
                navigateAudiobook: { id, libraryId in
                    if let library = libraries.first(where: { $0.id == libraryId }) {
                        self.activeLibrary = library
                    }
                    
                    Task {
                        try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                        
                        NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                            "audiobookId": id
                        ])
                    }
                }, navigateAuthor: { id, libraryId in
                    if let library = libraries.first(where: { $0.id == libraryId }) {
                        self.activeLibrary = library
                    }
                    
                    Task {
                        try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                        
                        NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                            "authorId": id
                        ])
                    }
                }, navigateSeries: { seriesName, libraryId in
                    if let library = libraries.first(where: { $0.id == libraryId }) {
                        self.activeLibrary = library
                    }
                    
                    Task {
                        try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                        
                        NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                            "seriesName": seriesName
                        ])
                    }
                }, navigatePodcast: { id, libraryId in
                    if let library = libraries.first(where: { $0.id == libraryId }) {
                        self.activeLibrary = library
                    }
                    
                    Task {
                        try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                        
                        NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                            "podcastId": id
                        ])
                    }
                }, navigateEpisode: { episodeId, podcastId, libraryId in
                    if let library = libraries.first(where: { $0.id == libraryId }) {
                        self.activeLibrary = library
                    }
                    
                    Task {
                        try await Task.sleep(nanoseconds: UInt64(0.5 * TimeInterval(NSEC_PER_SEC)))
                        
                        NotificationCenter.default.post(name: Navigation.navigateNotification, object: nil, userInfo: [
                            "episodeId": episodeId,
                            "podcastId": podcastId,
                        ])
                    }
                }))
        } else {
            if failed {
                ErrorView()
            } else {
                LoadingView()
                    .task { await fetchLibraries() }
            }
        }
    }
}

private extension Tabs {
    func fetchLibraries() async {
        if let libraries = try? await AudiobookshelfClient.shared.getLibraries(), !libraries.isEmpty {
            self.libraries = libraries
            
            if let id = Library.getLastActiveLibraryId(), let library = libraries.first(where: { $0.id == id }) {
                setActiveLibrary(library)
            } else if libraries.count > 0 {
                setActiveLibrary(libraries[0])
            }
        }
    }
    
    func setActiveLibrary(_ library: Library) {
        activeLibrary = library
        library.setAsLastActiveLibrary()
    }
}


#Preview {
    Tabs()
}
