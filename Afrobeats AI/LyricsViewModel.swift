//
//  LyricsViewModel.swift
//  AfroBeats AI
//
//  Created by Alex Paul on 3/19/24.
//

import Foundation


public class LyricsViewModel: ObservableObject {
    @Published var lyrics: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var recentSearches: [RecentSearch] = []
    @Published var searchHistory: [String] = []
    @Published var translation: String = ""
    
    private let networkManager: LyricsNetworkManager
    private let recentSearchesLimit = 10
    
    init(networkManager: LyricsNetworkManager = LyricsNetworkManager(apiKey: "")) {
        self.networkManager = networkManager
    }
    
    func fetchTranslation(for selectedLines: Set<Int>) {
        print("fetchTranslation called with selectedLines count: \(selectedLines.count)")

        guard selectedLines.count == 5 else {
             DispatchQueue.main.async {
                 self.errorMessage = "Please select 5 lines to get the translation."
                 self.isLoading = false
             }
             return
         }
        let lines = lyrics.split(separator: "\n")
        let selectedText = selectedLines.map { String(lines[$0]) }.joined(separator: "\n")

        isLoading = true
        Task {
            do {
                let translatedText = try await networkManager.getTranslation(input: selectedText)
                DispatchQueue.main.async {
                    self.translation = translatedText
//                    print(self.translation)
                    self.isLoading = false
                    self.errorMessage = ""
                }
            } catch {
                DispatchQueue.main.async {
                    self.translation = ""
                    self.isLoading = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .invalidURL:
                            self.errorMessage = "Invalid URL. Please check the API endpoint."
                        case .requestFailed:
                            self.errorMessage = "Request failed. Please try again later."
                        case .invalidResponse:
                            self.errorMessage = "Invalid response from the server. Please try again."
                        case .decodingFailed:
                            self.errorMessage = "Failed to decode the response. Please contact support."
                        case .translationError(let message):
                            self.errorMessage = "Translation failed: \(message)"
                        }
                    } else {
                        self.errorMessage = "An error occurred. Please try again later."
                    }
                }
            }
        }
    }
    
    @MainActor
    func searchLyrics(artist: String, title: String) async {
        isLoading = true
        errorMessage = ""
        
        let searchText = "\(artist) \(title)"
        addToSearchHistory(searchText)
        
        do {
            let fetchedLyrics = try await networkManager.fetchLyrics(artist: artist, title: title)
            lyrics = fetchedLyrics
            isLoading = false
            addToRecentSearches(artist: artist, title: title)
        } catch {
            errorMessage = handleError(error)
            isLoading = false
        }
    }
    
    private func addToSearchHistory(_ searchText: String) {
        searchHistory.removeAll { $0 == searchText }
        searchHistory.insert(searchText, at: 0)
        
        if searchHistory.count > 10 {
            searchHistory.removeLast()
        }
    }
    
    private func validateSearchText(_ searchText: String) -> (artist: String, title: String)? {
        let components = searchText.components(separatedBy: " - ")
        guard components.count == 2 else {
            return nil
        }
        let artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return (artist, title)
    }
    
    private func handleError(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                return "Invalid URL. Please check the API endpoint."
            case .requestFailed:
                return "Request failed. Please try again later."
            case .invalidResponse:
                return "Invalid response from the server. Please try again."
            case .decodingFailed:
                return "Failed to decode the response. Please contact support."
            case .translationError(_):
                return "Translation failed"
            }
        } else {
            return "An error occurred. Please try again later."
        }
    }
    
    @MainActor
    private func addToRecentSearches(artist: String, title: String) {
        let newSearch = RecentSearch(artist: artist, title: title)
        recentSearches.removeAll { $0 == newSearch }
        recentSearches.insert(newSearch, at: 0)
        if recentSearches.count > recentSearchesLimit {
            recentSearches.removeLast()
        }
    }
    
    @MainActor
    func deleteSearchHistory(at indexSet: IndexSet) {
        searchHistory.remove(atOffsets: indexSet)
    }
    
    func getArtist(from searchText: String) -> String {
        let components = searchText.components(separatedBy: " ")
        return components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func getTitle(from searchText: String) -> String {
        let components = searchText.components(separatedBy: " ")
        if components.count > 1 {
            return components[1...].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return ""
        }
    }
}

