//
//  PexelsAPIClient.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import Foundation
import Combine

struct PexelsPopularResponse: Codable {
    let page: Int?
    let perPage: Int?
    let totalResults: Int?
    let url: String?
    let videos: [Video]
}

final class PexelsAPIClient {
    private let httpClient = HTTPClient.shared
    
    func fetchPopularVideos(perPage: Int = 15, page: Int = 1) -> AnyPublisher<PexelsPopularResponse, APIError> {
        guard var comps = URLComponents(string: "\(Constants.pexelsBaseUrl)/popular") else {
            return Fail(error: APIError.urlError).eraseToAnyPublisher()
        }
        
        comps.queryItems = [
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        guard let url = comps.url else { return Fail(error: APIError.urlError).eraseToAnyPublisher() }
        
        let headers = ["Authorization": Constants.pexelsApiKey]
        
        return httpClient.get(url: url, headers: headers)
    }
}
