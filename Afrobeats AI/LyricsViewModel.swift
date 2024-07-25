import Foundation
import Combine

public class LyricsViewModel: ObservableObject {
    @Published var lyrics: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var recentSearches: [RecentSearch] = []
    @Published var searchHistory: [String] = []
    @Published var translation: String = ""
    @Published var artistSearchText: String = ""
    @Published var titleSearchText: String = ""
    
    private let networkManager: LyricsNetworkManager
    private let recentSearchesLimit = 10
    private var cancellables = Set<AnyCancellable>()
    
    init(networkManager: LyricsNetworkManager? = nil) {
        if let networkManager = networkManager {
            self.networkManager = networkManager
        } else {
            guard let path = Bundle.main.path(
                forResource: "Configuration",
                ofType: "plist"
            ), let dict = NSDictionary(
                contentsOfFile: path
            ),
                  let apiKey = dict["API_KEY"] as? String
            else {
                fatalError("Configuration.plist not found in bundle")
            }
            self.networkManager = LyricsNetworkManager(apiKey: apiKey)
        }
    }
    
    @MainActor
    func searchLyrics() async {
        guard !artistSearchText.isEmpty && !titleSearchText.isEmpty else {
            errorMessage = "Please enter both artist and song title"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let searchText = "\(artistSearchText) - \(titleSearchText)"
        addToSearchHistory(searchText)
        
        do {
            let fetchedLyrics = try await networkManager.fetchLyrics(artist: artistSearchText, title: titleSearchText)
            lyrics = fetchedLyrics
            isLoading = false
            addToRecentSearches(artist: artistSearchText, title: titleSearchText)
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
    
    func fetchTranslation(for selectedLines: Set<Int>) {
        guard selectedLines.count == 5 else {
            errorMessage = "Please select 5 lines to get the translation."
            return
        }
        
        let lines = lyrics.split(separator: "\n")
        let selectedText = selectedLines.map { String(lines[$0]) }.joined(separator: "\n")
        
        isLoading = true
        Task {
            do {
                let translatedText = try await networkManager.getTranslation(input: selectedText)
                await MainActor.run {
                    self.translation = translatedText
                    self.isLoading = false
                    self.errorMessage = ""
                }
            } catch {
                await MainActor.run {
                    self.translation = ""
                    self.isLoading = false
                    self.errorMessage = handleError(error)
                }
            }
        }
    }
    
    private func handleError(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                return "Invalid URL. Please check the artist and song title."
            case .requestFailed:
                return "Song not found. Please check the spelling of the artist and song title."
            case .invalidResponse:
                return "Invalid response from the server. Please try again later."
            case .decodingFailed:
                return "Failed to decode the response. Please try a different song."
            case .translationError(let message):
                return "Translation failed: \(message)"
            }
        } else {
            return "An unexpected error occurred. Please try again."
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
    
    private func validateSearchText(_ searchText: String) -> (artist: String, title: String)? {
        let components = searchText.components(separatedBy: " - ")
        guard components.count == 2 else {
            return nil
        }
        let artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return (artist, title)
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
