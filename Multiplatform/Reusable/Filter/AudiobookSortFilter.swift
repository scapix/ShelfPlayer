//
//  AudiobooksSort.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import Defaults
import SPFoundation
import SPOffline

struct AudiobookSortFilter: View {
    @Binding var display: DisplayType
    @Binding var filter: Filter
    
    @Binding var sort: SortOrder
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            Section("section.display") {
                Button {
                    withAnimation {
                        display = .list
                    }
                } label: {
                    Label("sort.list", systemImage: "list.bullet")
                }
                
                Button {
                    withAnimation {
                        display = .grid
                    }
                } label: {
                    Label("sort.grid", systemImage: "square.grid.2x2")
                }
            }
            
            Section("section.filter") {
                ForEach(Filter.allCases, id: \.hashValue) { filter in
                    Button {
                        withAnimation {
                            self.filter = filter
                        }
                    } label: {
                        if self.filter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            }
            
            Section("section.order") {
                ForEach(SortOrder.allCases, id: \.hashValue) { order in
                    Button {
                        withAnimation {
                            sort = order
                        }
                    } label: {
                        if sort == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    withAnimation {
                        ascending.toggle()
                    }
                } label: {
                    if ascending {
                        Label("sort.ascending", systemImage: "checkmark")
                    } else {
                        Text("sort.ascending")
                    }
                }
            }
        } label: {
            Label("filterSort", systemImage: "arrow.up.arrow.down.circle")
                .labelStyle(.iconOnly)
                .symbolVariant(filter == .all ? .none : .fill)
        }
    }
}

// MARK: Filter sort function

extension AudiobookSortFilter {
    @MainActor
    static func filterSort(audiobooks: [Audiobook], filter: Filter, order: SortOrder, ascending: Bool) -> [Audiobook] {
        let audiobooks = audiobooks.filter { audiobook in
            if filter == .all {
                return true
            }
            
            let entity = OfflineManager.shared.requireProgressEntity(item: audiobook)
            
            if filter == .finished && entity.progress >= 1 {
                return true
            } else if filter == .unfinished && entity.progress < 1 {
                return true
            }
            
            return false
        }
        
        return sort(audiobooks: audiobooks, order: order, ascending: ascending)
    }
    
    static func sort(audiobooks: [Audiobook], order: SortOrder, ascending: Bool) -> [Audiobook] {
        let audiobooks = audiobooks.sorted {
            switch order {
                case .name:
                    return $0.sortName.localizedStandardCompare($1.sortName) == .orderedAscending
                case .series:
                    for (index, lhs) in $0.series.enumerated() {
                        if index > $1.series.count - 1 {
                            return true
                        }
                        
                        let rhs = $1.series[index]
                        
                        if lhs.name == rhs.name {
                            guard let lhsSequence = lhs.sequence else { return false }
                            guard let rhsSequence = rhs.sequence else { return true }
                            
                            return lhsSequence < rhsSequence
                        }
                        
                        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                    }
                    
                    return false
                case .author:
                    guard let lhsAuthor = $0.author else { return false }
                    guard let rhsAuthor = $1.author else { return true }
                    
                    return lhsAuthor.localizedStandardCompare(rhsAuthor) == .orderedAscending
                case .released:
                    guard let lhsReleased = $0.released else { return false }
                    guard let rhsReleased = $1.released else { return true }
                    
                    return lhsReleased < rhsReleased
                case .added:
                    return $0.addedAt < $1.addedAt
                case .duration:
                    return $0.duration < $1.duration
            }
        }
        
        // Reverse if not ascending
        if ascending {
            return audiobooks
        } else {
            return audiobooks.reversed()
        }
    }
}

// MARK: Types

extension AudiobookSortFilter {
    enum DisplayType: String, Defaults.Serializable {
        case grid = "grid"
        case list = "list"
    }
    
    enum Filter: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case all = "filter.all"
        case finished = "filter.finished"
        case unfinished = "filter.unfinished"
    }
    
    enum SortOrder: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case name = "sort.name"
        case series = "item.media.metadata.seriesName"
        case author = "sort.author"
        case released = "sort.released"
        case added = "sort.added"
        case duration = "sort.duration"
    }
}

extension Defaults.Keys {
    static let audiobooksDisplay = Key<AudiobookSortFilter.DisplayType>("audiobooksDisplay", default: .list)
    static let audiobooksSortOrder = Key<AudiobookSortFilter.SortOrder>("audiobooksSortOrder", default: .added)
    
    static let audiobooksFilter = Key<AudiobookSortFilter.Filter>("audiobooksFilter", default: .all)
    static let audiobooksAscending = Key<Bool>("audiobooksFilterAscending", default: true)
}

#Preview {
    AudiobookSortFilter(display: .constant(.list), filter: .constant(.all), sort: .constant(.added), ascending: .constant(true))
}
