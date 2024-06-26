import SwiftUI


struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedSong: (artist: String, title: String)?
    @StateObject private var viewModel = LyricsViewModel()
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 0) {
                    searchBar
                    searchHistoryList
                }
                .background(Color(UIColor.systemBackground))
                .navigationTitle("Search Artist")
                .navigationDestination(isPresented: Binding<Bool>(
                    get: { selectedSong != nil },
                    set: { _ in selectedSong = nil }
                )) {
                    if let song = selectedSong {
                        LyricsView(artist: song.artist, title: song.title)
                    }
                }
                .dismissKeyboardOnDoubleTap()
            }
            .tabItem {
                Label("Search Artist", systemImage: "magnifyingglass")
            }
            
            FeedbackView()
                .tabItem {
                    Label("Feedback", systemImage: "bubble.fill")
                }
        }
        .accentColor(.blue)
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Search artist and song title", text: $searchText)
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .onSubmit(performSearch)
        }
        .padding()
    }
    
    private var searchHistoryList: some View {
        List {
            ForEach(viewModel.searchHistory, id: \.self) { searchText in
                Text(searchText)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        selectSong(from: searchText)
                    }
            }
            .onDelete { indexSet in
                viewModel.deleteSearchHistory(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func performSearch() {
        let artist = viewModel.getArtist(from: searchText)
        let title = viewModel.getTitle(from: searchText)
        Task {
            await viewModel.searchLyrics(artist: artist, title: title)
        }
        selectedSong = (artist, title)
    }
    
    private func selectSong(from searchText: String) {
        let artist = viewModel.getArtist(from: searchText)
        let title = viewModel.getTitle(from: searchText)
        selectedSong = (artist, title)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
        ContentView()
            .preferredColorScheme(.light)
    }
}
