//
//  NetworkManger .swift
//  AfroBeats AI
//
//  Created by Alex Paul on 3/19/24.
//
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
    private let openAIBaseURL = "https://api.openai.com/v1/completions"
    private let session: URLSession
    private let apiHeaders: [String: String]
    
    init(session: URLSession = .shared, apiKey: String) {
        self.session = session
        self.apiHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    func fetchLyrics(artist: String, title: String) async throws -> String {
            let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? artist
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
            
            let endpoint = "\(baseURL)/\(encodedArtist)/\(encodedTitle)"
            
            print("----> endpoint: \(endpoint)")
            
            guard let url = URL(string: endpoint) else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NetworkError.invalidResponse
                }
                do {
                    let lyricsResponse = try JSONDecoder().decode(LyricsResponse.self, from: data)
                    return lyricsResponse.lyrics
                } catch {
                    throw NetworkError.decodingFailed
                }
            } catch {
                throw NetworkError.requestFailed
            }
        }

   


    
    func getTranslation(input: String) async throws -> String {
        let parameters: [String: Any] = [
                    "model": "gpt-3.5-turbo-instruct",
                    "prompt": "Translate the following Afrobeats lyrics into concise, accurate English. Provide brief but insightful cultural context where relevant:\n\n\(input)\n\nTranslation:",
                    "temperature": 0.2,
                    "max_tokens": 300,
                    "top_p": 0.95,
                    "frequency_penalty": 0.1,
                    "presence_penalty": 0.1
                ]
        
        guard let url = URL(string: openAIBaseURL) else {
            throw NetworkError.invalidURL
        }
        print("URL--->", url)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = apiHeaders
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try parseTextCompletionResponse(data)
            case 400...499:
                throw NetworkError.translationError("Client error: \(httpResponse.statusCode)")
            case 500...599:
                throw NetworkError.translationError("Server error: \(httpResponse.statusCode)")
            default:
                throw NetworkError.invalidResponse
            }
        } catch {
            throw NetworkError.requestFailed
        }
    }
    
    private func parseTextCompletionResponse(_ data: Data) throws -> String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let choices = jsonObject?["choices"] as? [[String: Any]], let text = choices.first?["text"] as? String else {
                throw NetworkError.translationError("Failed to parse translation response")
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
