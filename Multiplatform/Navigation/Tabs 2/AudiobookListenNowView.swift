//
//  AudiobookListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import SPFoundation
import SPOffline
import SPOfflineExtended

struct AudiobookListenNowView: View {
    @Environment(\.libraryId) private var libraryId: String
    @Default(.hideFromContinueListening) private var hideFromContinueListening
    
    @Default(.showAuthorsRow) private var showAuthorsRow
    @Default(.disableDiscoverRow) private var disableDiscoverRow
    
    @State private var audiobookRows = [AudiobookHomeRow]()
    @State private var authorRows = [AuthorHomeRow]()
    
    @State private var downloadedAudiobooks = [Audiobook]()
    
    @State private var failed = false
    
    var body: some View {
        Group {
            if audiobookRows.isEmpty {
                if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .task{ await fetchItems() }
                }
            } else {
                ScrollView {
                    VStack {
                        ForEach(audiobookRows) { row in
                            if row.id != "discover" || !disableDiscoverRow {
                                VStack(alignment: .leading) {
                                    RowTitle(title: row.label)
                                        .padding(.horizontal, 20)
                                    
                                    AudiobookHGrid(audiobooks: row.audiobooks.filter { audiobook in
                                        if row.id != "continue-listening" {
                                            return true
                                        }
                                        
                                        return !hideFromContinueListening.contains { $0.itemId == audiobook.id }
                                    })
                                }
                            }
                        }
                        
                        if !downloadedAudiobooks.isEmpty {
                            VStack(alignment: .leading) {
                                RowTitle(title: String(localized: "downloads"))
                                    .padding(.horizontal, 20)
                                
                                AudiobookHGrid(audiobooks: downloadedAudiobooks)
                            }
                        }
                        
                        if showAuthorsRow {
                            ForEach(authorRows) { row in
                                VStack(alignment: .leading) {
                                    RowTitle(title: row.label)
                                        .padding(.horizontal, 20)
                                    
                                    AuthorGrid(authors: row.authors)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("title.listenNow")
        .modifier(NowPlaying.SafeAreaModifier())
        .refreshable { await fetchItems() }
    }
}

extension AudiobookListenNowView {
    func fetchItems() async {
        failed = false
        
        if let downloadedAudiobooks = try? OfflineManager.shared.getAudiobooks() {
            self.downloadedAudiobooks = downloadedAudiobooks
        }
        
        do {
            (audiobookRows, authorRows) = try await AudiobookshelfClient.shared.getAudiobooksHome(libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}

#Preview {
    AudiobookListenNowView()
}
