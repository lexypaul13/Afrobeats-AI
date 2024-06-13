//
//  ContentView.swift
//  Afrobeats AI
//
//  Created by Alex Paul on 6/9/24.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedSong: (artist: String, title: String)?
    @StateObject private var viewModel = LyricsViewModel()
    
    var body: some View {
        TabView {
            NavigationStack {
                ZStack {
                    // Set the entire background to black
                    
                    VStack {
                        // Search Bar with Gray Background
                        HStack {
                            TextField("Search artist and song title", text: $searchText, prompt: Text("Search artist and song title")
                                .foregroundStyle(.gray)
                                .font(.headline)
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(hex: "efeff0"))
                            .cornerRadius(8)
                            .onSubmit {
                                Task {
                                    let artist = viewModel.getArtist(from: searchText)
                                    let title = viewModel.getTitle(from: searchText)
                                    await viewModel.searchLyrics(artist: artist, title: title)
                                    selectedSong = (artist, title)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Search History List with Gray Background
                        List {
                            ForEach(viewModel.searchHistory, id: \.self) { searchText in
                                Button(action: {
                                    let artist = viewModel.getArtist(from: searchText)
                                    let title = viewModel.getTitle(from: searchText)
                                    selectedSong = (artist, title)
                                }) {
                                    Text(searchText)
                                        .foregroundColor(.black) // Set text color to black
                                }
                                .listRowBackground(Color(hex: "efeff0"))
                            }
                            .onDelete { indexSet in
                                viewModel.deleteSearchHistory(at: indexSet)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .navigationTitle("Search Artist")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Spacer()
                            Text("Search")
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
                .navigationDestination(isPresented: Binding<Bool>(
                    get: { selectedSong != nil },
                    set: { _ in selectedSong = nil }
                )) {
                    if let song = selectedSong {
                        LyricsView(artist: song.artist, title: song.title)
                    }
                }
            }
            .tabItem {
                Label("Search Artist", systemImage: "magnifyingglass")
            }
            
            FeedbackView()
                .tabItem {
                    Label("Feedback", systemImage: "envelope")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
