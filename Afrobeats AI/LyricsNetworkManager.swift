import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingFailed
    case translationError(String)
}

class LyricsNetworkManager {
    private let baseURL = "https://private-505cf2-lyricsovh.apiary-proxy.com/v1"
    private let openAIBaseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let apiKey: String
    
    init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiKey = apiKey
    }
    
    func fetchLyrics(artist: String, title: String) async throws -> String {
        let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? artist
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        
        let endpoint = "\(baseURL)/\(encodedArtist)/\(encodedTitle)"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response: \(response)")
                throw NetworkError.invalidResponse
            }
            do {
                let lyricsResponse = try JSONDecoder().decode(LyricsResponse.self, from: data)
                return lyricsResponse.lyrics
            } catch {
                print("Decoding failed: \(error.localizedDescription)")
                throw NetworkError.decodingFailed
            }
        } catch {
            print("Request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed
        }
    }

    func getTranslation(input: String) async throws -> String {
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are an expert translator for Afrobeats lyrics."],
                ["role": "user", "content": "Translate the following Afrobeats lyrics into concise, accurate English. Provide brief but insightful cultural context where relevant:\n\n\(input)\n\nTranslation:"]
            ]
        ]
        
        guard let url = URL(string: openAIBaseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try parseChatCompletionResponse(data)
            case 400...499:
                throw NetworkError.translationError("Client error: \(httpResponse.statusCode)")
            case 500...599:
                throw NetworkError.translationError("Server error: \(httpResponse.statusCode)")
            default:
                throw NetworkError.invalidResponse
            }
        } catch {
            print("Request failed: \(error.localizedDescription)")
            throw NetworkError.requestFailed
        }
    }
    
    private func parseChatCompletionResponse(_ data: Data) throws -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let choices = jsonObject?["choices"] as? [[String: Any]], let message = choices.first?["message"] as? [String: Any], let content = message["content"] as? String else {
                throw NetworkError.translationError("Failed to parse translation response")
            }
            
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Decoding failed: \(error.localizedDescription)")
            throw NetworkError.decodingFailed
        }
    }
}
