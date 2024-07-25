//
//  LyricsView.swift
//  Afrobeats AI
//
//  Created by Alex Paul on 6/9/24.
//

import SwiftUI

struct LyricsView: View {
    let artist: String
    let title: String
    @StateObject private var viewModel: LyricsViewModel
    @State private var showSideMenu = false
    @State private var selectedLines: Set<Int> = []
    @Environment(\.colorScheme) var colorScheme

    var isSideMenuEnabled: Bool {
        selectedLines.count == 5
    }
    
    init(artist: String, title: String) {
        self.artist = artist
        self.title = title
        self._viewModel = StateObject(wrappedValue: LyricsViewModel())
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if viewModel.isLoading && selectedLines.isEmpty {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        let lines = viewModel.lyrics.split(separator: "\n")
                        ForEach(lines.indices, id: \.self) { index in
                            let line = lines[index]
                            Text(String(line))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .lineSpacing(20)
                                .background(selectedLines.contains(index) ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color.clear)
                                .padding(.bottom)
                                .onTapGesture {
                                    if selectedLines.contains(index) {
                                        selectedLines.remove(index)
                                    } else {
                                        if selectedLines.count < 5 {
                                            selectedLines.insert(index)
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitle("\(artist) - \(title)", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSideMenu.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(!isSideMenuEnabled ? .gray : .blue)
                    }
                    .disabled(!isSideMenuEnabled)
                }
            }
            .onAppear {
                Task {
                    viewModel.artistSearchText = artist
                    viewModel.titleSearchText = title
                    await viewModel.searchLyrics()
                }
            }
            
            SideMenu(isShowing: $showSideMenu, selectedLines: selectedLines,
                     lyrics: viewModel.lyrics, viewModel: viewModel)
                .disabled(!isSideMenuEnabled)
                .onChange(of: selectedLines) { _ in
                    if selectedLines.count == 5 {
                        viewModel.fetchTranslation(for: selectedLines)
                    }
                }
                .onChange(of: showSideMenu) { isShowing in
                    print("Side menu is now \(isShowing ? "shown" : "hidden")")
                    if !isShowing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            selectedLines.removeAll()
                        }
                    }
                }
        }
        .background(Color(UIColor.systemBackground))
    }
}


struct LyricsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LyricsView(artist: "Burna Boy", title: "City Boys")
        }
        .preferredColorScheme(.dark)
        
        NavigationView {
            LyricsView(artist: "Burna Boy", title: "City Boys")
        }
        .preferredColorScheme(.light)
    }
}
