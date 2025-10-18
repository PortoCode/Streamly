//
//  APIError.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case urlError
    case requestFailed(Int)
    case decodingError(Error)
    case underlying(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .urlError: return "Invalid URL"
        case .requestFailed(let code): return "Request failed with code: \(code)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .underlying(let error): return error.localizedDescription
        case .unknown: return "Unknown error"
        }
    }
}
