import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LyricsViewModel()
    @State private var selectedSong: (artist: String, title: String)?
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 0) {
                    artistSearchBar
                    titleSearchBar
                    searchButton
                    searchHistoryList
                }
                .background(Color(UIColor.systemBackground))
                .navigationTitle("Search Lyrics")
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
                Label("Search Lyrics", systemImage: "magnifyingglass")
            }
            
            FeedbackView()
                .tabItem {
                    Label("Feedback", systemImage: "bubble.fill")
                }
        }
        .accentColor(.blue)
    }
    
    private var artistSearchBar: some View {
        HStack {
            TextField("Enter artist name", text: $viewModel.artistSearchText)
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var titleSearchBar: some View {
        HStack {
            TextField("Enter song title", text: $viewModel.titleSearchText)
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var searchButton: some View {
        Button(action: {
            Task {
                await viewModel.searchLyrics()
                selectedSong = (viewModel.artistSearchText, viewModel.titleSearchText)
            }
        }) {
            Text("Search")
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .padding(.top, 16)
        .padding(.bottom, 25)
    }
    
    private var searchHistoryList: some View {
        List {
            ForEach(viewModel.searchHistory, id: \.self) { searchText in
                Text(searchText)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        let components = searchText.components(separatedBy: " - ")
                        if components.count == 2 {
                            viewModel.artistSearchText = components[0]
                            viewModel.titleSearchText = components[1]
                            selectedSong = (components[0], components[1])
                        }
                    }
            }
            .onDelete { indexSet in
                viewModel.deleteSearchHistory(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
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
