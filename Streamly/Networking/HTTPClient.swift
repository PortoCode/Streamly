//
//  HTTPClient.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation
import Combine

final class HTTPClient {
    static let shared = HTTPClient()
    private init() {}
    
    func get<T: Decodable>(url: URL, headers: [String: String] = [:]) -> AnyPublisher<T, APIError> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                let response = result.response as? HTTPURLResponse
                if let status = response?.statusCode, !(200...299).contains(status) {
                    throw APIError.requestFailed(status)
                }
                return result.data
            }
            .mapError { APIError.underlying($0) }
            .flatMap { data -> AnyPublisher<T, APIError> in
                let decoder = JSONDecoder()
                do {
                    let value = try decoder.decode(T.self, from: data)
                    return Just(value).setFailureType(to: APIError.self).eraseToAnyPublisher()
                } catch {
                    return Fail(error: APIError.decodingError(error)).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
