//
//  AudiobookLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import SPFoundation

struct AudiobookLibraryView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.libraryId) private var libraryId
    
    @Default(.audiobooksDisplay) private var audiobookDisplay
    @Default(.audiobooksFilter) private var audiobooksFilter
    
    @Default(.audiobooksSortOrder) private var audiobooksSortOrder
    @Default(.audiobooksAscending) private var audiobooksAscending
    
    @State private var failed = false
    @State private var audiobooks = [Audiobook]()
    
    @State private var filteredGenres = [String]()
    
    private var genres: [String] {
        var genres = Set<String>()
        
        for audiobook in audiobooks {
            for genre in audiobook.genres {
                genres.insert(genre)
            }
        }
        
        return Array(genres)
    }
    private var visibleAudiobooks: [Audiobook] {
        let visible = AudiobookSortFilter.filterSort(audiobooks: audiobooks, filter: audiobooksFilter, order: audiobooksSortOrder, ascending: audiobooksAscending)
        
        if filteredGenres.count == 0 {
            return visible
        }
        
        return visible.filter {
            if $0.genres.count == 0 {
                return false
            }
            
            let matches = $0.genres.reduce(0, { result, genre in filteredGenres.contains(where: { $0 == genre }) ? result + 1 : result })
            return matches == filteredGenres.count
        }
    }
    
    var body: some View {
        Group {
            if audiobooks.isEmpty {
                if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .task { await fetchItems() }
                }
            } else {
                Group {
                    switch audiobookDisplay {
                        case .grid:
                            ScrollView {
                                AudiobookVGrid(audiobooks: visibleAudiobooks)
                                    .padding(.horizontal, 20)
                            }
                        case .list:
                            List {
                                AudiobookList(audiobooks: visibleAudiobooks)
                            }
                            .listStyle(.plain)
                    }
                }
                .toolbar {
                    if horizontalSizeClass == .compact {
                        ToolbarItem(placement: .topBarLeading) {
                            NavigationLink(destination: AuthorsView()) {
                                Label("authors", systemImage: "person.fill")
                                    .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        AudiobookSortFilter(display: $audiobookDisplay, filter: $audiobooksFilter, sort: $audiobooksSortOrder, ascending: $audiobooksAscending)
                    }
                }
            }
        }
        .navigationTitle("title.library")
        .navigationBarTitleDisplayMode(.large)
        .modifier(NowPlaying.SafeAreaModifier())
        .modifier(AudiobookGenreFilterModifier(genres: genres, selected: $filteredGenres))
        .refreshable { await fetchItems() }
    }
}

extension AudiobookLibraryView {
    func fetchItems() async {
        failed = false
        
        if let audiobooks = try? await AudiobookshelfClient.shared.getAudiobooks(libraryId: libraryId) {
            self.audiobooks = audiobooks
        } else {
            failed = true
        }
    }
}

#Preview {
    AudiobookLibraryView()
}
