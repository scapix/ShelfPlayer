//
//  PodcastLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI

struct PodcastLibraryView: View {
    var body: some View {
        TabView {
            HomeView()
            LatestView()
            LibraryView()
            SearchView()
        }
    }
}

#Preview {
    PodcastLibraryView()
        .environment(\.libraryId, "368e36e5-22b2-4d74-8f17-c50fe6299adf")
        .environment(AvailableLibraries(libraries: []))
}
